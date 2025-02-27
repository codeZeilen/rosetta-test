package org.ports.lispy;

public class LispyBoolean implements LispyExpression {

    private boolean value;

    public LispyBoolean(boolean value) {
        this.value = value;
    }

    public Object evaluate(Env env) {
        return this;
    };

    public String toString() {
        return this.value ? "#t" : "#f";
    }

    public String toTypeString() {
        return "boolean";
    }

}
