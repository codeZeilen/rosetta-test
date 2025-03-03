package org.ports.lispy;

public class PLString implements PLExpression {

    private String value;

    public PLString(String value) {
        this.value = value;
    }

    public Object evaluate(PLEnv env) {
        return this;
    };

    public Boolean truthValue() {
        return this.value.length() > 0;
    };

    public String toString() {
        return this.value;
    }

    public String toTypeString() {
        return "string";
    }

}
