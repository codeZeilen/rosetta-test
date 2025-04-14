import lispy
import unittest
import threading
import time
from pathlib import Path

class TestRosettaUnittestContainer(unittest.TestCase):
    pass


class RosettaFunction(object):
    
    def __init__(self, function, env) -> None:
        self.function = function
        self.env = env
        
    def is_valid(self):
        return self.function is not None

    def __call__(self, *args):
        return self.function(self.env, *args)
    
    def __getitem__(self, key):
        if key == 0:
            return lispy.Sym(self.rosetta_role())
        elif key == 1:
            return self
        else:
            return None 
        
    def rosetta_role(self):
        raise NotImplementedError("RosettaFunction is an abstract class")
        
        
class RosettaSetup(RosettaFunction):
    
    def rosetta_role(self):
        return "setup"
    
    
class RosettaTearDown(RosettaFunction):
    
    def rosetta_role(self):
        return "tearDown"
    
    
class Placeholder(RosettaFunction):

    def __init__(self, name, parameters, doc_string) -> None:
        self.name = name
        self.parameters = parameters
        self.doc_string = doc_string
        super().__init__(None, None)
        
    def rosetta_role(self):
        return "placeholder"
    

def rosetta_assert(value, msg=""):
    assert value, msg
    
def rosetta_assert_eq(expected, actual):
    assert expected == actual, f"{expected} != {actual}"

def rosetta_thread(proc):
    thread = threading.Thread(target=proc)
    thread.daemon = True
    thread.start()
    return thread

def rosetta_thread_kill(thread: threading.Thread):
    pass

def rosetta_thread_join(thread: threading.Thread):
    thread.join()
    
def rosetta_thread_yield():
    time.sleep(0)

