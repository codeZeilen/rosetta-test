import lispy

class Placeholder(object):

    def __init__(self, name, parameters) -> None:
        self.name = name
        self.parameters = parameters

def create_placeholder(name, parameters):
    return Placeholder(name, parameters)

class PortsSuite(object):

    # TODO: Consider simplyfing the macros to just add to a single list of annotations and extract the relevant parts afterwards (using functions written in ports)
    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.initialize_ports_primitives()
        self.initialize_macros()
        with open(file_name, "r") as file:
            self.suite = lispy.parse(file.read())
        print(self.suite)
        print("Expanding suite")
        self.suite = lispy.expand(self.suite, True)
        print(self.suite)
        self.suite = lispy.eval(self.suite, self.lispy_env)

    def initialize_ports_primitives(self):
        self.lispy_env.update({
            "create-placeholder": create_placeholder
        })

    def initialize_macros(self):
        with open("macros.lispy", "r") as file:
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
        2 + 3

def suite(file_name):
    return PortsSuite(file_name)
    