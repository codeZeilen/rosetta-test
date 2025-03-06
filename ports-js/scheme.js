import { parseWithoutExpand } from './parser.js';

import { readFileSync } from 'fs';
import URL from 'url';

// Use JavaScript native Symbol instead of custom implementation
function Sym(s) {
  return Symbol.for(s);
}

// Define special form symbols
const _quote = Sym('quote');
const _if = Sym('if');
const _cond = Sym('cond');
const _set = Sym('set!');
const _unset = Sym('variable-unset!');
const _define = Sym('define');
const _lambda = Sym('lambda');
const _begin = Sym('begin');
const _definemacro = Sym('define-macro');
const _include = Sym('include');
const _quasiquote = Sym('quasiquote');
const _unquote = Sym('unquote');
const _unquotesplicing = Sym('unquote-splicing');
const _append = Sym('append');
const _cons = Sym('cons');
const _let = Sym('let');


function asString(expr) {
    if (typeof expr === 'symbol') {
        return Symbol.keyFor(expr) || expr.toString();
    } else if (Array.isArray(expr)) {
        return `(${expr.map(asString).join(' ')})`;
    } else if (expr === true) {
        return '#t';
    } else if (expr === false) {
        return '#f';
    } else {
        return expr.toString();
    }

}

// Procedure class
class Procedure {
  constructor(parms, exp, env) {
    this.parms = parms;
    this.exp = exp;
    this.env = env;
  }

  call(...args) {
    return evaluate(this.exp, new Env(this.parms, args, this.env));
  }
}

// Environment class
class Env extends Map {
  constructor(parms = [], args = [], outer = null) {
    super();
    this.outer = outer;
    
    if (typeof parms === 'symbol') {
      this.set(parms, Array.from(args));
    } else {
      if (args.length !== parms.length) {
        throw new Error(`Expected ${parms}, given ${args}`);
      }
      parms.forEach((param, i) => this.set(param, args[i]));
    }
  }

  keyFor(variable) {
    return typeof variable === 'symbol' ? variable : Symbol.for(variable);
  }

  find(variable) {
    const key = this.keyFor(variable);
      
    if (this.has(key)) {
      return this;
    }
    if (this.outer) {
      return this.outer.find(variable);
    }
    throw new Error(`Variable ${Symbol.keyFor(key)} not found`);
  }

  unset(variable) {
    const key = this.keyFor(variable);
    if (this.has(key)) {
      this.delete(key);
    } else {
      throw new Error(`Variable ${Symbol.keyFor(key)} not found`);
    }
  }
}

// Helper functions
const isPair = x => Array.isArray(x) && x.length > 0;
const cons = (x, y) => [x, ...y];
const isa = (x, type) => typeof x === type || x instanceof type;

// Macro table for storing macros
const macro_table = new Map();

// Require helper function for syntax checking
function require(x, predicate, msg = "wrong length") {
  if (!predicate) throw new SyntaxError(`${asString(x)}: ${msg}`);
}

// Expand quasiquote expressions
function expand_quasiquote(x) {
  if (!isPair(x)) {
    return [_quote, x];
  }
  require(x, x[0] !== _unquotesplicing, "can't splice here");
  if (x[0] === _unquote) {
    require(x, x.length === 2);
    return x[1];
  } else if (isPair(x[0]) && x[0][0] === _unquotesplicing) {
    require(x[0], x[0].length === 2);
    return [_append, x[0][1], expand_quasiquote(x.slice(1))];
  } else {
    return [_cons, expand_quasiquote(x[0]), expand_quasiquote(x.slice(1))];
  }
}

// Expand include expressions
function expand_include(x) {
  const result = [_begin];
  for (let i = 1; i < x.length; i++) {
    const filename = x[i];
    try {
      const content = readFileSync(filename, 'utf8');
      const parsed = parse(content);
      if (parsed) {
        result.push(parsed);
      } else {
        throw new Error(`Could not include content of ${filename}`);
      }
    } catch (err) {
      throw new Error(`Error including file ${filename}: ${err.message}`);
    }
  }
  return result;
}

