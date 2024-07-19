import lispy

class Placeholder(object):

    def __init__(self, name, parameters, doc_string) -> None:
        self.name = name
        self.parameters = parameters
        self.doc_string = doc_string
        
        self.function = None
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
            self.suite = self.eval(file.read())
        
        self.suite_name, self.suite_version, self.sources, self.placeholders, capabilities, setup, tear_down = self.suite
        self.root_capability = [lispy.Sym("capability"), "root", setup, tear_down, capabilities, []]
        
    def eval(self, code):
        return lispy.eval(lispy.expand(lispy.parse(code), True), self.lispy_env)

    def initialize_ports_primitives(self):
        self.lispy_env.update({
            "create-placeholder": create_placeholder,
            "is-placeholder?": lambda x: isinstance(x, Placeholder),
            "assert": ports_assert
        })

    def initialize_ports(self):
        with open("ports.lispy", "r") as file:
            self.eval(file.read())

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
        invalid_placeholders = [placeholder for placeholder in self.placeholders if not placeholder.is_valid()]
        if invalid_placeholders:
            invalid_placeholder_list = "\n".join([placeholder.name for placeholder in invalid_placeholders])
            raise Exception(f"Invalid placeholders: {invalid_placeholder_list}")
            
    def install_placeholders(self):
        for placeholder in self.placeholders:
            self.lispy_env[placeholder.name] = placeholder
            placeholder.env = self.lispy_env
    
    def run(self):
        self.ensure_placeholders_are_valid()
        self.install_placeholders()
        self.lispy_env.update({
            "root-capability": self.root_capability,
            "test-file": None, # TODO: this should be done by the spec
        })
        self.eval("(capability-set-children-parent! root-capability)")
        self.eval("(capability-run root-capability)")

def suite(file_name):
    return PortsSuite(file_name)
    