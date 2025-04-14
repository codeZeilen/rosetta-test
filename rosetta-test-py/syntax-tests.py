import json
import lispy
import numbers

with open("rosetta-test/parsing-tests.json") as file:
    testTable = json.load(file)

def matches(structure, target):
    if isinstance(target, list):
        if not isinstance(structure, list):
            return False
        if not len(structure) == len(target):
            return False
        else: 
            result = True
            for i in range(len(target)):
                result = result and matches(structure[i], target[i])
            return result
    elif target == "Boolean":
        return isinstance(structure, bool)
    elif target == "String":
        return isinstance(structure, str)
    elif target == "Character":
        return isinstance(structure, str) and len(structure) == 1
    elif target == "Symbol":
        return isinstance(structure, lispy.Symbol)
    elif target == "Number":
        return isinstance(structure, numbers.Number)

for entry in [row for row in testTable if not isinstance(row, str)]:
    parseResult = lispy.parseWithoutExpand(entry[0])
    if matches(parseResult, entry[1]):
        print(f"✅: {entry}") 
    else:
        print(f"❌: {entry} got {parseResult} instead")
        