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
        PLEnv globalTestEnv = (new PLInterpreter()).globalEnvironment;
        for(Object value : allTestData) {
            JSONObject testData = (JSONObject) value;
            String input = testData.getString("input");
            tests.add(DynamicTest.dynamicTest(input, () -> {
                PLInterpreter interpreter = new PLInterpreter();
                Object result = interpreter.evaluate(input, globalTestEnv);
                Object expectation = testData.get("expected");
                assertTrue(result.equals(expectation), "For: " + input + " expected " + expectation.toString() + " got " + result.toString());
            }));
        }

        return tests;
    }

}
