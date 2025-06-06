################ Scheme Interpreter in Python

## (c) Peter Norvig, 2010; See http://norvig.com/lispy2.html
## (c) Patrick Rein, 2024; Updated to Python3

################ Symbol, Procedure, classes

from __future__ import division
import re, sys, io 
from contextlib import redirect_stdout
import threading
from functools import reduce
from fractions import Fraction
import sys

class Symbol(str): 

    def __eq__(self, value: object) -> bool:
        return isinstance(value, Symbol) and super().__eq__(value)
    
    def __hash__(self) -> int:
        return id(self).__hash__()  
    
    def __repr__(self) -> str:
        return "'" + self

def Sym(s, symbol_table={}):
    "Find or create unique Symbol entry for str s in symbol table."
    if isinstance(s, Symbol): return s
    if s not in symbol_table: symbol_table[s] = Symbol(s)
    return symbol_table[s]

_quote, _if, _cond, _else, _set, _define, _lambda, _begin, _definemacro, _include, = list(map(Sym, 
"quote   if   cond   else   set!  define   lambda   begin   define-macro   include".split()))

_quasiquote, _unquote, _unquotesplicing = list(map(Sym,
"quasiquote   unquote   unquote-splicing".split()))

class Procedure(object):
    "A user-defined Scheme procedure."
    def __init__(self, parms, exp, env):
        self.parms, self.exp, self.env = parms, exp, env
    def __call__(self, *args): 
        return eval(self.exp, Env(self.parms, args, self.env))

################ parse, read, and user interaction

def parse(inport):
    "Parse a program: read and expand/error-check it."
    # Backwards compatibility: given a str, convert it to an InPort
    if isinstance(inport, str): inport = InPort(io.StringIO(inport))
    return expand(read(inport), toplevel=True)

def parseWithoutExpand(inport):
    if isinstance(inport, str): inport = InPort(io.StringIO(inport))
    return read(inport)

eof_object = Symbol('#<eof-object>') # Note: uninterned; can't be read

class InPort(object):
    "An input port. Retains a line of chars."
    tokenizer = r"""\s*(,@|[('`,)]|"(?:[\\].|[^\\"])*"|;.*|[^\s('"`,;)]*)(.*)"""
    
    def __init__(self, file):
        self.file = file
        self.line = ''
        
    def next_token(self):
        "Return the next token, reading new text into line buffer if needed."
        while True:
            if self.line == '': 
                self.line = self.file.readline()
            if self.line == '': 
                return eof_object
            token, self.line = re.match(InPort.tokenizer, self.line).groups()
            if token != '' and not token.startswith(';'):
                return token

def readchar(inport):
    "Read the next character from an input port."
    if inport.line != '':
        ch, inport.line = inport.line[0], inport.line[1:]
        return ch
    else:
        return inport.file.read(1) or eof_object

def read(inport):
    "Read a Scheme expression from an input port."
    def read_ahead(token):
        if '(' == token: 
            L = []
            while True:
                token = inport.next_token()
                if token == ')': 
                    return L
                else: 
                    try:
                        L.append(read_ahead(token))
                    except SyntaxError as e:
                        raise SyntaxError(f'Syntax Error in list {L}')
        elif ')' == token: raise SyntaxError('unexpected )')
        elif token in quotes: return [quotes[token], read(inport)]
        elif token is eof_object: raise SyntaxError(f'Unexpected EOF in list')
        else: return atom(token)
    # body of read:
    token1 = inport.next_token()
    return eof_object if token1 is eof_object else read_ahead(token1)

quotes = {"'":_quote, "`":_quasiquote, ",":_unquote, ",@":_unquotesplicing}

def atom(token: str):
    'Numbers become numbers; #t and #f are booleans; "..." string; otherwise Symbol.'
    lowerToken = token.lower()
    if lowerToken == '#t' or lowerToken == '#true': return True
    elif lowerToken == '#f' or lowerToken == '#false': return False
    elif token[0] == '"': 
        raw_string = token[1:-1]
        raw_string = raw_string.replace('\\n', '\n')
        raw_string = raw_string.replace('\\r', '\r')
        raw_string = raw_string.replace('\\t', '\t')
        raw_string = raw_string.replace('\\"', '"')
        return raw_string
    try: return int(token)
    except ValueError:
        try: return Fraction(token)
        except ValueError:
            return Sym(token)

