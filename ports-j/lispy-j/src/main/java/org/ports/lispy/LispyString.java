package org.ports.lispy;

public class LispyString implements LispyExpression {

    private String value;

    public LispyString(String value) {
        this.value = value;
    }

    public Object evaluate(Env env) {
        return this;
    };

    public String toString() {
        return this.value;
    }

    public String toTypeString() {
        return "string";
    }

}
