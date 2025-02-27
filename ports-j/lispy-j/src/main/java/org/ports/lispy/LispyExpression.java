package org.ports.lispy;

public interface LispyExpression {
   
    public abstract Object evaluate(Env env);
    
    public abstract String toTypeString();

}