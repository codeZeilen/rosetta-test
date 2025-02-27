package org.ports.lispy;

import org.apache.commons.lang3.math.Fraction;

public class LispyInteger implements LispyExpression {

    private Integer value;

    public LispyInteger(int value) {
        this.value = value;
    }

    public static LispyInteger valueOf(String token) throws NumberFormatException {
        return new LispyInteger(Integer.parseInt(token));
    }

    public Object evaluate(Env env) {
        return this;
    };

    public String toString() {
        return this.value.toString();
    }

    public String toTypeString() {
        return "integer";
    }

    public LispyInteger add(LispyInteger other) {
        return new LispyInteger(this.value + other.value);
    }

    public LispyFraction add(LispyFraction other) {
        return other.add(this.asFraction());
    }

    public LispyInteger subtract(LispyInteger other) {
        return new LispyInteger(this.value - other.value);
    }

    // TODO: Fill missing operations

    public LispyInteger multiply(LispyInteger other) {
        return new LispyInteger(this.value * other.value);
    }

    public LispyInteger divide(LispyInteger other) {
        return new LispyInteger(this.value / other.value);
    }

    public LispyInteger modulo(LispyInteger other) {
        return new LispyInteger(this.value % other.value);
    }

    public Fraction asFraction() {
        return Fraction.getFraction(this.value, 1);
    }

    
    
}