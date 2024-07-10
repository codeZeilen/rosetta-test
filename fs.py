"""This is sketched code and is not intended to be run."""

import ports
import io
import os
import tempfile

fs_suite = ports.suite("fs.ports")

@fs_suite.setUp()
def set_up(env):
    test_directory = tempfile.mkdtemp()
    env["_test_directory"] = test_directory
    env["_original_directory"] = os.getcwd()
    os.chdir(test_directory)

@fs_suite.tearDown()
def tear_down(env):
    for file in env.get("file_descriptors", []):
        file.close()
    os.chdir(env["_original_directory"])
    os.rmdir(env["_test_directory"])

@fs_suite.placeholder("open")
def open_file(env, file_name, mode):
    try:
        env.setdefault("file_descriptors", [])
        file = open(file_name, mode)
        env["file_descriptors"].append(file)
        return file
    except ValueError as msg:
        return msg

@fs_suite.placeholder("read")
def read_file(env, file, length):
    try:
        return file.read(length)
    except Exception as err:
        return err

@fs_suite.placeholder("close")
def close_file(env, file):
    try:
        file.close()
    except Exception as err:
        return err

@fs_suite.placeholder("is-file-descriptor?")
def is_file(env, value):
    return isinstance(value, io.IOBase)

@fs_suite.placeholder("is-file-error?")
def is_file_error(env, value):
    return isinstance(value, Exception)

@fs_suite.placeholder("create-test-file")
def create_test_file(env, file_name, file_content):
    with open(file_name, "w") as file:
        file.write(file_content)

fs_suite.run()