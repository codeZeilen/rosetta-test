package org.ports.lispy;

import java.util.HashMap;
import java.util.Map;

public class Symbol implements CharSequence, LispyExpression {
    private final String s; 
    private static Map<String, Symbol> symbolTable = new HashMap<String, Symbol>();
    
    public Symbol(String s) {
        this.s = s;
    }

    public static Symbol Sym(String s) {
        if (!symbolTable.containsKey(s)) {
            symbolTable.put(s, new Symbol(s));
        }
        return symbolTable.get(s);
    }

    @Override
    public char charAt(int arg0) {
        return this.s.charAt(arg0);
    }

    @Override
    public int length() {
        return this.s.length();
    }

    @Override
    public CharSequence subSequence(int arg0, int arg1) {
        return this.s.subSequence(arg0, arg1);
    }

    public Object evaluate(Env env) {
        return env.find(this);
    }
    
    public String toString() {
        return this.s.toString();
    }

    public String toTypeString() {
        return "symbol";
    }

}