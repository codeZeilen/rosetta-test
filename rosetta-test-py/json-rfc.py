import rosetta
from pathlib import Path
import json

suite = rosetta.suite("stdlib json", "rosetta-test-suites/json-rfc.ros")

@suite.placeholder("list-json-test-files")
def listTestFiles(env):
    return list(map(lambda p: p.name, Path("rosetta-test-suites/json-rfc-fixtures").glob("*.json")))

@suite.placeholder("parse")
def parse(env,json_string):
    try:
        return json.loads(json_string)
    except Exception as e:
        return e

@suite.placeholder("parse-success?")
def parse_success(env,parse_result):
    return not isinstance(parse_result,Exception)
    
@suite.placeholder("file-contents")
def file_contents(env,file_name):
    # We need to read in binary, as the data includes invalid characters by design
    with open(f"rosetta-test-suites/json-rfc-fixtures/{file_name}", "rb") as f:
        return f.read()
    
#
# Running
#

suite.run(exclude=(
    # Python json accespts Infinity and NaN, although they are not allowed.
    "test_n_number_infinity", 
    "test_n_number_NaN", 
    "test_n_number_minus_infinity"))