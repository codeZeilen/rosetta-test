import lispy
import unittest
import threading

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

def ports_assert(value):
    assert value
    
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

class PortsSuite(object):

    # TODO: Consider simplyfing the macros to just add to a single list of annotations and extract the relevant parts afterwards (using functions written in ports)
    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_ports_primitives()
        self.initialize_ports()
        with open(file_name, "r") as file:
            self.suite = self.eval(file.read())
        
        self.suite_name, self.suite_version, self.sources, self.placeholders, self.root_capability = self.suite

    def eval(self, code, env=None):
        if not env:
            env = self.lispy_env
        return lispy.eval(lispy.expand(lispy.parse(code), True), env)

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
        })

    def initialize_ports(self):
        with open("ports.scm", "r") as file:
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
        test_name = "_".join(ports_test[1].split())
        return f"test_{test_name}" #TODO: should be done in ports and should be full-test-name 
    
    def generate_unittest_test_method(self, ports_test):
        return lambda testcase: self.run_test(ports_test)
    
    def run_test(self, ports_test):
        env = lispy.Env((lispy.Sym("current-test"),), (ports_test,), outer=self.lispy_env)
        self.eval(f"(test-run current-test)", env)
    
    def run(self, only=None):
        self.ensure_placeholders_are_valid()
        self.install_placeholders()
        self.lispy_env.update({
            "root-capability": self.root_capability,
            "test-file": None, # TODO: this should be done by the spec
        })
        tests = self.eval("(capability-all-tests root-capability)")
        
        test_suite = unittest.TestSuite()
        for test in tests:
            test_name = self.generate_test_name(test)
            if only:
                if test_name not in only:
                    continue
            setattr(TestPortsUnittestContainer,
                    test_name,
                    self.generate_unittest_test_method(test))
            test_suite.addTest(TestPortsUnittestContainer(test_name))
        unittest.TextTestRunner().run(test_suite)


def suite(file_name):
    return PortsSuite(file_name)
    