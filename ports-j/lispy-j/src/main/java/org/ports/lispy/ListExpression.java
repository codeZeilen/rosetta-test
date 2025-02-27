package org.ports.lispy;

public class ListExpression implements LispyExpression {

    private final LispyExpression[] expressions;

    public ListExpression(LispyExpression[] expressions) {
        this.expressions = expressions;
    }

    public Object evaluate(Env env) {
        Procedure procedure = (Procedure) expressions[0].evaluate(env);
        Object[] arguments = new Object[expressions.length - 1];
        for (int i = 1; i < expressions.length; i++) {
            arguments[i - 1] = expressions[i].evaluate(env);
        }
        return procedure.apply(arguments);
    }

    public int length() {
        return this.expressions.length;
    }

    public LispyExpression get(int i) {
        return this.expressions[i];
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