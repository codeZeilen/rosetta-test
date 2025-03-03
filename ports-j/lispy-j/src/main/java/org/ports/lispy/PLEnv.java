package org.ports.lispy;

import java.util.HashMap;
import java.util.Map;

public class PLEnv {
    private final Map<PLSymbol, Object> variables;
    private final PLEnv outer;

    public PLEnv(PLSymbol[] parameters, Object[] arguments, PLEnv outer) {
        this.variables = new HashMap<>();
        this.initializeVariables(parameters, arguments);
        this.outer = outer;
    }

    public PLEnv(PLSymbol[] parameters, Object[] arguments) {
        this.variables = new HashMap<>();
        this.initializeVariables(parameters, arguments);
        this.outer = null;
    }

    public PLEnv() {
        this.variables = new HashMap<>();
        this.outer = null;
    }

    private void initializeVariables(PLSymbol[] parameters, Object[] arguments) {
        if(parameters.length != arguments.length) {
            throw new RuntimeException("Parameter count mismatch");
        }
        for (int i = 0; i < parameters.length; i++) {
            variables.put(parameters[i], arguments[i]);
        }
    }

    public void setItem(PLSymbol key, Object value) {
        variables.put(key, value);
    }

    public Object find(PLSymbol var) {
        if (variables.containsKey(var)) {
            return variables.get(var);
        } else if (outer != null) {
            return outer.find(var);
        } else {
            throw new RuntimeException("Variable not found: " + var);
        }
    }

    public void unset(PLSymbol var) {
        if (variables.containsKey(var)) {
            variables.remove(var);
        } else if (outer != null) {
            outer.unset(var);
        } else {
            throw new RuntimeException("Variable not found: " + var);
        }
    }

    @Override
    public String toString() {
        if (outer == null) {
            return "global env";
        }
        return variables.toString() + " -> " + outer.toString();
    }
}