// Expand expressions - handles macros and special forms
function expand(x, toplevel = false) {
  require(x, !Array.isArray(x) || x.length !== 0);  // () => Error
  
  if (!Array.isArray(x)) {  // constant => unchanged
    return x;
  } else if (x[0] === _include) {  // (include string1 string2 ...)
    require(x, x.length > 1);
    return expand_include(x);
  } else if (x[0] === _quote) {  // (quote exp)
    require(x, x.length === 2);
    return x;
  } else if (x[0] === _if) {
    if (x.length === 3) x.push(null);  // (if t c) => (if t c null)
    require(x, x.length === 4);
    return x.map(ea => expand(ea));
  } else if (x[0] === _set) {
    require(x, x.length === 3);
    const variable = x[1];
    require(x, typeof variable === 'symbol', "can set! only a symbol");
    return [_set, variable, expand(x[2])];
  } else if (x[0] === _define || x[0] === _definemacro) {
    require(x, x.length >= 3);
    const [def, v, ...body] = x;
    if (Array.isArray(v) && v.length > 0) {  // (define (f args) body)
      const [f, ...args] = v;                //  => (define f (lambda (args) body))
      return expand([def, f, [_lambda, args, ...body]]);
    } else {
      require(x, x.length === 3);
      require(x, typeof v === 'symbol', "can define only a symbol");
      const exp = expand(x[2]);
      if (def === _definemacro) {
        require(x, toplevel, "define-macro only allowed at top level");
        const proc = evaluate(exp);
        require(x, proc instanceof Procedure, "macro must be a procedure");
        macro_table.set(v, proc);  // (define-macro v proc)
        return null;               //  => null; add v:proc to macro_table
      }
      return [_define, v, exp];
    }
  } else if (x[0] === _begin) {
    if (x.length === 1) return null;  // (begin) => null
    return x.map(xi => expand(xi, toplevel));
  } else if (x[0] === _lambda) {  // (lambda (x) e1 e2)
    require(x, x.length >= 3);    //  => (lambda (x) (begin e1 e2))
    const [_, vars, ...body] = x;
    require(x, 
      (Array.isArray(vars) && vars.every(v => typeof v === 'symbol')) || 
      typeof vars === 'symbol', 
      "illegal lambda argument list");
    const exp = body.length === 1 ? body[0] : [_begin, ...body];
    return [_lambda, vars, expand(exp)];
  } else if (x[0] === _quasiquote) {  // `x => expand_quasiquote(x)
    require(x, x.length === 2);
    return expand_quasiquote(x[1]);
  } else if (typeof x[0] === 'symbol' && macro_table.has(x[0])) {
    var proc = macro_table.get(x[0])
    if (proc instanceof Procedure) {
        return expand(proc.call(...x.slice(1)), toplevel);  // (m arg...)
    } else {
        return expand(proc(...x.slice(1)), toplevel);  // (m arg...)
    }
  } else {                          //        => macroexpand if m is a macro
    return x.map(ea => expand(ea));           // (f arg...) => expand each
  }
}

// Let macro implementation
function letMacro(...args) {
  const x = [_let, ...args];
  require(x, args.length > 1);
  const [bindings, ...body] = args;
  require(x, bindings.every(b => 
    Array.isArray(b) && b.length === 2 && typeof b[0] === 'symbol'
  ), "illegal binding list");
  
  const vars = bindings.map(b => b[0]);
  const vals = bindings.map(b => b[1]);
  
  return [[_lambda, vars, ...body.map(ea => expand(ea))], ...vals.map(ea => expand(ea))];
}

// Initialize the macro table with the let macro
macro_table.set(_let, letMacro);

// Global environment setup
const globalEnv = new Env();

