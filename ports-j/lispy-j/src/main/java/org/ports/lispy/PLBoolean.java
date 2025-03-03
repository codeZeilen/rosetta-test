package org.ports.lispy;

public class PLBoolean implements PLExpression {

    private boolean value;
    public static final PLBoolean TRUE = new PLBoolean(true);
    public static final PLBoolean FALSE = new PLBoolean(false);

    public PLBoolean(boolean value) {
        this.value = value;
    }

    public Object evaluate(PLEnv env) {
        return this;
    };

    public Boolean truthValue() {
        return this.value;
    };

    public String toString() {
        return this.value ? "#t" : "#f";
    }

    public String toTypeString() {
        return "boolean";
    }

}
