import lispy
import unittest
import threading
import time
from pathlib import Path

class TestPortsUnittestContainer(unittest.TestCase):
    pass

# TODO: Should be combined with above    
class PortsFunction(object):
    
    def __init__(self, function, env) -> None:
        self.function = function
        self.env = env
        
    def is_valid(self):
        return self.function is not None

    def __call__(self, *args):
        return self.function(self.env, *args)
    
    def __getitem__(self, key):
        if key == 0:
            return lispy.Sym(self.ports_role())
        elif key == 1:
            return self
        else:
            return None 
        
class PortsSetup(PortsFunction):
    
    def ports_role(self):
        return "setup"
    
class PortsTearDown(PortsFunction):
    
    def ports_role(self):
        return "tearDown"
    
class Placeholder(PortsFunction):

    def __init__(self, name, parameters, doc_string) -> None:
        self.name = name
        self.parameters = parameters
        self.doc_string = doc_string
        super().__init__(None, None)
        
    def __getitem__(self, key):
        if key == 0:
            return lispy.Sym("placeholder")
        else:
            return None

def create_placeholder(name, parameters, doc_string=""):
    return Placeholder(name, parameters, doc_string)

def ports_assert(value, msg=""):
    assert value, msg
    
def ports_assert_eq(expected, actual):
    assert expected == actual, f"{expected} != {actual}"

def ports_thread(proc):
    thread = threading.Thread(target=proc)
    thread.daemon = True
    thread.start()
    return thread

def ports_thread_kill(thread: threading.Thread):
    pass

def ports_thread_join(thread: threading.Thread):
    thread.join()
    
def ports_thread_yield():
    time.sleep(0)

class PortsSuite(object):

    # TODO: Consider simplyfing the macros to just add to a single list of annotations and extract the relevant parts afterwards (using functions written in ports)
    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_ports_primitives()
        self.initialize_ports()
        with open(file_name, "r", encoding="utf-8") as file:
            self.suite = self.eval(file.read())
        
        self.suite_name, self.suite_version, self.sources, self.placeholders, self.root_capability = self.suite

    def eval(self, code, env=None):
        if not env:
            env = self.lispy_env
        return lispy.eval(lispy.expand(lispy.parse(code), True), env)
    
    def eval_with_args(self, code, **kwargs):
        env = lispy.Env(outer=self.lispy_env)
        for key, value in kwargs.items():
            env[lispy.Sym(key)] = value
        return self.eval(code, env)

    def initialize_ports_primitives(self):
        self.lispy_env.update({
            "create-placeholder": create_placeholder,
            "is-placeholder?": lambda x: isinstance(x, Placeholder),
            "assert": ports_assert,
            "assert-equal": ports_assert_eq,
            "true": True,
            "false": False,
            "thread": ports_thread,
            "thread-wait-for-completion": ports_thread_join,
            "thread-sleep!": lambda x: time.sleep(x),
            "thread-yield": ports_thread_yield,
        })

    def initialize_ports(self):
        with open("ports/ports.scm", "r") as file:
            self.eval(file.read())

    def placeholder(self, name):
        def decorator(func):
            try:
                self.placeholder_named(name).function = func
            except Exception as e:
                raise Exception(f"Tried to fill placeholder {name}, but was not specified in suite.")
            return func
        return decorator
    
    def placeholder_named(self, name):
        for placeholder in self.placeholders:
            if placeholder.name == name:
                return placeholder
        raise Exception(f"Placeholder {name} not found")
    
    def setUp(self):
        def decorator(func):
            self.root_capability[2].insert(0, PortsSetup(func, self.lispy_env))
            return func
        return decorator
    
    def tearDown(self):
        def decorator(func):
            self.root_capability[3].append(PortsTearDown(func, self.lispy_env))
            return func
        return decorator
    
    def ensure_placeholders_are_valid(self):
        invalid_placeholders = [placeholder for placeholder in self.placeholders if not placeholder.is_valid()]
        if invalid_placeholders:
            invalid_placeholder_list = "\n".join([("- " + placeholder.name) for placeholder in invalid_placeholders])
            raise Exception(f"Invalid placeholders:\n{invalid_placeholder_list}")
            
    def install_placeholders(self):
        for placeholder in self.placeholders:
            self.lispy_env[placeholder.name] = placeholder
            placeholder.env = self.lispy_env
    
    def generate_test_name(self, ports_test):
        return self.eval_with_args("(test-full-name current_test)", current_test=ports_test)
    
    def generate_capability_identifier(self, ports_test):
        return self.eval_with_args("(capability-full-name (test-capability current_test))", current_test=ports_test)
    
    def generate_unittest_test_method(self, ports_test):
        return lambda testcase: self.run_test(ports_test)
    
    def capability_identifier_matches_list(self, capability_identifier, capability_list):
        return any([capability_identifier.startswith(capability) for capability in capability_list])
    
    def run_test(self, ports_test):
        return self.eval_with_args("(test-run current_test)", current_test=ports_test)
    
    def run(self, only=None, only_capabilities=None, exclude=None, exclude_capabilities=None):
        self.ensure_placeholders_are_valid()
        self.install_placeholders()
        self.lispy_env.update({
            "root-capability": self.root_capability,
        })
        tests = self.eval("(capability-all-tests root-capability)")
        
        test_suite = unittest.TestSuite()
        
        selected_tests = self.eval_with_args(
            "(select-tests the_tests only only_capabilities exclude exclude_capabilities)", 
            the_tests=tests, only=only, only_capabilities=only_capabilities, exclude=exclude, exclude_capabilities=exclude_capabilities)
        
        for test in selected_tests:
            test_name = self.generate_test_name(test)
            setattr(TestPortsUnittestContainer,
                    test_name,
                    self.generate_unittest_test_method(test))
            test_suite.addTest(TestPortsUnittestContainer(test_name))
        unittest.TextTestRunner().run(test_suite)


def suite(file_name):
    return PortsSuite(file_name)
    
def fixture_path(file_name: str):
    return (Path('./suites') / Path(file_name)).absolute().as_posix()