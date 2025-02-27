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

        // Open the test file in /home/patrick/code/ports/ports/syntax-tests.json and write the contents to fileContents file
        try {
            fileContents = new String(Files.readAllBytes(Paths.get("/home/patrick/code/ports/ports/syntax-tests.json")));    
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
                Interpreter interpreter = new Interpreter();
                LispyExpression parseResult = interpreter.parse(test.getString(0));
                Object expectation = test.get(1);
                
                assertTrue(this.checkParseResult(parseResult, expectation), "For: " + test.getString(0) + " expected " + expectation.toString() + " got " + parseResult.toTypeString());
            }));
        }
        return tests;
    }

    private boolean checkParseResult(LispyExpression parseResult, Object expectation) {
        if(expectation.getClass() == String.class) {
            String expectedLabel = expectation.toString();
            if(expectedLabel.equals("Boolean")) {
                return parseResult instanceof LispyBoolean;
            } else if(expectedLabel.equals("Number")) {
                return parseResult instanceof LispyFraction || parseResult instanceof LispyInteger;
            } else if(expectedLabel.equals("String")) {
                return parseResult instanceof LispyString;
            } else if(expectedLabel.equals("Symbol")) {
                return parseResult instanceof Symbol;
            } else {
                return false;
            }
        } else {
            JSONArray expectationArray = (JSONArray) expectation;
            if(!(parseResult instanceof ListExpression)) {
                return false;
            } 
            ListExpression listExpression = (ListExpression) parseResult;
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