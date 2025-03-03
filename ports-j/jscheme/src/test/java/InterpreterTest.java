package java;

import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.json.JSONArray;
import org.json.JSONObject;

public class InterpreterTest {
    
    @TestFactory
    Collection<DynamicTest> interpretationTests() {
        List<DynamicTest> tests = new ArrayList<DynamicTest>();
        String fileContents = "";
        try {
            fileContents = new String(Files.readAllBytes(Paths.get("../../ports/lispy-tests.json")));    
        } catch (Exception e) {
            return tests;
        }
        JSONArray allTestData = new JSONArray(fileContents);
        Scheme schemeInterpreter = new Scheme(null);
        for(Object value : allTestData) {
            JSONObject testData = (JSONObject) value;
            String input = testData.getString("input");
            tests.add(DynamicTest.dynamicTest(input, () -> {
                Object result = schemeInterpreter.eval(input);
                Object expectation = this.getExpectedFrom(testData);
                if(expectation.toString().equals("null")) {
                    assertTrue(result == null, () -> "For: " + input + " expected null got " + result.toString());
                } else {
                    assertTrue(result.equals(expectation), "For: " + input + " expected " + expectation.toString() + " got " + result.toString());
                }
            }));
        }

        return tests;
    }

    private Object getExpectedFrom(JSONObject testData) {
        return this.convertObjects(testData.get("expected"));
    }

    private Object convertObjects(Object someObject) {
        if(someObject instanceof JSONArray) {
            ArrayList<Object> result = new ArrayList<Object>();
            for(Object item: (JSONArray) someObject) {
                result.add(this.convertObjects(item));
            }
            return result;
        } else if (someObject instanceof BigDecimal) {
            return ((Number) someObject).doubleValue();
        } else if (someObject instanceof Integer) {
            return BigInteger.valueOf((Integer) someObject);
        } else {
            return someObject;
        }
    }

}
