package org.ports.lispy;

import org.apache.commons.lang3.math.Fraction;

public class PLFraction extends PLNumber implements PLExpression {

    protected Fraction value;

    public PLFraction(Fraction value) {
        this.value = value;
    }

    public Object evaluate(PLEnv env) {
        return this;
    };

    public Boolean truthValue() {
        return this.value.doubleValue() != 0.0;
    };

    public String toString() {
        return this.value.toString();
    }

    public String toTypeString() {
        return "fraction";
    }

    public PLNumber add(PLNumber other) {
        return other.addFraction(this);
    }

    public PLNumber addInteger(PLInteger other) {
        return new PLFraction(this.value.add(other.asFraction().value));
    }

    public PLNumber addFraction(PLFraction other) {
        return new PLFraction(this.value.add(other.value));
    }

    public static PLFraction valueOf(String token) throws NumberFormatException {
       return new PLFraction(Fraction.getFraction(token));
    }

}