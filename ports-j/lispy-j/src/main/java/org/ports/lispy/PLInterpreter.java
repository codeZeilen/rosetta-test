package org.ports.lispy;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import org.apache.commons.collections4.iterators.PeekingIterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.math.Fraction;

public class PLInterpreter {
    
    protected final PLEnv globalEnvironment;

    public PLInterpreter() {
        this.globalEnvironment = this.createGlobalEnvironment();
    }

    // Method to evaluate expressions
    public Object evaluate(String expression) {
        return this.evaluate(expression, this.globalEnvironment);
    }

    public Object evaluate(String expression, PLEnv env) {
        PLExpression rootExpression = this.extend(this.parse(expression));
        return rootExpression.evaluate(env);
    }

    protected PLExpression extend(PLExpression expression) {
        return expression;
    }

    protected PLExpression parse(String expression) {
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

    private PLExpression parseTokens(String[] tokens) {
        if(tokens.length == 0) {
            return new PLList(new PLExpression[0]);
        };

        PeekingIterator<String> iterator = new PeekingIterator<String>(List.of(tokens).iterator());

        return this.parseTokens(iterator);
    }

    private PLExpression parseTokens(PeekingIterator<String> iterator) {
        String token = iterator.peek();

        // Check if the token denotes the start of al ist
        if (token.equals("(")) {
            iterator.next();
            ArrayList<PLExpression> list = new ArrayList<>();
            while (!iterator.peek().equals(")")) {
                list.add(this.parseTokens(iterator));
            }
            // End of list, consume closing parenthesis
            token = iterator.next();
            if (token == null) {
                throw new RuntimeException("Unexpected end of input");
            }
            return new PLList(list.toArray(new PLExpression[0]));
        } 

        // Properly consume the token
        token = iterator.next();
        if (token.equals(")")) {
            throw new RuntimeException("Unexpected ')'");
        } else if (token.equals("'")) {
            return new PLList(new PLExpression[] {PLSymbol.Sym("quote"), this.parseTokens(iterator)});
        } else if (token.equals("`")) {
            return new PLList(new PLExpression[] {PLSymbol.Sym("quasiquote"), this.parseTokens(iterator)});
        } else if (token.equals(",")) {
            return new PLList(new PLExpression[] {PLSymbol.Sym("unquote"), this.parseTokens(iterator)});
        } else if (token.equals(",@")) {
            return new PLList(new PLExpression[] {PLSymbol.Sym("unquote-splicing"), this.parseTokens(iterator)});
        } else {
            return this.parseAtom(token);
        }
    }

    private PLExpression parseAtom(String token) {
        String lowerToken = token.toLowerCase();
        if (lowerToken.equals("#t") || lowerToken.equals("#true")) {
            return PLBoolean.TRUE;
        }
        if (lowerToken.equals("#f") || lowerToken.equals("#false")) {
            return PLBoolean.FALSE;
        }
        if (token.charAt(0) == '"') {
            String value = token.substring(1, token.length() - 1);
            value.replace("\\n", "\n").replace("\\r", "\r").replace("\\t", "\t");
            return new PLString(value);
        }

        try {
            return PLInteger.valueOf(token);
        } catch (NumberFormatException e1) {
            try {
                return PLFraction.valueOf(token); // TODO: This should try to parse a fraction instead
            } catch (NumberFormatException e2) {
                return PLSymbol.Sym(token);
            }
        }
    }

    private PLEnv createGlobalEnvironment() {
        PLEnv env = new PLEnv();
        env.setItem(PLSymbol.Sym("+"), new PLPrimProcedure((Object args[]) -> ((PLNumber) args[0]).add((PLNumber) args[1])));
        //env.put(PLSymbol.Sym("-"), (PLNumber a, PLNumber b) -> a.subtract(b));
        //env.put(PLSymbol.Sym("*"), (PLNumber a, PLNumber b) -> a.multiply(b));
        //env.put(PLSymbol.Sym("/"), (PLNumber a, PLNumber b) -> a.divide(b));
        return env;
    }

}