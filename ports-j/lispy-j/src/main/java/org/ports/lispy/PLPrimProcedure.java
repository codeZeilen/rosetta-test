package org.ports.lispy;

import java.util.function.Function;

public class PLPrimProcedure implements PLProcedure {

    private Function<Object[], Object> f;

    public PLPrimProcedure(Function<Object[], Object> f) {
        this.f = f;
    }

    public Object apply(Object[] args) {
        return this.f.apply(args);
    }
    
}
