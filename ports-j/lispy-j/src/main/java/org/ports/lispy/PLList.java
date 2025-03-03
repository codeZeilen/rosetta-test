package org.ports.lispy;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class PLList implements PLExpression {

    private final PLExpression[] expressions;

    public PLList(PLExpression[] expressions) {
        this.expressions = expressions;
    }

    public Object evaluate(PLEnv env) {
        if(expressions[0].equals(PLSymbol.Sym("define"))) {
            if(expressions[1] instanceof PLSymbol) {
                env.setItem((PLSymbol) expressions[1], expressions[2].evaluate(env));
            } else if(expressions[1] instanceof PLList) {
                PLList list = (PLList) expressions[1];
                PLSymbol identifier = (PLSymbol) list.get(0);
                PLSymbol[] parameters;
                if(list.length() > 1) {
                    parameters = (PLSymbol[]) list.subList(1, list.length() - 1);
                } else {
                    parameters = new PLSymbol[0];
                }
                assert expressions.length == 3;
                PLExpression body = expressions[2];
                env.setItem(identifier, new PLLambdaProcedure(parameters, body, env));
            }
        }
        if(expressions[0].equals(PLSymbol.Sym("if"))) {
            if(((PLExpression) expressions[1].evaluate(env)).truthValue()) {
                return expressions[2].evaluate(env);
            } else {
                return expressions[3].evaluate(env);
            }
        }

        return this.evaluateProcedureApplication(env);
    }

    private Object evaluateProcedureApplication(PLEnv env) {
        PLProcedure procedure = (PLProcedure) expressions[0].evaluate(env);
        Object[] arguments = new Object[expressions.length - 1];
        for (int i = 1; i < expressions.length; i++) {
            arguments[i - 1] = expressions[i].evaluate(env);
        }
        return procedure.apply(arguments);
    }

    public Boolean truthValue() {
        return this.expressions.length > 0;
    }

    public int length() {
        return this.expressions.length;
    }

    public PLExpression get(int i) {
        return this.expressions[i];
    }

    public PLExpression[] subList(int from, int to) {
        return Arrays.copyOfRange(this.expressions, from, to);
    }

    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("(");
        for (int i = 0; i < this.expressions.length; i++) {
            builder.append(this.expressions[i].toString());
            if (i < this.expressions.length - 1) {
                builder.append(" ");
            }
        }
        builder.append(")");
        return builder.toString();
    }

    public String toTypeString() {
        StringBuilder builder = new StringBuilder();
        builder.append("(");
        for (int i = 0; i < this.expressions.length; i++) {
            builder.append(this.expressions[i].toTypeString());
            if (i < this.expressions.length - 1) {
                builder.append(" ");
            }
        }
        builder.append(")");
        return builder.toString();
    }

}