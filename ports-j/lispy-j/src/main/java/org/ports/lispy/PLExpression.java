package org.ports.lispy;

public interface PLExpression {
   
    public abstract Object evaluate(PLEnv env);
    public abstract Boolean truthValue();
    
    public abstract String toTypeString();

}