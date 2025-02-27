package org.ports.lispy;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import org.apache.commons.collections4.iterators.PeekingIterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.math.Fraction;

public class Interpreter {
    
    private final Env globalEnvironment;

    public Interpreter() {
        this.globalEnvironment = new Env(new Symbol[0], new Object[0]);
    }

    // Method to evaluate expressions
    public Object evaluate(String expression) {
        return this.evaluate(expression, this.globalEnvironment);
    }

    public Object evaluate(String expression, Env env) {
        LispyExpression rootExpression = this.extend(this.parse(expression));
        return rootExpression.evaluate(env);
    }

    protected LispyExpression extend(LispyExpression expression) {
        return expression;
    }

    protected LispyExpression parse(String expression) {
        String[] tokens = this.tokenize(expression);
        return this.parseTokens(tokens);
    }

    protected String[] tokenize(String expression) {
        Pattern pattern = Pattern.compile("\\s*(,@|[('`,)]|\"(?:[\\\\].|[^\\\\\"])*\"|;.*|[^\\s('\"`,;)]*)(.*)");
        Matcher matcher;
        ArrayList<String> tokens = new ArrayList<>();

        for (String line : expression.lines().toList()) {
            matcher = pattern.matcher(line);
            while (matcher.find() && !matcher.group().isEmpty()) {
                String token = matcher.group(1);
                if (token != null && !token.isEmpty() && !token.startsWith(";")) {
                    tokens.add(token);
                }
                matcher = pattern.matcher(matcher.group(2));
            }
        }
        
        return tokens.toArray(new String[0]);
    }

    private LispyExpression parseTokens(String[] tokens) {
        if(tokens.length == 0) {
            return new ListExpression(new LispyExpression[0]);
        };

        PeekingIterator<String> iterator = new PeekingIterator<String>(List.of(tokens).iterator());

        return this.parseTokens(iterator);
    }

    private LispyExpression parseTokens(PeekingIterator<String> iterator) {
        String token = iterator.peek();

        // Check if the token denotes the start of al ist
        if (token.equals("(")) {
            iterator.next();
            ArrayList<LispyExpression> list = new ArrayList<>();
            while (!iterator.peek().equals(")")) {
                list.add(this.parseTokens(iterator));
            }
            // End of list, consume closing parenthesis
            token = iterator.next();
            if (token == null) {
                throw new RuntimeException("Unexpected end of input");
            }
            return new ListExpression(list.toArray(new LispyExpression[0]));
        } 

        // Properly consume the token
        token = iterator.next();
        if (token.equals(")")) {
            throw new RuntimeException("Unexpected ')'");
        } else if (token.equals("'")) {
            return new ListExpression(new LispyExpression[] {new Symbol("quote"), this.parseTokens(iterator)});
        } else if (token.equals("`")) {
            return new ListExpression(new LispyExpression[] {new Symbol("quasiquote"), this.parseTokens(iterator)});
        } else if (token.equals(",")) {
            return new ListExpression(new LispyExpression[] {new Symbol("unquote"), this.parseTokens(iterator)});
        } else if (token.equals(",@")) {
            return new ListExpression(new LispyExpression[] {new Symbol("unquote-splicing"), this.parseTokens(iterator)});
        } else {
            return this.parseAtom(token);
        }
    }

    private LispyExpression parseAtom(String token) {
        String lowerToken = token.toLowerCase();
        if (lowerToken.equals("#t") || lowerToken.equals("#true")) {
            return new LispyBoolean(true);
        }
        if (lowerToken.equals("#f") || lowerToken.equals("#false")) {
            return new LispyBoolean(false);
        }
        if (token.charAt(0) == '"') {
            String value = token.substring(1, token.length() - 1);
            value.replace("\\n", "\n").replace("\\r", "\r").replace("\\t", "\t");
            return new LispyString(value);
        }

        try {
            return LispyInteger.valueOf(token);
        } catch (NumberFormatException e1) {
            try {
                return LispyFraction.valueOf(token); // TODO: This should try to parse a fraction instead
            } catch (NumberFormatException e2) {
                return new Symbol(token);
            }
        }
    }

    public static int main(String[] args) {
        Interpreter interpreter = new Interpreter();
        System.out.println(interpreter.tokenize("(+ 1 2)"));
        return 0;
    }

}