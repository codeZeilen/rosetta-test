package org.ports.lispy;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.json.JSONArray;

public class InterpreterTokenzierTest  {

    @Test
    public void testBasicTokenize() {
        PLInterpreter interpreter = new PLInterpreter();
        
        String expression = "(+ 1 2)";
        String[] expectedTokens = {"(", "+", "1", "2", ")"};
        String[] actualTokens = interpreter.tokenize(expression);
        
        assertArrayEquals(expectedTokens, actualTokens);
    }

    @Test
    public void testTokenizeLines() {
        PLInterpreter interpreter = new PLInterpreter();
        
        String expression = "(+ 1 2\n 3 4)";
        String[] expectedTokens = {"(", "+", "1", "2", "3", "4", ")"};
        String[] actualTokens = interpreter.tokenize(expression);
        
        assertArrayEquals(expectedTokens, actualTokens);
    }

    @Test
    public void testTokenizeComment() {
        PLInterpreter interpreter = new PLInterpreter();
        
        String expression = "(+ 1 2 ; First part \n 3 4)";
        String[] expectedTokens = {"(", "+", "1", "2", "3", "4", ")"};
        String[] actualTokens = interpreter.tokenize(expression);
        
        assertArrayEquals(expectedTokens, actualTokens);
    }

}