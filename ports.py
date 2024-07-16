import lispy

class Placeholder(object):

    def __init__(self, name, parameters, doc_string) -> None:
        self.name = name
        self.parameters = parameters
        self.doc_string = doc_string
        
        self.function = lambda *args: None
        self.env = None
        
    def __call__(self, *args):
        return self.function(self.env, *args)
    
    def is_valid(self):
        return self.function is not None
    
    def __getitem__(self, key):
        if key == 0:
            return lispy.Sym("placeholder")
        else:
            return None

def create_placeholder(name, parameters, doc_string=""):
    return Placeholder(name, parameters, doc_string)

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
            "is-placeholder?": lambda x: isinstance(x, Placeholder),
            "assert": ports_assert
        })

    def initialize_ports(self):
        with open("ports.lispy", "r") as file:
            lispy.eval(lispy.parse(file.read()), self.lispy_env)

    def placeholder(self, name):
        def decorator(func):
            self.placeholder_named(name).function = func
            return func
        return decorator
    
    def placeholder_named(self, name):
        for placeholder in self.placeholders:
            if placeholder.name == name:
                return placeholder
        raise Exception(f"Placeholder {name} not found")
    
    def setUp(self):
        def decorator(func):
            return func
        return decorator
    
    def tearDown(self):
        def decorator(func):
            return func
        return decorator
    
    def ensure_placeholders_are_valid(self):
        for placeholder in self.placeholders:
            if not placeholder.is_valid():
                raise Exception(f"Placeholder {placeholder.name} is not implemented")
            placeholder.env = self.lispy_env
            
    def install_placeholders(self):
        for placeholder in self.placeholders:
            self.lispy_env[placeholder.name] = placeholder
    
    def run(self):
        self.ensure_placeholders_are_valid()
        self.install_placeholders()
        self.lispy_env.update({
            "capabilities": self.capabilities
        })
        lispy.eval(lispy.parse("""(map capability-run capabilities)"""), self.lispy_env)

def suite(file_name):
    return PortsSuite(file_name)
    