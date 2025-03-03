package org.ports.lispy;

import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.json.JSONArray;

public class InterpreterParserTest  {

    @TestFactory
    Collection<DynamicTest> parserTest() {
        List<DynamicTest> tests = new ArrayList<DynamicTest>();
        String fileContents = "";

        try {
            fileContents = new String(Files.readAllBytes(Paths.get("../../ports/syntax-tests.json")));
        } catch (Exception e) {
            return tests;
        }
        
        JSONArray testData = new JSONArray(fileContents);
        for(Object value : testData) {
            if(value.getClass() == String.class) {
                continue;
            }
            JSONArray test = (JSONArray) value;
            tests.add(DynamicTest.dynamicTest(test.getString(0), () -> {
                PLInterpreter interpreter = new PLInterpreter();
                PLExpression parseResult = interpreter.parse(test.getString(0));
                Object expectation = test.get(1);
                
                assertTrue(this.checkParseResult(parseResult, expectation), "For: " + test.getString(0) + " expected " + expectation.toString() + " got " + parseResult.toTypeString());
            }));
        }
        return tests;
    }

    private boolean checkParseResult(PLExpression parseResult, Object expectation) {
        if(expectation.getClass() == String.class) {
            String expectedLabel = expectation.toString();
            if(expectedLabel.equals("Boolean")) {
                return parseResult instanceof PLBoolean;
            } else if(expectedLabel.equals("Number")) {
                return parseResult instanceof PLFraction || parseResult instanceof PLInteger;
            } else if(expectedLabel.equals("String")) {
                return parseResult instanceof PLString;
            } else if(expectedLabel.equals("Symbol")) {
                return parseResult instanceof PLSymbol;
            } else {
                return false;
            }
        } else {
            JSONArray expectationArray = (JSONArray) expectation;
            if(!(parseResult instanceof PLList)) {
                return false;
            } 
            PLList listExpression = (PLList) parseResult;
            if(listExpression.length() != expectationArray.length()) {
                return false;
            }
            for(int i = 0; i < listExpression.length(); i++) {
                if(!this.checkParseResult(listExpression.get(i), expectationArray.get(i))) {
                    return false;
                }
            }
            return true;
        }
        
    }
}