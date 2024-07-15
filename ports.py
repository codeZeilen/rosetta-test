import lispy

class Placeholder(object):

    def __init__(self, name, parameters) -> None:
        self.name = name
        self.parameters = parameters

def create_placeholder(name, parameters):
    return Placeholder(name, parameters)

def ports_assert(value):
    assert value

class PortsSuite(object):

    # TODO: Consider simplyfing the macros to just add to a single list of annotations and extract the relevant parts afterwards (using functions written in ports)
    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_ports_primitives()
        self.initialize_ports()
        with open(file_name, "r") as file:
            self.suite = lispy.parse(file.read())
        self.suite = lispy.expand(self.suite, True)
        self.suite = lispy.eval(self.suite, self.lispy_env)
        
        self.suite_name, self.suite_version, self.sources, self.placeholders, self.capabilities, self.setup, self.tear_down = self.suite

    def initialize_ports_primitives(self):
        self.lispy_env.update({
            "create-placeholder": create_placeholder,
            "assert": ports_assert
        })

    def initialize_ports(self):
        with open("ports.lispy", "r") as file:
            lispy.eval(lispy.parse(file.read()), self.lispy_env)

    def placeholder(self, name):
        def decorator(func):
            return func
        return decorator
    
    def setUp(self):
        def decorator(func):
            return func
        return decorator
    
    def tearDown(self):
        def decorator(func):
            return func
        return decorator
    
    def run(self):
        self.lispy_env.update({
            "capabilities": self.capabilities
        })
        lispy.eval(lispy.parse("""(map capability-run capabilities)"""), self.lispy_env)

def suite(file_name):
    return PortsSuite(file_name)
    