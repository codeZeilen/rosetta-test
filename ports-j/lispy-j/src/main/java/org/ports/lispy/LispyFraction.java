package org.ports.lispy;

import org.apache.commons.lang3.math.Fraction;

public class LispyFraction implements LispyExpression {

    private Fraction value;

    public LispyFraction(Fraction value) {
        this.value = value;
    }

    public Object evaluate(Env env) {
        return this;
    };

    public String toString() {
        return this.value.toString();
    }

    public String toTypeString() {
        return "fraction";
    }

    public LispyFraction add(LispyInteger other) {
        return new LispyFraction(this.value.add(other.asFraction()));
    }

    public LispyFraction add(Fraction otherFraction) {
        return new LispyFraction(this.value.add(otherFraction));
    }

    public static LispyFraction valueOf(String token) throws NumberFormatException {
       return new LispyFraction(Fraction.getFraction(token));
    }

}