function addGlobals(env) {
  // Add basic operations
  env.set(Sym('+'), (a, b) => a + b);
  env.set(Sym('-'), (a, b) => a - b);
  env.set(Sym('*'), (a, b) => a * b);
  env.set(Sym('/'), (a, b) => a / b);
  env.set(Sym('not'), a => !a);
  env.set(Sym('>'), (a, b) => a > b);
  env.set(Sym('<'), (a, b) => a < b);
  env.set(Sym('>='), (a, b) => a >= b);
  env.set(Sym('<='), (a, b) => a <= b);
  env.set(Sym('='), (a, b) => a === b);
  env.set(Sym('equal?'), (a, b) => a === b);
  env.set(Sym('eq?'), (a, b) => a === b);
  env.set(Sym('length'), a => a.length);
  env.set(Sym('cons'), cons);
  env.set(Sym('car'), a => a[0]);
  env.set(Sym('cdr'), a => a.slice(1));
  env.set(Sym('append'), (a, b) => [...a, ...b]);
  env.set(Sym('list'), (...args) => args);
  env.set(Sym('list?'), a => Array.isArray(a));
  env.set(Sym('list-ref'), (list, idx) => list[idx]);
  env.set(Sym('list-set!'), (list, idx, val) => { list[idx] = val; });
  
  // Error handling
  env.set(Sym('error'), msg => { throw new Error(msg); });
  
  // String operations
  env.set(Sym('string-append'), (...strs) => strs.reduce((acc, s) => acc + String(s), ''));
  env.set(Sym('string-split'), (s, sep) => String(s).split(sep));
  env.set(Sym('string-replace'), (old, newStr, s) => String(s).replace(old, newStr));
  env.set(Sym('string-index'), (str, substr) => {
    const idx = str.indexOf(substr);
    return idx !== -1 ? idx : false;
  });
  env.set(Sym('string-upcase'), s => String(s).toUpperCase());
  env.set(Sym('string-downcase'), s => String(s).toLowerCase());
  env.set(Sym('string-trim'), s => String(s).trim());
  env.set(Sym('number->string'), x => String(x));
  
  // Type checking
  env.set(Sym('null?'), x => x === null || x === undefined || (Array.isArray(x) && x.length === 0));
  env.set(Sym('symbol?'), x => typeof x === 'symbol');
  env.set(Sym('boolean?'), x => typeof x === 'boolean');
  env.set(Sym('pair?'), isPair);
  

  env.set(Sym('display'), (...args) => console.log(...args));

  return env;
}

// Evaluation function
function evaluate(x, env = globalEnv) {
  while (true) {
    if (typeof x === 'symbol') {
      return env.find(x).get(x);
    } else if (!Array.isArray(x)) {
      return x;
    } else if (x[0] === _quote) {
      return x[1];
    } else if (x[0] === _if) {
      const [_, test, conseq, alt] = x;
      x = evaluate(test, env) ? conseq : alt;
    } else if (x[0] === _cond) {
      let matched = false;
      for (let i = 1; i < x.length; i++) {
        const [test, exp] = x[i];
        if (test === 'else' || evaluate(test, env)) {
          x = exp;
          matched = true;
          break;
        }
      }
      if (!matched) return null;
    } else if (x[0] === _set) {
      const [_, variable, exp] = x;
      env.find(variable).set(variable, evaluate(exp, env));
      return null;
    } else if (x[0] === _unset) {
      const [_, variable] = x;
      env.find(variable).unset(variable);
      return null;
    } else if (x[0] === _define) {
      const [_, variable, exp] = x;
      env.set(variable, evaluate(exp, env));
      return null;
    } else if (x[0] === _lambda) {
      const [_, vars, exp] = x;
      return new Procedure(vars, exp, env);
    } else if (x[0] === _begin) {
      for (let i = 1; i < x.length - 1; i++) {
        evaluate(x[i], env);
      }
      x = x[x.length - 1];
    } else {
      const exps = x.map(exp => evaluate(exp, env));
      const proc = exps.shift();
      if (proc instanceof Procedure) {
        x = proc.exp;
        env = new Env(proc.parms, exps, proc.env);
      } else {
        return proc(...exps);
      }
    }
  }
}

// Add parse function that includes expansion
export function parse(inport) {
  const parsed = parseWithoutExpand(inport);
  return expand(parsed, true);
}

// Public API
export function evalSchemeString(str) {
  return evaluate(parse(str));
}

export function evalScheme(list) {
  return evaluate(expand(list, true));
}

addGlobals(globalEnv);


function main() {
    console.log(evalSchemeString("(+ (* 2 3) 2)")); // Should output 3
}

// run tests only if started directly
if (import.meta.url.startsWith('file:')) {
    const modulePath = URL.fileURLToPath(import.meta.url);
    if (process.argv[1] === modulePath) {
        main()
    }
  }
