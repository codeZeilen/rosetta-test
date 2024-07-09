import lispy

class PortsSuite(object):

    def __init__(self, file_name) -> None:
        self.lispy_env = lispy.Env(outer=lispy.global_env)
        self.suite = lispy.load(file_name)

    


def suite(file_name):
    return PortsSuite(file_name)
    