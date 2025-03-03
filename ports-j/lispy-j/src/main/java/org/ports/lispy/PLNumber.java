package org.ports.lispy;

public abstract class PLNumber {
    
    public abstract PLNumber add(PLNumber other);
    public abstract PLNumber addInteger(PLInteger other);
    public abstract PLNumber addFraction(PLFraction other);

    //public abstract LispyNumber subtract(LispyNumber other);
    //public abstract LispyNumber multiply(LispyNumber other);
    //public abstract LispyNumber divide(LispyNumber other);

}
