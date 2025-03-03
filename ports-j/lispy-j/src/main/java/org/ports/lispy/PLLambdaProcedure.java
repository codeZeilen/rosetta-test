package org.ports.lispy;

public class PLLambdaProcedure implements PLProcedure {
    private PLSymbol[] parms;
    private PLExpression exp;
    private PLEnv env;

    public PLLambdaProcedure(PLSymbol[] parms, PLExpression exp, PLEnv env) {
        this.parms = parms;
        this.exp = exp;
        this.env = env;
    }

    public Object apply(Object[] args) {
        return this.exp.evaluate(new PLEnv(this.parms, args, this.env));
    }
}