def to_string(x):
    "Convert a Python object back into a Lisp-readable string."
    if x is True: return "#t"
    elif x is False: return "#f"
    elif isa(x, Symbol): return x
    elif isa(x, str): return '"%s"' % x.replace('"',r'\"')
    elif isa(x, list): return '('+' '.join(list(map(to_string, x)))+')'
    else: return str(x)

def load(filename):
    "Eval every expression from a file."
    repl(None, InPort(open(filename)), None)

def repl(prompt='lispy> ', inport=InPort(sys.stdin), out=sys.stdout):
    "A prompt-read-eval-print loop."
    sys.stderr.write("Lispy version 2.0\n")
    while True:
        try:
            if prompt: sys.stderr.write(prompt)
            x = parse(inport)
            if x is eof_object: return
            val = eval(x)
            with redirect_stdout(out):
                if val is not None and out: 
                    print(to_string(val))
        except Exception as e:
            print('%s: %s' % (type(e).__name__, e))

################ Environment class

class ArgumentError(Exception): pass

class Env(dict):
    "An environment: a dict of {'var':val} pairs, with an outer Env."
    def __init__(self, parms=(), args=(), outer=None):
        # Bind parm list to corresponding args, or single parm to list of args
        self.outer = outer
        if isa(parms, Symbol): 
            self.update({parms:list(args)})
        else: 
            if len(args) != len(parms):
                raise ArgumentError(f'expected {parms}, given {args}, ')
            self.update(zip(parms,args))

        self.lock = threading.Lock()
        
    def __getitem__(self, key):
        with self.lock:
            return super().__getitem__(Sym(key))
            
    def __setitem__(self, key, value):
        with self.lock:
            super().__setitem__(Sym(key), value)
            
    def __contains__(self, key: object) -> bool:
        return super().__contains__(Sym(key))
        
    def __delitem__(self, key):
        with self.lock:
            super().__delitem__(Sym(key))
        
    def find(self, var):
        "Find the innermost Env where var appears."
        with self.lock:
            if var in self: 
                return self
            elif self.outer is None: 
                raise LookupError(var)
            else: 
                return self.outer.find(var)
                
    def __str__(self) -> str:
        if self.outer is None:
            return "global env"
        return super().__str__() + " -> " + str(self.outer)

def is_pair(x): return x != [] and isa(x, list)
def cons(x, y): return [x]+y

def callcc(proc):
    "Call proc with current continuation; escape only"
    ball = RuntimeWarning("Sorry, can't continue this continuation any longer.")
    def throw(retval): ball.retval = retval; raise ball
    try:
        return proc(throw)
    except RuntimeWarning as w:
        if w is ball: return ball.retval
        else: raise w
        
def primitive_error(msg):
    return Exception(msg)

def primitive_raise(err):
    raise err

def primitive_error_handler(handler_fn, thunk_fn):
    try:
        return thunk_fn()
    except Exception as e:
        return handler_fn(e)
    
def primitive_string_index(astring, substring):
    try:
        return astring.index(substring)
    except:
        return False

