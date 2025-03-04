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
    return structure == target

for entry in testTable:
    input = entry["input"]
    try:
        evalResult = lispy.eval(lispy.parse(input))
    except Exception as e:
        evalResult = e
    if matches(evalResult, entry["expected"]):
        print(f"✅: {input}") 
    else:
        print(f"❌: {input} got {evalResult} instead")
        