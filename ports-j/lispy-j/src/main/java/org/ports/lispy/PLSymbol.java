package org.ports.lispy;

import java.util.HashMap;
import java.util.Map;

public class PLSymbol implements CharSequence, PLExpression {
    private final String s; 
    private static Map<String, PLSymbol> symbolTable = new HashMap<String, PLSymbol>();
    
    public PLSymbol(String s) {
        this.s = s;
    }

    public static PLSymbol Sym(String s) {
        if (!symbolTable.containsKey(s)) {
            symbolTable.put(s, new PLSymbol(s));
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

    public Object evaluate(PLEnv env) {
        return env.find(this);
    }

    public Boolean truthValue() {
        return true;
    }
    
    public String toString() {
        return this.s.toString();
    }

    public String toTypeString() {
        return "symbol";
    }

    public boolean equals(Object obj) {
        if (obj instanceof PLSymbol) {
            return this == obj;
        }
        return false;
    }

}