def add_globals(self):
    "Add some Scheme standard procedures."
    import math, cmath, operator as op
    self.update(vars(math))
    self.update(vars(cmath))
    prims = dict(
        map(lambda item: (Sym(item[0]), item[1]), {
     '+':op.add, '-':op.sub, '*':op.mul, '/':op.truediv, 'not':op.not_, 
     '>':op.gt, '<':op.lt, '>=':op.ge, '<=':op.le, '=':op.eq, 
     'modulo':op.mod,
     'equal?':op.eq, 'eq?':op.is_, 'eqv?':op.eq, 'length':len, 'cons':cons,
     'car':lambda x:x[0], 
     'cdr':lambda x:x[1:],
     'append':op.add,  
     'list':lambda *x:list(x), 'list?': lambda x:isa(x,list), 'list-ref':op.getitem,
     'list-set!':op.setitem,
     'make-hash-table':lambda: {}, 'hash-table?':lambda x:isa(x,dict),
     'hash-table-set!':lambda ht,k,v: ht.__setitem__(k,v),
     'hash-table-ref-prim':lambda ht,key: ht[key],
     'hash-table-keys':lambda ht: list(ht.keys()), 'hash-table-values':lambda ht: list(ht.values()),
     'hash-table-delete!':lambda ht,k: None if ht.pop(k, None) else None,
     'error':lambda err_msg: primitive_error(err_msg),
     'raise':lambda err: primitive_raise(err),
     'with-exception-handler': lambda handler_fn, thunk_fn: primitive_error_handler(handler_fn, thunk_fn),
     'string-append': lambda *strs: "".join(map(str, strs)), 'char-whitespace?': lambda x: x.isspace(),
     'string-split': lambda s,sep: str(s).split(sep), 'string-replace': lambda old,new,s: str(s).replace(old,new),
     'string-index': primitive_string_index,
     'string-upcase': lambda s: str(s).upper(), 'string-downcase': lambda s: str(s).lower(),
     'string-trim': lambda s: str(s).strip(),'number->string': lambda x: str(x),
     'null?':lambda x:x==() or x==[] or x==None, 'symbol?':lambda x: isa(x, Symbol),
     'boolean?':lambda x: isa(x, bool), 'pair?':is_pair, 
     'apply':lambda proc,l: proc(*l), 
     'eval':lambda x: eval(expand(x)), 'load':lambda fn: load(fn), 'call/cc':callcc,
     
     # Port prims
     'open-input-file':open, 
     'close-port':lambda p: p.close(), 
     'open-output-file': lambda f: open(f,'w'), 
     'eof-object?':lambda x:x is eof_object, 
     'read-char': lambda p: p.read(1) or eof_object,
     'port?': lambda x:isa(x,io.IOBase),
     'output-port?': lambda x: isinstance(x, io.IOBase) and x.writable(),
     'input-port?': lambda x: isinstance(x, io.IOBase) and x.readable(),
     'write':lambda x,port=sys.stdout: port.write(to_string(x)),
     'write-char':lambda x,port=sys.stdout: port.write(x) ,
     'display':lambda x: print(x if isa(x,str) else to_string(x), end="",flush=True),
     'exit':lambda code: sys.exit(code)}.items()))
    self.update(prims)
    return self

isa = isinstance

#
# Rest of stdlib is loaded at the end of this file
#
global_env = add_globals(Env())

class LispyException(Exception):
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)


################ eval (tail recursive)

def eval(x, env=global_env):
    "Evaluate an expression in an environment."
    try:
        while True:
            if isa(x, Symbol):       # variable reference
                return env.find(x)[x]
            elif not isa(x, list):   # constant literal
                return x                
            elif x[0] is _quote:     # (quote exp)
                (_, exp) = x
                return exp
            elif x[0] is _if:        # (if test conseq alt)
                (_, test, conseq, alt) = x
                x = (conseq if eval(test, env) else alt)
            elif x[0] is _cond:      # (cond (test exp) ...)
                one_clause_matched = False
                for clause in x[1:]:
                    (test, exp) = clause
                    if test == _else or eval(test, env):
                        x = exp
                        one_clause_matched = True
                        break
                if not one_clause_matched:
                    return None # no clause matched so the cond returns undefined
            elif x[0] is _set:       # (set! var exp)
                (_, var, exp) = x
                env.find(var)[var] = eval(exp, env)
                return None
            elif x[0] is _define:    # (define var exp)
                (_, var, exp) = x
                env[var] = eval(exp, env)
                return None
            elif x[0] is _lambda:    # (lambda (var*) exp)
                (_, vars, exp) = x
                return Procedure(vars, exp, env)
            elif x[0] is _begin:     # (begin exp+)
                for exp in x[1:-1]:
                    eval(exp, env)
                x = x[-1]
            else:                    # (proc exp*)
                exps = [eval(exp, env) for exp in x]
                proc = exps.pop(0)
                if isa(proc, Procedure):
                    x = proc.exp
                    env = Env(proc.parms, exps, proc.env)
                else:
                    if not proc:
                        raise SyntaxError(f'Undefined procedure: {x[0]}')
                    
                    return proc(*exps)
    except LispyException as e:
        print("handling in " + to_string(x))
        e.message = e.message + f'while evaluating {to_string(x)}\n'
        raise
    except (SyntaxError, TypeError) as e:
        raise LispyException(str(e) + "\n" + f'while evaluating {to_string(x)} in {env}')


################ expand