class RosettaTestSuite(object):

    # TODO: Consider simplyfing the macros to just add to a single list of annotations and extract the relevant parts afterwards (using functions written in rosetta)
    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_rosetta_primitives()
        self.initialize_rosetta()
        with open(file_name, "r", encoding="utf-8") as file:
            self.suite_source = file.read()
        
        self.suite_name = None
        self.suite_version = None
        self.sources = None
        self.placeholders = None
        self.root_capability = None
        
        self.placeholder_functions = {}
        self.setUp_functions = []
        self.tearDown_functions = []

    def initialize_suite(self):
        """Only called after the Python-side was set up and the suite is ready to run."""
        self.suite_name, self.suite_version, self.sources, self.placeholders, self.root_capability = self.eval(self.suite_source)

    def eval(self, code, env=None):
        if not env:
            env = self.lispy_env
        return lispy.eval(lispy.expand(lispy.parse(code), True), env)
    
    def eval_with_args(self, code, **kwargs):
        env = lispy.Env(outer=self.lispy_env)
        for key, value in kwargs.items():
            env[lispy.Sym(key)] = value
        return self.eval(code, env)
    
    def create_placeholder(self, name, parameters, doc_string=""):
        newPlaceholder = Placeholder(name, parameters, doc_string)
        self.lispy_env[name] = newPlaceholder
        newPlaceholder.env = self.lispy_env
        
        if name in self.placeholder_functions:
            newPlaceholder.function = self.placeholder_functions[name]
        
        return newPlaceholder

    def initialize_rosetta_primitives(self):
        self.lispy_env.update({
            lispy.Sym("create-placeholder"): lambda *args: self.create_placeholder(*args),
            lispy.Sym("is-placeholder?"): lambda x: isinstance(x, Placeholder),
            lispy.Sym("assert"): rosetta_assert,
            lispy.Sym("assert-equal"): rosetta_assert_eq,
            lispy.Sym("is-assertion-error?"): lambda e: isinstance(e, AssertionError),
            lispy.Sym("thread"): rosetta_thread,
            lispy.Sym("thread-wait-for-completion"): rosetta_thread_join,
            lispy.Sym("thread-sleep!"): lambda x: time.sleep(float(x)),
            lispy.Sym("thread-yield"): rosetta_thread_yield,
        })

    def initialize_rosetta(self):
        with open("rosetta-test/rosetta-test.scm", "r") as file:
            self.eval(file.read())

    def placeholder(self, name):
        def decorator(func):
            self.placeholder_functions[lispy.Sym(name)] = func    
            return func
        return decorator
    
    def setUp(self):
        def decorator(func):
            self.setUp_functions.append(func)
            return func
        return decorator
    
    def tearDown(self):
        def decorator(func):
            self.tearDown_functions.append(func)
            return func
        return decorator
    
    def ensure_placeholders_are_valid(self):
        invalid_placeholders = [placeholder for placeholder in self.placeholders if not placeholder.is_valid()]
        if invalid_placeholders:
            invalid_placeholder_list = "\n".join([("- " + placeholder.name) for placeholder in invalid_placeholders])
            invalid_placeholders_suggestion = "\n\n".join([f"@suite.placeholder(\"{placeholder.name}\")\ndef {placeholder.name.replace('-', '_')}(env,*args):\n\tpass" for placeholder in invalid_placeholders])
            raise Exception(f"Empty placeholders:\n{invalid_placeholder_list}\n\nFix based on:\n{invalid_placeholders_suggestion}")
        
    def install_setUp_tearDown_functions(self):
        for func in self.setUp_functions:
            self.root_capability[2].insert(0, RosettaSetup(func, self.lispy_env))
        for func in self.tearDown_functions:
            self.root_capability[3].insert(0, RosettaTearDown(func, self.lispy_env))
    
    def generate_test_name(self, rosetta_test):
        return self.eval_with_args("(test-full-name current_test)", current_test=rosetta_test)
        
    def generate_unittest_test_method(self, rosetta_test):
        return lambda testcase: self.run_test(rosetta_test)
    
    def run_test(self, rosetta_test):
        print(self.eval_with_args("(test-name current_test)", current_test=rosetta_test))
        return self.eval_with_args("(test-run current_test)", current_test=rosetta_test)
    
    def run_unittest(self, only=None, only_capabilities=None, exclude=None, exclude_capabilities=None, expected_failures=[]):
        self.initialize_suite()
        self.install_setUp_tearDown_functions()
        self.ensure_placeholders_are_valid()
        self.lispy_env.update({
            lispy.Sym("root-capability"): self.root_capability,
        })
        tests = self.eval("(capability-all-tests root-capability)")
        
        test_suite = unittest.TestSuite()
        
        selected_tests = self.eval_with_args(
            "(select-tests the_tests only only_capabilities exclude exclude_capabilities)", 
            the_tests=tests, only=only, only_capabilities=only_capabilities, exclude=exclude, exclude_capabilities=exclude_capabilities)
        
        for test in selected_tests:
            test_name = self.generate_test_name(test)
            setattr(TestRosettaUnittestContainer,
                    test_name,
                    self.generate_unittest_test_method(test))
            test_case = TestRosettaUnittestContainer(test_name)
            if test_name in expected_failures:
                unittest.expectedFailure(test_case)
            test_suite.addTest(test_case)
        unittest.TextTestRunner().run(test_suite)

    def run(self, only=None, only_capabilities=None, exclude=None, exclude_capabilities=None, expected_failures=[]):
        self.initialize_suite()
        self.install_setUp_tearDown_functions()
        self.ensure_placeholders_are_valid()
        self.lispy_env.update({
            lispy.Sym("root-capability"): self.root_capability,
        })
        self.eval_with_args(
            "(run-suite suite_name suite_version root-capability only_tests only_capabilities exclude exclude_capabilities expected_failures)", 
            suite_name=self.suite_name,
            suite_version=self.suite_version,
            only_tests=only, only_capabilities=only_capabilities, exclude=exclude, exclude_capabilities=exclude_capabilities,
            expected_failures=expected_failures)
        

def suite(file_name):
    return RosettaTestSuite(file_name)
    
def fixture_path(file_name: str):
    return (Path('./rosetta-test-suites') / Path(file_name)).absolute().as_posix()