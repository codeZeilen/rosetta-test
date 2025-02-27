package org.ports.lispy;

public class Procedure {
    private Symbol[] parms;
    private LispyExpression exp;
    private Env env;

    public Procedure(Symbol[] parms, LispyExpression exp, Env env) {
        this.parms = parms;
        this.exp = exp;
        this.env = env;
    }

    public Object apply(Object[] args) {
        return this.exp.evaluate(new Env(this.parms, args, this.env));
    }
}