def expand(x, toplevel=False):
    "Walk tree of x, making optimizations/fixes, and signaling SyntaxError."
    require(x, x!=[])                    # () => Error
    if not isa(x, list):                 # constant => unchanged
        return x
    elif x[0] is _include:              # (include string1 string2 ...)
        require(x, len(x)>1)
        return expand_include(x)
    elif x[0] is _quote:                 # (quote exp)
        require(x, len(x)==2)
        return x
    elif x[0] is _if:                    
        if len(x)==3: x = x + [None]     # (if t c) => (if t c None)
        require(x, len(x)==4)
        return list(map(expand, x))
    elif x[0] is _set:                   
        require(x, len(x)==3); 
        var = x[1]                       # (set! non-var exp) => Error
        require(x, isa(var, Symbol), "can set! only a symbol")
        return [_set, var, expand(x[2])]
    elif x[0] is _define or x[0] is _definemacro: 
        require(x, len(x)>=3)            
        _def, v, body = x[0], x[1], x[2:]
        if isa(v, list) and v:           # (define (f args) body)
            f, args = v[0], v[1:]        #  => (define f (lambda (args) body))
            return expand([_def, f, [_lambda, args]+body])
        else:
            require(x, len(x)==3)        # (define non-var/list exp) => Error
            require(x, isa(v, Symbol), "can define only a symbol")
            exp = expand(x[2])
            if _def is _definemacro:     
                require(x, toplevel, "define-macro only allowed at top level")
                proc = eval(exp)       
                require(x, callable(proc), "macro must be a procedure")
                macro_table[v] = proc    # (define-macro v proc)
                return None              #  => None; add v:proc to macro_table
            return [_define, v, exp]
    elif x[0] is _begin:
        if len(x)==1: return None        # (begin) => None
        else: return [expand(xi, toplevel) for xi in x]
    elif x[0] is _lambda:                # (lambda (x) e1 e2) 
        require(x, len(x)>=3)            #  => (lambda (x) (begin e1 e2))
        vars, body = x[1], x[2:]
        require(x, (isa(vars, list) and all(isa(v, Symbol) for v in vars))
                or isa(vars, Symbol), "illegal lambda argument list")
        exp = body[0] if len(body) == 1 else [_begin] + body
        return [_lambda, vars, expand(exp)]   
    elif x[0] is _quasiquote:            # `x => expand_quasiquote(x)
        require(x, len(x)==2)
        return expand_quasiquote(x[1])
    elif isa(x[0], Symbol) and x[0] in macro_table:
        return expand(macro_table[x[0]](*x[1:]), toplevel) # (m arg...) 
    else:                                #        => macroexpand if m isa macro
        return list(map(expand, x))            # (f arg...) => expand each

def require(x, predicate, msg="wrong length"):
    "Signal a syntax error if predicate is false."
    if not predicate: raise SyntaxError(to_string(x)+': '+msg)

_append, _cons, _let = list(map(Sym, "append cons let".split()))

def expand_quasiquote(x):
    """Expand `x => 'x; `,x => x; `(,@x y) => (append x y) """
    if not is_pair(x):
        return [_quote, x]
    require(x, x[0] is not _unquotesplicing, "can't splice here")
    if x[0] is _unquote:
        require(x, len(x)==2)
        return x[1]
    elif is_pair(x[0]) and x[0][0] is _unquotesplicing:
        require(x[0], len(x[0])==2)
        return [_append, x[0][1], expand_quasiquote(x[1:])]
    else:
        return [_cons, expand_quasiquote(x[0]), expand_quasiquote(x[1:])]
    
def expand_include(x):
    result = [_begin]
    for file_name in x[1:]:
        with open(file_name, "r") as include_file:
            include_result = parse(include_file.read())
            if include_result:
                result.append(include_result)
            else:
                raise LispyException("Could not include content of " + file_name)
    return result

def let(*args):
    args = list(args)
    x = cons(_let, args)
    require(x, len(args)>1)
    bindings, body = args[0], args[1:]
    require(x, all(isa(b, list) and len(b)==2 and isa(b[0], Symbol)
                   for b in bindings), "illegal binding list")
    vars, vals = zip(*bindings)
    return [[_lambda, list(vars)]+list(map(expand, body))] + list(map(expand, vals))

macro_table = {_let:let} ## More macros can go here

eval(parse("""(begin

;; More macros can also go here
)"""))

#
# Loading the basic definitions 
#
with open("rosetta-test/stdlib.scm", "r") as f:
    eval(parse(f.read()), env=global_env)

#
# Overriding basic definitions for performance reasons
#
global_env.update({
    'map':lambda fn, l: list(map(fn, l)), 
    'for-each':lambda fn, l: [fn(x) for x in l],
    'empty?':lambda ls:len(ls) == 0,
    'write-string':lambda s, port=sys.stdout: port.write(s),
    'read-string':lambda k, port: port.read(k) if port else None,
})


if __name__ == '__main__':
    repl()

