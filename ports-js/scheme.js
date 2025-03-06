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

  find(variable) {
    if (this.has(variable)) {
      return this;
    } else if (this.outer === null) {
      throw new Error(`Variable ${variable} not found`);
    } else {
      return this.outer.find(variable);
    }
  }

  unset(variable) {
    if (this.has(variable)) {
      this.delete(variable);
    } else {
      throw new Error(`Variable ${variable} not found`);
    }
  }
}

// Helper functions
const isPair = x => Array.isArray(x) && x.length > 0;
const cons = (x, y) => [x, ...y];
const isa = (x, type) => typeof x === type || x instanceof type;

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
  
  return env;
}

addGlobals(globalEnv);

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

// Public API
export function evalSchemeString(str) {
  return evaluate(parseWithoutExpand(str));
}

export function evalScheme(list) {
  return evaluate(list);
}

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
