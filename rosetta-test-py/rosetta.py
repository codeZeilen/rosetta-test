import lispy
import unittest
import threading
import time
import sys
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
    def __init__(self, bridge_name, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_rosetta_primitives()
        self.initialize_rosetta()
        with open(file_name, "r", encoding="utf-8") as file:
            self.suite_source = file.read()
        
        self.suite = None
        self.bridge_name = bridge_name
        
        self.placeholder_functions = {}
        self.setUp_functions = []
        self.tearDown_functions = []

    def initialize_suite(self):
        """Only called after the Python-side was set up and the suite is ready to run."""
        self.suite = self.eval(self.suite_source)
        self.suite_eval("(suite-set-bridge-name! the_suite bridge_name)", bridge_name=self.bridge_name)

    def suite_name(self):
        return self.suite_eval("(suite-name the_suite)")
    
    def suite_version(self):
        return self.suite_eval("(suite-version the_suite)")
    
    def placeholders(self):
        return self.suite_eval("(suite-placeholders the_suite)")
    
    def root_capability(self):
        return self.suite_eval("(suite-root-capability the_suite)")

    def eval(self, code, env=None):
        if not env:
            env = self.lispy_env
        return lispy.eval(lispy.expand(lispy.parse(code), True), env)
    
    def eval_with_args(self, code, **kwargs):
        env = lispy.Env(outer=self.lispy_env)
        for key, value in kwargs.items():
            env[lispy.Sym(key)] = value
        return self.eval(code, env)
    
    def suite_eval(self, code, **kwargs):
        return self.eval_with_args(code, the_suite=self.suite, **kwargs)
    
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
            lispy.Sym("rosetta-test-host"): lambda: "python"
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
        invalid_placeholders = [placeholder for placeholder in self.placeholders() if not placeholder.is_valid()]
        if invalid_placeholders:
            invalid_placeholder_list = "\n".join([("- " + placeholder.name) for placeholder in invalid_placeholders])
            invalid_placeholders_suggestion = "\n\n".join([f"@suite.placeholder(\"{placeholder.name}\")\ndef {placeholder.name.replace('-', '_')}(env,*args):\n\tpass" for placeholder in invalid_placeholders])
            raise Exception(f"Empty placeholders:\n{invalid_placeholder_list}\n\nFix based on:\n{invalid_placeholders_suggestion}")
        
    def install_setUp_tearDown_functions(self):
        for func in self.setUp_functions:
            self.root_capability()[2].insert(0, RosettaSetup(func, self.lispy_env))
        for func in self.tearDown_functions:
            self.root_capability()[3].insert(0, RosettaTearDown(func, self.lispy_env))
    
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
            lispy.Sym("root-capability"): self.root_capability(),
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
        self.suite_eval("(suite-set-only-tests! the_suite only)", only=only)
        self.suite_eval("(suite-set-only-capabilities! the_suite only_capabilities)", only_capabilities=only_capabilities)
        self.suite_eval("(suite-set-exclude-tests! the_suite exclude)", exclude=exclude)
        self.suite_eval("(suite-set-exclude-capabilities! the_suite exclude_capabilities)", exclude_capabilities=exclude_capabilities)
        self.suite_eval("(suite-set-expected-failures! the_suite expected_failures)", expected_failures=expected_failures)
        self.suite_eval("(suite-run the_suite argv)", argv=sys.argv)
        

def suite(bridge_name, file_name):
    return RosettaTestSuite(bridge_name, file_name)
    
def fixture_path(file_name: str):
    return (Path('./rosetta-test-suites') / Path(file_name)).absolute().as_posix()