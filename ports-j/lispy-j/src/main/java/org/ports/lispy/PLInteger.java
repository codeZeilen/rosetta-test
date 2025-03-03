package org.ports.lispy;

import org.apache.commons.lang3.math.Fraction;

public class PLInteger extends PLNumber implements PLExpression {

    protected Integer value;

    public PLInteger(int value) {
        this.value = value;
    }

    public static PLInteger valueOf(String token) throws NumberFormatException {
        return new PLInteger(Integer.parseInt(token));
    }

    public Object evaluate(PLEnv env) {
        return this;
    };

    public Boolean truthValue() {
        return this.value != 0;
    };

    public String toString() {
        return this.value.toString();
    }

    public String toTypeString() {
        return "integer";
    }

    public PLNumber add(PLNumber other) {
        return other.addInteger(this);
    }

    public PLNumber addInteger(PLInteger other) {
        return new PLInteger(this.value + other.value);
    }

    public PLNumber addFraction(PLFraction other) {
        return other.add(this.asFraction());
    }

    public PLInteger subtract(PLInteger other) {
        return new PLInteger(this.value - other.value);
    }

    // TODO: Fill missing operations

    public PLInteger multiply(PLInteger other) {
        return new PLInteger(this.value * other.value);
    }

    public PLInteger divide(PLInteger other) {
        return new PLInteger(this.value / other.value);
    }

    public PLInteger modulo(PLInteger other) {
        return new PLInteger(this.value % other.value);
    }

    public PLFraction asFraction() {
        return new PLFraction(Fraction.getFraction(this.value, 1));
    }

    public boolean equals(Object obj) {
        if (obj instanceof PLInteger) {
            return this.value == ((PLInteger) obj).value;
        }
        if (obj instanceof Integer) {
            return this.value == (Integer) obj;
        }
        return false;
    }

    
    
}