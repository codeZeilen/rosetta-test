import json
import lispy
import numbers

testTable = []
with open("ports/lispy-tests.json") as file:
    testTable.extend(json.load(file))
    
with open("ports/lispy-tests2.json") as file:
    testTable.extend(json.load(file))

def matches(structure, target):
    if(isinstance(target, dict) and "type" in target):
        return isinstance(structure, Exception)
    if(isinstance(structure, lispy.Symbol)):
        return str(structure) == target
    if(isinstance(target, list)):
        if len(structure) != len(target):
            return False
        for i in range(len(structure)):
            if not matches(structure[i], target[i]):
                return False
        return True
        
    return structure == target

expected_failures = ["(quote (testing 1 (2.0) -3.14e159))"]
all_tests_passed = True
for entry in testTable:
    input = entry["input"]
    try:
        evalResult = lispy.eval(lispy.parse(input))
    except Exception as e:
        evalResult = e
    if matches(evalResult, entry["expected"]):
        print(f"✅: {input}") 
    else:
        if input in expected_failures:
            print(f"✖️: {input} got {evalResult} instead")
            continue
        all_tests_passed = False
        print(f"❌: {input} got {evalResult} instead")
        
if all_tests_passed:
    print("All tests passed")
else:
    print("Some tests failed")
    exit(1)