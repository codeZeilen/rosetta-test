"
this is Scheme (the Uncommon Lisp), a Lisp-1 dialect fully static with closures

	ULisp openNew 		""doIt""

	SLIB version 3b1 is provided 
	(see http://swiss.csail.mit.edu/~jaffer/SLIB.html)






	
"
Class {
	#name : #ULisp,
	#superclass : #StaticLisp,
	#instVars : [
		'initialEnvironment',
		'userEnvironment'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #private }
ULisp class >> aliasForPrimitive: aSymbol [

	| alias |

	alias := aSymbol allButLast.
	alias := alias copyReplaceAll: 'LISP' with: ''.
	(aSymbol endsWith: 'P:')
		ifTrue: [alias := alias allButLast, '?'].
	(aSymbol endsWith: 'D:')
		ifTrue: [alias := alias allButLast, '!'].		
	(aSymbol endsWith: 'Star:')
		ifTrue: [alias := (alias allButLast: 4), '*'].	
	alias := alias copyReplaceAll: 'ONE' with: '-1'.
	alias := alias copyReplaceAll: 'TO' with: '->'.
	(alias detect: [:c | c isUppercase] ifNone: [nil])
		ifNotNil: [alias := alias linkAtCaps].

	^ alias asSymbol
	
	
]

{ #category : #libraries }
ULisp class >> amb [

	"amb by Dorai Sitaram

	http://www.ccs.neu.edu/home/dorai/t-y-scheme/t-y-scheme-Z-H-16.html#node:=chap:=14
	"

	^#(in-library amb

(define amb-fail `*)

(define initialize-amb-fail
  (lambda ()
    (set! amb-fail
      (lambda ()
        (error 'amb tree exhausted')))))

(initialize-amb-fail)

(define-macro amb
  (lambda #'alts...'
    `(let ((#'+prev-amb-fail' amb-fail))
       (call/cc
        (lambda (#'+sk')
          ,@(map (lambda (alt)
                   `(call/cc
                     (lambda (#'+fk')
                       (set! amb-fail
                         (lambda ()
                           (set! amb-fail #'+prev-amb-fail')
                           (#'+fk' `fail)))
                       (#'+sk' ,alt))))
			#'alts...')
          (#'+prev-amb-fail'))))))

(define assert
  (lambda (pred)
    (if (not pred) (amb))))

 (define-macro bag-of
  (lambda (e)
    `(let ((#'+prev-amb-fail' amb-fail)
           (#'+results' `()))
       (if (call/cc
            (lambda (#'+k')
              (set! amb-fail (lambda () (#'+k' false)))
              (let ((#'+v' ,e))
                (set! #'+results' (cons #'+v' #'+results'))
                (#'+k' true))))
           (amb-fail))
       (set! amb-fail #'+prev-amb-fail')
       (reverse! #'+results'))))
	)



]

{ #category : #libraries }
ULisp class >> argumentsLists [

	^ #()  "no arguments-lists library"
]

{ #category : #libraries }
ULisp class >> autoCompile [

	"on-the-fly compilation --experimental--"

	^ 
	#(in-library auto-compile

(require-library `ulisp-compilers)

(defmacro defun (name args &rest body)
	`(progn
		(defun: ,name ,args ,@body)
		(compile ,name)))

(defmacro define (name &rest spec)
	(if (and (symbol? name)
			(pair? (car spec))
			(eq? `lambda (caar spec)))
		`(progn
			(define: ,name ,@spec)
			(compile ,name))
		(if (pair? name)
			`(progn
				(define: ,name ,@spec)
				(compile ,(car name)))
			`(define: ,name ,@spec))))
)
]

{ #category : #libraries }
ULisp class >> benchmarks [

	^ #(in-library benchmarks

(define #'*benchmarks*' ())

(define (run-benchmark . args)
	(set! #'*benchmarks*' (append #'*benchmarks*' args)))

(load  'ulisp/gabriel-scheme/cpstack.sch')
(load  'ulisp/gabriel-scheme/ctak.sch')
(load  'ulisp/gabriel-scheme/deriv.sch')
(load  'ulisp/gabriel-scheme/destruct.sch')
(load  'ulisp/gabriel-scheme/div.sch')
(load  'ulisp/gabriel-scheme/fft.sch')
(load  'ulisp/gabriel-scheme/puzzle.sch')
(load  'ulisp/gabriel-scheme/tak.sch')
(load  'ulisp/gabriel-scheme/takr.sch')

(define (run-benchmark name thunk)
  (newline)
  (display '--------------------------------------------------------')
  (newline)
  (display name)
  (newline)
  (send Smalltalk garbageCollect)
  (time (thunk) true))

(define (run-benchmark-named str)
	(apply run-benchmark (list str (plist-get #'*benchmarks*' str))))

(define (all-benchmarks)
	(do ((bm #'*benchmarks*' (cddr bm)) (all ()))
		((null bm) all)
		(set! all (append all (list (car bm))))))

(define (run-all-benchmarks)
	(map run-benchmark-named (all-benchmarks)))
		
)
]

{ #category : #libraries }
ULisp class >> block [

	^ #()  "no block library"
]

{ #category : #private }
ULisp class >> complexString: aComplex base: base [

	| rs is |

	rs := aComplex real printStringBase: base.
	(aComplex real isKindOf: Fraction) ifTrue: [rs := rs allButFirst allButLast].

	is := aComplex imaginary printStringBase: base.
	(aComplex imaginary isKindOf: Fraction) ifTrue: [is := is allButFirst allButLast].

	^ rs, 
		(0 <= aComplex imaginary ifTrue: ['+']	ifFalse: ['']),
		is,
		'i'
		
	
]

{ #category : #libraries }
ULisp class >> defaultLibraries [

	"the bindings defined by these libraries will belong to the interaction-environment"

	^ #(compilers #'ulisp-compilers' #'slib-init' #'slib-integration')
]

{ #category : #booleans }
ULisp class >> falseValue [

	^ false
]

{ #category : #booleans }
ULisp class >> falseValuePrintString [

	^ '#f'
]

{ #category : #libraries }
ULisp class >> glue [

	"helpers for writing compatible code among dialects"

	^ 
	#(progn

		(defun yes* () true)
		(defun no* () false)

	)
]

{ #category : #private }
ULisp class >> initialize [

	super initialize
]

{ #category : #libraries }
ULisp class >> jacal [

	"JACAL, an interactive symbolic mathematics program, by Aubrey Jaffer

	http://www-swiss.ai.mit.edu/~jaffer/JACAL.html
	"

	^#(in-library jacal
			(require `math-integer)
			(require `math-real)					
			(#'slib:load' (system-path 'ulisp/jacal/math')))



]

{ #category : #libraries }
ULisp class >> kanren [

	"kanren, by Oleg and al.
	http://kanren.sourceforge.net/
	"

	^#(in-library kanren
			(load (system-path 'ulisp/kanren/ulisp/load-kanren.scm')))



]

{ #category : #libraries }
ULisp class >> loop [

	^ 
	#(in-library loop
		(load: (system-path 'ulisp\loop.scm')))
]

{ #category : #libraries }
ULisp class >> meroonet [

	"an object system by Christian Queinnec

	http://www-spi.lip6.fr/~queinnec/WWW/Meroon.html
	"

	^#(in-library meroonet
			(define define-meroonet-macro define-macro)
			(define meroonet-error error)
			(load (system-path 'ulisp/meroonet/meroonet.scm')))



]

{ #category : #libraries }
ULisp class >> miniKanren [

	"miniKANREN, by Oleg and al.
	http://kanren.sourceforge.net/
	"

	^#(in-library mini-kanren
			(load (system-path 'ulisp/minikanren/mkdefs.scm')))



]

{ #category : #booleans }
ULisp class >> nullPrintString [

	^ '()'
]

{ #category : #libraries }
ULisp class >> pregexp [

	"Portable Regular Expressions for Scheme and Common Lisp, by Dorai Sitaram

	http://www.ccs.neu.edu/~dorai/pregexp/pregexp.html
	"

	^#(in-library pregexp

			(define (test-pregexp)
				(load (system-path 'ulisp/pregexp/tester.scm'))
				(load (system-path 'ulisp/pregexp/pregexp-test.scm')))

			(load (system-path 'ulisp/pregexp/pregexp.scm')))



]

{ #category : #booleans }
ULisp class >> preserveNil [

	^ false
]

{ #category : #libraries }
ULisp class >> pseudoSyntaxRules [

	"
	implements syntax-rules, let-syntax and letrec-syntax as a NON HYGIENIC macro system, initially developed for Common Lisp.

	adapted from code by Dorai Sitaram
	http://www.ccs.neu.edu/home/dorai/mbe/mbe-lsp.html
	"

	^#(in-library pseudo-syntax-rules
			(load (system-path 'ulisp/mbe.lsp')))



]

{ #category : #libraries }
ULisp class >> schelog [

	"Prolog-style logic programming in Scheme, by Dorai Sitaram

	http://www.ccs.neu.edu/home/dorai/schelog/schelog.html
	"

	^#(in-library schelog
			(load (system-path 'ulisp/schelog/schelog.scm')))



]

{ #category : #libraries }
ULisp class >> scheme [

	"some code here from 'The Scheme Programming Language' (third edition) by R. Kent Dybvig [tspl3]
	http://www.scheme.com/tspl3/

	some code from 'Teach Yourself Scheme in Fixnum Days' by Dorai Sitaram [tysfn]
	http://www.ccs.neu.edu/home/dorai/t-y-scheme/t-y-scheme.html
	"

	^#(in-library scheme

"aliases for already defined lisp functions. 
we keep the lisp symbol definition"
(define memv member)
(define begin progn)
(define #'null?' null)
(define #'atom?' atom)

"named let defined as a macro. see usage is ULisp>>#let:"
(defmacro ulisp-named-let (sym init . body)
	`((letrec: ((,sym (lambda: ,(map: first init) ,@body))) ,sym) ,@(map: second init))) 

"recycle destructively already defined lisp functions
we do not keep the lisp symbol definition"
(defmacro defsalias (ssymb lsymb)
	`(progn:
		(define ,ssymb ,lsymb)
		(makunbound `,lsymb)))

(defsalias add1 #'1+')
(defsalias = n-equal)
(defsalias #'eq?' eq)
(defsalias #'pair?' #'cons?')
(defsalias #'set-car!' setcar)
(defsalias #'set-cdr!' setcdr)
(defsalias #'string->symbol' intern)
(defsalias #'string->uninterned-symbol' make-symbol)
(defsalias write prin1)

(defsalias char-upper-case? upper-case?)
(defsalias char-lower-case? lower-case?)


"aliases"
(define #'call/cc' call-with-current-continuation)


"pairs"
(defunary last-pair last)	"srfi-1"

"characters"

(define #'char=?' eq?)
(define #'char<=?' <=)
(define #'char>=?' >=)
(define #'char<?' <)
(define #'char>?' >)
(defbinary #'char-ci=?' sameAs:)
(defunary char-upcase asUppercase)
(defunary char-downcase asLowercase)
(define (#'char-ci<?' c1 c2) (< (char-upcase c1) (char-upcase c2)))
(define (#'char-ci<=?' c1 c2) (<= (char-upcase c1) (char-upcase c2)))
(define (#'char-ci>?' c1 c2) (> (char-upcase c1) (char-upcase c2)))
(define (#'char-ci>=?' c1 c2) (>= (char-upcase c1) (char-upcase c2)))

"strings"

(define string-copy copy)
(define string-append concat)
(define string-length length)
(define string-ref elt)
(defbinary #'string=?' =)
(defbinary #'string-ci=?' sameAs:)
(define #'string<=?' <=)
(define #'string>=?' >=)
(define #'string<?' <)
(define #'string>?' >)
(defunary string-upcase asUppercase)
(defunary string-downcase asLowercase)
(defunary string-upcase! asUppercase)
(defunary string-downcase! asLowercase)
(define (#'string-ci<?' c1 c2) (< (string-upcase c1) (string-upcase c2)))
(define (#'string-ci<=?' c1 c2) (<= (string-upcase c1) (string-upcase c2)))
(define (#'string-ci>?' c1 c2) (> (string-upcase c1) (string-upcase c2)))
(define (#'string-ci>=?' c1 c2) (>= (string-upcase c1) (string-upcase c2)))

"complex numbers"

(define (make-rectangular x y)
	(send Complex real:imaginary: x y))

(define (make-polar r t)
	(send Complex abs:arg: r t))

(defunary magnitude abs)
(defunary angle arg)
(defunary real-part real)
(defunary imag-part imaginary)

"vectors"

(define vector-length length)
(define vector-ref elt)
(define (#'list->vector' args) (apply vector args))

"I/O"

(define call-with-output-file
  (lambda (filename proc)
'Creates a new output port for the file named by FILENAME and passes this port to PROC. An error is signaled if the file cannot be opened for output. If PROC returns, call-with-output-file closes the output port and returns the value returned by PROC'
    (let ((p (open-output-file filename)))
      (let ((v (proc p)))
        (close-output-port p)
        v))))

(defunary close-input-port close)
(defunary close-output-port close)

"delayed evaluation with multiple value support
from tspl3, sections 5.6 and 5.7"

(defmacro delay (exp)
  `(make-promise (lambda () ,exp)))

(define make-promise
  (lambda (p)
    (let ((vals false) (set? false))
      (lambda ()
        (if (not set?)
            (call-with-values p
              (lambda x
                (if (not set?)
                    (begin (set! vals x)
                           (set! set? true))))))
        (apply values vals))))) 

(define force
  (lambda (promise)
    (promise)))


"fluid-let
from tysfn, section 8.3"

(define-macro fluid-let 
	(lambda (xexe . body)
		(let ((xx (map car xexe))
			(ee (map cadr xexe))
			(old-xx (map (lambda (ig) (gensym)) xexe))
			(result (gensym)))
	`(let ,(map (lambda (old-x x) `(,old-x ,x)) 
							old-xx xx)
		,@(map (lambda (x e)
					`(set! ,x ,e)) 
				xx ee)
		(let ((,result (begin ,@body)))
			,@(map (lambda (x old-x)
								`(set! ,x ,old-x)) 
					xx old-xx)
           ,result)))))

"reverse!
from tysfn, section 6.3"

(define reverse!
  (lambda (s)
    	(let loop ((s s) (r `()))
      	(if (null? s) r
	  		(let ((d (cdr s)))
            		(set-cdr! s r)
	    			(loop d s))))))

"to do..."

(define #'inexact->exact' identity)
(define #'exact->inexact' identity)


(define disassemble procedure-source)

)
]

{ #category : #benchmarks }
ULisp class >> setUpCode [

	^ {
'(define (fib x)
	 (if (< x 2)
		x
		(+ (fib (- x 1)) (fib (- x 2)))))'.
	}

]

{ #category : #libraries }
ULisp class >> setter [

	"setter for generalized set!	
	from http://srfi.schemers.org/srfi-17/srfi-17-twobit.scm"

	^#(in-library setter

(define setter 
  (let ((setters (list (cons car  set-car!)
                       (cons cdr  set-cdr!)
                       (cons caar (lambda (p v) (set-car! (car p) v)))
                       (cons cadr (lambda (p v) (set-car! (cdr p) v)))
                       (cons cdar (lambda (p v) (set-cdr! (car p) v)))
                       (cons cddr (lambda (p v) (set-cdr! (cdr p) v)))
                       (cons vector-ref vector-set!)
                       (cons string-ref string-set!))))
    (letrec ((setter
              (lambda (proc)
                (let ((probe (assv proc setters)))
                  (if probe
                      (cdr probe)
                      (error 'No setter for ' proc)))))
             (set-setter!
              (lambda (proc setter)
                (set! setters (cons (cons proc setter) setters))
           "    (unspecified)" )))
      (set-setter! setter set-setter!)
      setter)))
)



]

{ #category : #libraries }
ULisp class >> slibInit [

	"SLIB is a portable library for Scheme:
	http://swiss.csail.mit.edu/~jaffer/SLIB.html

	the code here should enable SLIB for ULisp on Windows, Unix and MacOS systems. 
	on other systems your mileage may vary. please report any trouble and according fixes.  
	----------------"

	^#(in-library slib-init


" (software-type) should be set to the generic operating system type.
unix, macos, ms-dos, vms, and amiga are supported by SLIB ."
(define (software-type) 
	(case (platform-name)
		(('Win32') `ms-dos)
		(('unix') `unix)
		(('Mac OS') `macos)))

"(scheme-implementation-type) should return the name of the scheme
implementation loading this file."
(define (scheme-implementation-type) `ULisp)

"(scheme-implementation-home-page) should return a (string) URI
(Uniform Resource Identifier) for this scheme implementation's home
page; or false if there isn't one."
(define (scheme-implementation-home-page) false)

"(scheme-implementation-version) should return a string describing
the version the scheme implementation loading this file."
(define (scheme-implementation-version) ' v1')

"(implementation-vicinity) should be defined to be the pathname of
the directory where any auxillary files to your Scheme
implementation reside."
(define (implementation-vicinity) (system-path 'ulisp/'))

"(library-vicinity) should be defined to be the pathname of the
directory where files of Scheme library functions reside."
(define (library-vicinity) (system-path 'ulisp/slib/'))

"(home-vicinity) should return the vicinity of the user's HOME
directory, the directory which typically contains files which
customize a computer environment for a user."
(define home-vicinity implementation-vicinity)

(define in-vicinity string-append)

(define (user-vicinity) '')
 
(define #'*load-pathname*' false)

(define #'vicinity:suffix?'
    (lambda (chr) (eqv? chr (path-name-delimiter))))

(define (#'pathname->vicinity' pathname)
  (let loop ((i (- (string-length pathname) 1)))
    (cond ((negative? i) '')
	  ((#'vicinity:suffix?' (string-ref pathname i))
	   (substring pathname 0 (+ i 1)))
	  (else (loop (- i 1))))))

(define (program-vicinity)
  (if #'*load-pathname*' 
      (#'pathname->vicinity' #'*load-pathname*' )
      (slib:error `program-vicinity ' called; use slib:load to load')))

(define sub-vicinity
	(lambda (vic name)
		(string-append vic name (make-string 1 (path-name-delimiter)))))

(define (make-vicinity #'<pathname>') #'<pathname>')

(define with-load-pathname
  (let ((exchange
	 (lambda (new)
	   (let ((old #'*load-pathname*' ))
	     (set! #'*load-pathname*'  new)
	     old))))
    (lambda (path thunk)
      (let ((old false))
		(set! old (exchange path))
	"	(unwind-protect"
	"....................dynamic-wind"
			(apply thunk `())
	    		(exchange old))))) ")"

"*FEATURES* is a list of symbols naming the (SLIB) features
initially supported by this implementation."
(define #'slib:features'
      `(
	source		
	vicinity
"	#'srfi-59'  "

	r5rs				
	eval				
	values				
"	dynamic-wind		"
"	macro		"		
	delay				
"	multiarg-apply			"
"	char-ready?"
"	rev4-optional-procedures"

	string-case
	string-port
	r4rs				

"	ieee-p1178			"

	full-continuation		
	ieee-floating-point		

"	srfi			"	

	defmacro			
	promise
	))

(define (output-port-width . arg) 79)

(define (output-port-height . arg) 24)

(define current-error-port
  (let ((port (current-output-port)))
    (lambda () port)))

(define tmpnam (let ((cntr 100))
		 (lambda () (set! cntr (+ 1 cntr))
			 (string-append 'slib_' (#'number->string' cntr)))))


(define (delete-file f) false)

"FORCE-OUTPUT flushes any pending output on optional arg output port
use this definition if your system doesn''t have such a procedure."
(define (force-output . arg) true)

"'CHAR-CODE-LIMIT is one greater than the largest integer which can
be returned by CHAR->INTEGER."
(define char-code-limit 256)

"';;@ MOST-POSITIVE-FIXNUM is used in modular.scm"
(define most-positive-fixnum 16rFFFFFFF)

(define (identity x) x)

"SLIB:EVAL is single argument eval using the top-level (user) environment."
(define slib:eval eval)

";; If your implementation provides R4RS macros:"
(define macro:eval slib:eval)
(define macro:load load)

(define defmacro:eval slib:eval)


(define gentemp gensym)

(define base:eval slib:eval)

"
(define slib:warn
  (lambda args
    (let ((cep (current-error-port)))
      (if (provided? $'trace) (print-call-stack cep))
      (display 'Warn: ' cep)
      (for-each (lambda (x) (display #'#\ ' cep) (write x cep)) args))))
"
(define (slib:warn . args)
	(princ 'Warn:')
	(for-each (lambda (x) (princ ' ') (princ x)) args)
 	(print ''))

"define an error procedure for the library"
(define (slib:error . args)
  (if (provided? `trace) (print-call-stack (current-error-port)))
  (error (prin1-to-string args)))

(define (make-exchanger obj)
  (lambda (rep) (let ((old obj)) (set! obj rep) old)))
(define (open-file filename modes)
  (case modes
    ((r rb) (open-input-file filename))
    ((w wb) (open-output-file filename))
    (else (slib:error `open-file `mode? modes))))
(define (port? obj) (or (input-port? port) (output-port? port)))
(define (call-with-open-ports . ports)
  (define proc (car ports))
  (cond ((procedure? proc) (set! ports (cdr ports)))
	(else (set! ports (reverse ports))
	      (set! proc (car ports))
	      (set! ports (reverse (cdr ports)))))
  (let ((ans (apply proc ports)))
    (for-each close-port ports)
    ans))
(define (close-port port)
  (cond ((input-port? port)
	 (close-input-port port)
	 (if (output-port? port) (close-output-port port)))
	((output-port? port) (close-output-port port))
	(else (slib:error `close-port `port? port))))

"(define (browse-url url) ......"

";;@ define these as appropriate for your system."
(define slib:tab (#'integer->char' 9))
(define slib:form-feed (#'integer->char' 12))


";;@ Define SLIB:EXIT to be the implementation procedure to exit or
;;; return if exiting not supported."
(define slib:exit (lambda args false))

(define scheme-file-suffix 
    (lambda () '.scm'))

";;@ (SLIB:LOAD-SOURCE 'foo') should load 'foo.scm' or with whatever
;;; suffix all the module files in SLIB have.  See feature 'SOURCE."
(define (string-ending str n)
	(let* ((len (length str))
		   (n (min n len)))
		(substring  str (- len n) len)))

(define (slib:load-source f) 
	(load: (if (equal? '.scm' (string-ending f 4))
				f
				(string-append f '.scm'))
		true))

(define slib:load slib:load-source)

(define defmacro:load slib:load)

(slib:load (in-vicinity (library-vicinity) 'require'))


(define (call-with-output-string proc)
	(let ((p (send LKIOPort forOutput)))
		(proc p)
		(send (send (send p stream) contents) asString)))

)



]

{ #category : #libraries }
ULisp class >> slibIntegration [

	"transparently using SLIB"

	^#(in-library slib-integration

(defun display-source (symbol) 
	'Display the source code for the procedure bound to SYMBOL
This can be either Lisp or Smalltalk code' 
	(let ((proc (symbol-function symbol)))
		(if (#'primitive?' symbol) 
				(display (procedure-source proc))
			(require `pretty-print) 
			(pretty-print (procedure-source proc)))))
		
)



]

{ #category : #libraries }
ULisp class >> systemLibraries [

	"the bindings defined by these libraries will belong to the scheme-report-environment"

	^ #(glue #'provide-library' plist #'small-macros' common scheme setter loop #'turtle-graphics')
]

{ #category : #benchmarks }
ULisp class >> testCode [

	^ {
'(+ 1 1)'.
'(define (assoc x a)
	(cond
		((null? a) nil)
		((equal? x (car (car a))) (car a))
		(#t (assoc x (cdr a)))))'.
'(assoc 1 (list (list 2 5) (list 1 8)))'.
'(fib 12)'
		}
]

{ #category : #libraries }
ULisp class >> tinyClos [

	"CLOS-like object system for Scheme, by Gregor Kiczales:

	http://community.schemewiki.org/?Tiny-CLOS
	http://home.adelphi.edu/sbloch/class/archive/272/spring1997/tclos/tutorial.shtml
	"

	^#(in-library tiny-clos
			(load (system-path 'ulisp/tiny-clos/tiny-clos.scm')))



]

{ #category : #booleans }
ULisp class >> trueValue [

	^ true
]

{ #category : #booleans }
ULisp class >> trueValuePrintString [

	^ '#t'
]

{ #category : #libraries }
ULisp class >> ulispCompilers [

	"compiler optimizations -- experimental"

	^ 
	#(in-library ulisp-compilers

(require-library `compilers)

(put `define: `compiler `compile-define)


	)
]

{ #category : #private }
ULisp class >> wantsFullArgumentsListsSupport [

	^ false
]

{ #category : #'LISP-functions' }
ULisp >> LISPerror: aConsCell [

"(error STRING ...)
Raise a LispError with text (format STRING ...)"

	self lispError: 
		([self evalObject: (#(apply (function format)) asCons 
									addLast: aConsCell inQuotedCons)]
			on: Error do: [^ super error: aConsCell])


]

{ #category : #'LISP-functions' }
ULisp >> about: aConsCell [

"(about SYMBOL)
Describe the function definition and value of SYMBOL."

	| v sym |

	(sym := aConsCell car) isSymbol ifFalse: [self lispError: 'not a symbol'].

	v := self symbolValue: aConsCell car ifNone: [nil].

	self output:
		((self procedureP: v inCons) = self trueValue
			ifTrue: ['Procedure: ', (self documentation: aConsCell), String cr]
			ifFalse: [sym, (v ifNil: [' is unbound'] ifNotNil: [' is bound to ', (v printStringForLisp: self)]), String cr]).

	^ self trueValue
]

{ #category : #'LISP-functions' }
ULisp >> apply: aConsCell [

"(apply PROCEDURE &rest ARGS)
Call PROCEDURE with the remaining args, using the last arg as list of args.
Return the value PROCEDURE returns.
For example, (apply + 1 2 $'(3 4)) returns 10."

	(self isProcedure: aConsCell car)
		ifFalse: [self lispError: 'Invalid function: ', aConsCell car asString].

	^ super apply: aConsCell
]

{ #category : #'LISP-functions' }
ULisp >> assv: aConsCell [

"(assv KEY LIST)
Return non-nil if KEY is `eqv' to the car of an element of LIST.
The value is actually the element of LIST whose car is KEY.
Elements of LIST that are not conses are ignored."

	| key |

	key := aConsCell car.
	(key isConsCell
		or: [key isString]
		or: [key isArray])
	ifTrue: [^ self assq: aConsCell].

	^ self assoc: aConsCell

]

{ #category : #'LISP-functions-predicates' }
ULisp >> booleanP: aConsCell [

"(boolean? OBJECT)
Return t if OBJECT is either #t or #f."

	^ self class test: (aConsCell car == self trueValue or: [aConsCell car == self falseValue])
]

{ #category : #'LISP-functions' }
ULisp >> boundSymbols: ignored [

"(bound-symbols)
Return a list of all bound symbols, except those bound to a procedure"

	^ (environment allBoundSymbols
		reject: [:s | self isProcedure: (environment symbolValue: s)])
	 asConsList


]

{ #category : #'LISP-functions-continuations' }
ULisp >> callWithCurrentContinuation: aConsCell [

	| escapeFunction cc |

	((cc := self currentContinuation) isLKContinuation) ifFalse: 
	[
		cc cdr ifNil: [^ cc car].
		^ cc topForms as: LKValues
	].

	escapeFunction := self makeClosureFor: {#lambda: . #arg . {#sendMessage: . {#quote . #value:}. cc . #arg}} asCons.  

	^ self evalTailObject: ((ConsCell car: aConsCell car) addLast: escapeFunction) 
	



]

{ #category : #'LISP-functions' }
ULisp >> callWithInputFile: aConsCell [

"(call-with-input-file FILENAME PROC)
"

	| result file |

	file := StandardFileStream readOnlyFileNamed: aConsCell car.
	file ifNil: [self lispError: 'Could not read file "', aConsCell car asString, '"'].
	result := aConsCell cadr applyTo: (LKIOPort input: file) inCons
				inLisp: self asMacro: true.

	file close.

	^ result
]

{ #category : #'LISP-functions' }
ULisp >> callWithInputString: aConsCell [

"(call-with-input-string STRING PROC)
"

	^ aConsCell cadr applyTo: (LKIOPort input: (ReadStream on: aConsCell car)) inCons
		inLisp: self
		asMacro: true
]

{ #category : #'LISP-functions' }
ULisp >> callWithValues: aConsCell [

	^ self apply: 
		(aConsCell cdr copy addLast:
				(self evalToValues: aConsCell car inCons) asCons)
]

{ #category : #'LISP-functions' }
ULisp >> car: aConsCell [

"(car LIST)
Return the car (also called the head) of LIST.  If LIST is nil, signal an error"

	aConsCell car ifNil: [self lispError: 'pair expected, got the empty list'].

	^ super car: aConsCell 

]

{ #category : #'LISP-special forms' }
ULisp >> case: aConsCell [

"(case KEY &rest CLAUSES)"

	| key |

	key := self evalObject: aConsCell car.

	aConsCell cdr do: [:clause | | block |
		block := [:forms | 
				(forms ifNil: [^ nil]) 
					doWithCdr: [:c :cdr | 
						cdr ifNil: [^ self evalTailObject: c].
						self evalObject: c]].
		clause car = #else ifTrue: [^ block value: clause cdr].
		clause car do: [:datum | 
			datum = key ifTrue: [^ block value: clause cdr]]].
	
	^ nil


]

{ #category : #'LISP-functions' }
ULisp >> catch: aConsCell [

"(catch TAG THUNK HANDLER &rest PRE-UNWIND-HANDLER)
Call THUNK allowing nonlocal exits"

	| val |

	aConsCell ifNil: [^ nil].

	[val := self funcall: (aConsCell cdr ifNil: [^ nil])]
		on: Exception
		do: [:spec | ^ self funcall: (aConsCell cddr ifNil: [^ nil])].

	^ val

	
]

{ #category : #'LISP-functions' }
ULisp >> cdr: aConsCell [

"(cdr LIST)
Return the cdr (also called the tail) of LIST.  If LIST is nil, signal an error"

	aConsCell car ifNil: [self lispError: 'pair expected, got the empty list'].

	^ super cdr: aConsCell 

]

{ #category : #'LISP-functions-predicates' }
ULisp >> charAlphabeticP: aConsCell [

"(char-alphabetic? CHARACTER)
Return #t if CHARACTER is a letter"

	aConsCell car isCharacter ifFalse: [self lispError: 'character expected'].
	^ self class test: aConsCell car isLetter
]

{ #category : #'LISP-functions' }
ULisp >> charDowncase: aConsCell [ 

	^ aConsCell car asLowercase
]

{ #category : #'LISP-functions-predicates' }
ULisp >> charNumericP: aConsCell [

"(char-numeric? CHARACTER)
Return #t if CHARACTER is a digit"

	aConsCell car isCharacter ifFalse: [self lispError: 'character expected'].
	^ self class test: aConsCell car isDigit 
]

{ #category : #'LISP-functions-predicates' }
ULisp >> charP: aConsCell [

"(char? OBJECT)
Return #t if OBJECT is a character."

	^ self class test: aConsCell car isCharacter
]

{ #category : #'LISP-functions' }
ULisp >> charTOinteger: aConsCell [ 

	^ aConsCell car asciiValue
]

{ #category : #'LISP-functions' }
ULisp >> charUpcase: aConsCell [ 

	^ aConsCell car asUppercase
]

{ #category : #'LISP-functions-predicates' }
ULisp >> charWhitespaceP: aConsCell [

"(char-whitespace? CHARACTER)
Return #t if CHARACTER is either space, tab, line feed, form feed, or carriage return"

	aConsCell car isCharacter ifFalse: [self lispError: 'character expected'].
	^ self class test: aConsCell car isSeparator 
]

{ #category : #'LISP-functions' }
ULisp >> closeOutputPort: aConsCell [

"(close-output-port OUTPUT-PORT)
Closes an output port"
	
	aConsCell car close.
	^ self trueValue
]

{ #category : #'LISP-functions-predicates' }
ULisp >> complexP: aConsCell [

	^ self test: (aConsCell car isComplex or: [aConsCell car isNumber])
".. we need the double test for Squeak 3.8 where a Complex answsers false to #isNumber"
]

{ #category : #'LISP-special forms' }
ULisp >> cond: aConsCell [

"(cond &rest CLAUSES)
Try each clause until one succeeds.
Each clause normally look like (CONDITION &rest BODY).  CONDITION is evaluated and, if the value is non-nil, this clause succeeds:
then the expressions in BODY are evaluated and the last one's
value is the value of the cond-form.
Special clauses are:
(CONDITION => EXPRESSION)
(else EXPRESSION)

If no clause succeeds, cond returns nil.
If a clause has one element, as in (CONDITION),
CONDITION's value if non-nil is returned from the cond-form."

	aConsCell do: [:clause | | v |
		v := clause first == #else
			ifTrue: [self trueValue]
			ifFalse: [self evalObject: clause first].
		(v == self falseValue) ifFalse: 
		[
			clause cdr ifNil: [^ v].
			clause cadr == #=> ifTrue: 
				[^ self evalTailObject: ((self evalObject: clause cdr cdr car) inCons
											 addLast: v inQuotedCons)].
			clause cdr doWithCdr: [:c :cdr | 
				cdr ifNil: [^ self evalTailObject: c].
				self evalObject: c]
		]].

	^ self falseValue
]

{ #category : #'private - initialization' }
ULisp >> constantBindings [

	^ IdentityDictionary new
	

]

{ #category : #private }
ULisp >> currentContinuation [

	^ LKContinuation 
		upTo: (self class lookupSelector: #enterInterpreterContextAndEval:).

]

{ #category : #'LISP-functions' }
ULisp >> currentInputPort: ignored [

"(current-input-port)
Returns the current input port"
	
	^ self standardInput
]

{ #category : #'LISP-functions' }
ULisp >> currentOutputPort: ignored [

"(current-output-port)
Returns the current output port"
	
	^ self standardOutput
]

{ #category : #'private - initialization' }
ULisp >> defaultBindings [

	| db |

	db := super defaultBindings.

	db add: #'*print-circle*' -> false.

	^ db

	
	

]

{ #category : #'LISP-special forms' }
ULisp >> define: aConsCell [

	| s val |

	(s := aConsCell car) isSymbol
		ifTrue: [val := self evalObject: aConsCell cadr]
		ifFalse:
		[
			(aConsCell car isConsCell
				and: [(s := aConsCell car car) isSymbol])
			ifTrue: [ | spec |
				spec := aConsCell car cdr.
				spec isSymbol ifTrue: [spec := {#'&rest' . spec} asConsList].
				val := self makeClosureFor: (((ConsCell car: #lambda) addLast: spec) append: aConsCell cdr)
				]
			ifFalse: [self lispError: 'symbol expected, got ', s asString]
		].	

	self symbolValuesAdd: (self checkSymbol: s) -> val.
	^ s
]

{ #category : #'LISP-special forms' }
ULisp >> defineMacro: aConsCell [

	| s val |

	(s := aConsCell car) isSymbol
		ifTrue: [val := self evalObject: (aConsCell cadr copy setcar: #macro)]
		ifFalse:
		[
			(aConsCell car isConsCell
				and: [(s := aConsCell car car) isSymbol])
			ifTrue: [ | spec |
				spec := aConsCell car cdr.
				spec isSymbol ifTrue: [spec := {#'&rest' . spec} asCons].
				val := self makeClosureFor: (((ConsCell car: #macro) addLast: spec) append: aConsCell cdr)
				]
			ifFalse: [self lispError: 'symbol expected, got ', s asString]
		].	

	self symbolValuesAdd: (self checkSymbol: s) -> val.
	^ s
]

{ #category : #'LISP-special forms' }
ULisp >> defvar: aConsCell [

"(defvar SYMBOL VALUE)
An alias for define.
-- you should not use this special form in Scheme --"

	^ self define: aConsCell
]

{ #category : #'LISP-functions' }
ULisp >> display: aConsCell [

"(display obj [port])
Writes a representation of obj to the given port. Strings that appear in the written representation are not enclosed in doublequotes, and no characters are escaped within those strings. Character objects appear in the representation as if written by write-char instead of by write."

	self princ: aConsCell.
	^ self trueValue
]

{ #category : #'LISP-functions-predicates' }
ULisp >> eofObjectP: aConsCell [ 

"(eof-object? OBJECT)
Returns #t if OBJECT is an end of file object, otherwise returns #f"

	^ self test: (aConsCell car == LKIOPort eof)
]

{ #category : #'LISP-functions-predicates' }
ULisp >> equalP: aConsCell [
	
"(equal? O1 O2)
Return #t if O1 and O2 are similar objects."

	^ self class test: aConsCell car = aConsCell cadr

]

{ #category : #'LISP-functions-predicates' }
ULisp >> eqvP: aConsCell [
	
"(eqv? O1 O2)
Return #t if O1 and O2 are equivalent objects."

	(aConsCell car isConsCell
		or: [aConsCell car isString]
		or: [aConsCell car isArray])
	ifTrue: [^ self class test: aConsCell car == aConsCell cadr].

	^ self class test: aConsCell car = aConsCell cadr

]

{ #category : #private }
ULisp >> evalIrregularProcedure: aWouldBeProcedure withArguments: aConsCell [

	"subclasses may consider any object as a procedure and handle its evaluation here"

	self evalList: aConsCell. 
	"this allows a continuation jump from the arguments evaluation.
http://groups.google.com/groups?selm=87g00y4b6l.fsf%40radish.petrofsky.org"

	self lispError: 'Invalid function: ', aWouldBeProcedure asString
]

{ #category : #'LISP-functions-predicates' }
ULisp >> exactP: aConsCell [

	"not implemented"

	^ self trueValue	
]

{ #category : #'LISP-functions' }
ULisp >> fboundSymbols: ignored [

"(fbound-symbols)
Return a list of all symbols bound to a procedure"

	^ (environment allBoundSymbols
		select: [:s | self isProcedure: (environment symbolValue: s)])
	 asConsList

]

{ #category : #'LISP-functions' }
ULisp >> forEach: aConsCell [

	self map: aConsCell.
	^ nil
]

{ #category : #'private - initialization' }
ULisp >> getNewEnvironment [

	self lispEnvironment: LK1Environment new.


]

{ #category : #GUI }
ULisp >> guiColor [

	^ (Color r: 0.8 g: 0.664 b: 0.8) darker
]

{ #category : #'LISP-special forms' }
ULisp >> if: aConsCell [

"(if COND THEN &optional ELSE)
If COND yields non-nil, do THEN, else do ELSE
Returns the value of THEN or the value of ELSE.
If COND yields nil and there is no ELSE, return ()."

"
	aConsCell length > 3 ifTrue: 
		[self lispError: 'If: too many arguments'].

	^ ((self evalObject: aConsCell car) == self falseValue)
		ifFalse: [self evalTailObject: (aConsCell nth: 1)]
		ifTrue: [self evalTailObject: (aConsCell nth: 2 ifAbsent: [^ nil])]
"

	^ super if: aConsCell
	"we accept more than two arguments, for compatibility with lisp code
defined in superclasses: "
]

{ #category : #'LISP-functions-predicates' }
ULisp >> inexactP: aConsCell [

	"not implemented"

	^ self falseValue	
]

{ #category : #'private - initialization' }
ULisp >> initialEnvironment [

	^ initialEnvironment
]

{ #category : #'private - initialization' }
ULisp >> initialize [

	super initialize.

	self class primitives do: [:prim  | 
		self symbolValuesAdd: prim -> (LKPrimitive selector: prim for: self class)].

	
]

{ #category : #'private - initialization' }
ULisp >> initializeEnvironments [

	initialEnvironment := environment.
	userEnvironment := environment := environment newChild.

]

{ #category : #'LISP-functions-predicates' }
ULisp >> inputPortP: aConsCell [

"(input-port? OBJECT)
Returns #t if OBJECT is an input port, #f otherwise"
	
	^ self test: (aConsCell car isLKIOPort and: [aConsCell car isInput])
]

{ #category : #'private - initialization' }
ULisp >> installPrimitiveAliases: bindings [

	| aliases topEnvironment |

	aliases := bindings collect: [:b | b copy].
	topEnvironment := initialEnvironment ifNil: [environment].
	
	"clean up previous definitions"
	topEnvironment allBoundSymbols do: [:f |  | p |
		(((p := topEnvironment symbolValue: f ) isLKPrimitive)
			and: [(self class primitives pointsTo: p selector) not])
		ifTrue: [topEnvironment removeSymbolValue: f]].

	"create new definitions"
	aliases do: [:alias | 
		((topEnvironment bindsSymbol: alias key) not
			or: [(topEnvironment symbolValue: alias key) isSymbol])
		ifTrue: [
			topEnvironment addSymbolValue: alias.
			topEnvironment addSymbolValue: alias value selector -> alias value
		]].



]

{ #category : #'LISP-functions' }
ULisp >> integerTOchar: aConsCell [

	^ Character value: aConsCell car
]

{ #category : #'LISP-functions' }
ULisp >> interactionEnvironment: ignored [

	^ userEnvironment


]

{ #category : #private }
ULisp >> isProcedure: anObject [

	^ anObject isLKPrimitive
			or: [anObject isLispClosure]
			or: [anObject isMacro]
			or: [anObject isCompiledProcedure]

]

{ #category : #'LISP-functions-predicates' }
ULisp >> keywordP: aConsCell [

	"keyword? is not a valid Scheme function"	

	self lispError: 'keyword? is currently undefined in ULisp'

]

{ #category : #'LISP-functions-beware' }
ULisp >> last: aConsCell [

"(last LIST)
Return the last element of LIST"

"BEWARE: this is not the same semantics as the last function in Common Lisp
see SRFI-1"

	aConsCell car ifNil: [self lispError: 'list expected'].
	^ aConsCell car last car
	
]

{ #category : #'LISP-special forms' }
ULisp >> let: aConsCell [

"(let VARLIST &rest BODY)
Bind variables according to VARLIST then eval BODY.
The value of the last form in BODY is returned.
Each element of VARLIST is a symbol (which is bound to nil) or a list (SYMBOL VALUEFORM) (which binds SYMBOL to the value of VALUEFORM).
All the VALUEFORMs are evaluated before any symbol is bound.

Named let idiom:

          (let name ((variable init) ...)
            expression
            expression ...)
          
is equivalent to

          ((letrec ((name
                     (lambda (variable ...)
                       expression
                       expression ...)))
             name)
           init ...)"

	aConsCell first isSymbol ifFalse: [^ super let: aConsCell].

	"named let"
	^ self evalObject: ((ConsCell car: #'ulisp-named-let') append: aConsCell) multipleValue: true



]

{ #category : #'LISP-special forms' }
ULisp >> letrec: aConsCell [

"(let VARLIST &rest BODY)
Bind variables according to VARLIST then eval BODY.
The value of the last form in BODY is returned.
Each element of VARLIST is a symbol (which is bound to nil) or a list (SYMBOL VALUEFORM) (which binds SYMBOL to the value of VALUEFORM).
All the VALUEFORMs are evaluated before any symbol is bound."

	| sublisp |

	sublisp := self subLisp: #letrec form: aConsCell body: aConsCell cdr. 

	aConsCell first ifNotNil:
	[
		(aConsCell first do: [:form | | sym |
			sym := sublisp checkSymbol: (form isSymbol
										ifTrue: [form ] ifFalse: [form first]).
			sublisp symbolValuesAdd: sym -> nil]).

		(aConsCell first collect: [:form | 
			form isSymbol
				ifTrue: [form -> nil]
				ifFalse: [form first -> (sublisp evalObject: (form nth: 1))]])
			do: [:v | sublisp symbolValuesAdd: v]
	].

	((aConsCell nthCell: 1) ifNil: [^ nil]) 
		doWithCdr: [:c :cdr | 
			cdr ifNil: [^ sublisp evalTailObject: c]. 
			sublisp evalObject: c]

]

{ #category : #'LISP-functions' }
ULisp >> listRef: aConsCell [

"(list-ref LIST N)
Return the Nth element of LIST.
N counts from zero.  If LIST is not that long, an error is raised"

	^ aConsCell car nth: aConsCell cadr ifAbsent: [self lispError: 'index out of range']

]

{ #category : #'LISP-functions' }
ULisp >> listTOstring: aConsCell [

	^ String streamContents: [:str |
			(aConsCell car ifNil: [^ '']) do: [:car | str nextPut: car ]]
]

{ #category : #'LISP-functions' }
ULisp >> listTail: aConsCell [

"(list-tail LIST N)
Return the elements of LIST after the Nth one.
N counts from zero.  If LIST is not that long, an error is raised"

	^ aConsCell car nthcdr: aConsCell cadr ifAbsent: [self lispError: 'index out of range']

]

{ #category : #'private - initialization' }
ULisp >> loadDefaultLibraries [

	self loadSystemLibraries.
	self initializeEnvironments.
	super loadDefaultLibraries.
]

{ #category : #'private - initialization' }
ULisp >> loadLibraries: anArray label: aString [

	aString displayProgressAt: Sensor cursorPoint
		from: 0 to: anArray size
		during: [:bar |
			anArray doWithIndex: [:lib :i | 
				self top: {#loadLibrary: . lib inQuotedCons}.
				bar value: i]]

]

{ #category : #'private - initialization' }
ULisp >> loadSystemLibraries [

	self class systemLibraries do: [:lib | self top: {#loadLibrary: . lib inQuotedCons}]

]

{ #category : #'private - subclasses may implement' }
ULisp >> lookUpFunction: anObject [

	"in Scheme a function can be an arbitrary form which evaluates to a lambda expression

	 ^ self evalObject: anObject

		would be enough, but we are a little faster here"

	anObject isLKPrimitive ifTrue: [^ anObject].
	anObject isLispClosure ifTrue: [^ anObject].
	anObject isSymbol ifFalse: [^ self evalObject: anObject].

	^ self symbolFunction: anObject ifNone: [anObject]  	

]

{ #category : #'private - subclasses may implement' }
ULisp >> lookUpFunctionCompile: anObject [

	anObject isLKPrimitive ifTrue: [^ anObject].
	anObject isLispClosure ifTrue: [^ anObject].
	anObject isSymbol ifFalse: [^ self compileObject: anObject].

	^ self symbolFunction: anObject ifNone: [anObject]  	

]

{ #category : #'LISP-functions' }
ULisp >> makeString: aConsCell [

	^ String new: aConsCell car withAll: (aConsCell cadr ifNil: [$-])


]

{ #category : #'LISP-functions' }
ULisp >> map: aConsCell [

	| proc lists |

	proc := aConsCell car.

	(proc isLispClosure or: [proc isLKPrimitive])
		ifFalse: [self lispError: 'Invalid function: ', proc asString].

	lists := aConsCell cdr.

	^ (aConsCell cadr ifNil: [^ nil]) collect: [:each | | v args |
		args := (lists collect: [:list | list car inQuotedCons]).
		v := self evalObject: (ConsCell car: proc cdr: args).
		lists := lists collect: [:list | list cdr].
		v]
]

{ #category : #'LISP-functions' }
ULisp >> modulo: aConsCell [

"
"

	^ aConsCell car \\ aConsCell cadr


]

{ #category : #'LISP-functions-predicates' }
ULisp >> negativeP: aConsCell [

"(negative? NUMBER)
Test weither NUMBER < 0."

	^ self class test: aConsCell car < 0
]

{ #category : #'LISP-functions' }
ULisp >> openInputFile: aConsCell [

"(open-input-file FILENAME)
Takes a string naming an existing file and returns an input port capable of delivering characters from the file"
	
	^ LKIOPort input: (StandardFileStream oldFileNamed: aConsCell car) 
]

{ #category : #'LISP-functions' }
ULisp >> openOutputFile: aConsCell [

"(open-output-file FILENAME)
Creates and returns a new output port for the file named by FILENAME. 
An error is signaled if the file cannot be opened for output."
	
	^ LKIOPort output: (StandardFileStream forceNewFileNamed: aConsCell car)
]

{ #category : #'LISP-functions-predicates' }
ULisp >> outputPortP: aConsCell [

"(output-port? OBJECT)
Returns #t if OBJECT is an output port, #f otherwise"
	
	^ self test: (aConsCell car isLKIOPort and: [aConsCell car isOutput])
]

{ #category : #'LISP-functions-predicates' }
ULisp >> positiveP: aConsCell [

"(positive? NUMBER)
Test weither NUMBER > 0."

	^ self class test: aConsCell car > 0
]

{ #category : #'LISP-functions-predicates' }
ULisp >> primitiveP: aConsCell [

"(primitive-p OBJECT)
Return #t if OBJECT is a primitive."

	| sel |

	sel := (aConsCell car isLKPrimitive 
			ifTrue: [aConsCell car selector] ifFalse: [^ self falseValue]).
	^ self class test: (self class primitives pointsTo: sel) 
	

]

{ #category : #'LISP-functions-predicates' }
ULisp >> procedureP: aConsCell [
	
"(procedure? OBJECT)
Return #t if OBJECT is a procedure."

	^ self class test: (self isProcedure: aConsCell car)


]

{ #category : #'LISP-functions' }
ULisp >> quotient: aConsCell [

"
"

	^ aConsCell car quo: aConsCell cadr


]

{ #category : #private }
ULisp >> reader [

	^ ULispReader for: self
]

{ #category : #'LISP-functions' }
ULisp >> remainder: aConsCell [

"
"

	^ aConsCell car - ((aConsCell car quo: aConsCell cadr) * aConsCell cadr)


]

{ #category : #'LISP-functions' }
ULisp >> schemeReportEnvironment: ignored [

	^ initialEnvironment


]

{ #category : #'LISP-special forms' }
ULisp >> set: aConsCell [

"(set SYMBOL NEWVAL)
Set SYMBOL's value to NEWVAL, and return NEWVAL.
-- you should not use this special form in Scheme --"

	| form |
	form := aConsCell listCopy.
	form setcar: (self evalObject: form car).

	^ self setD: form

]

{ #category : #'LISP-special forms' }
ULisp >> setD: aConsCell [

"(set! SYMBOL VALUE)
Changes the value bound to SYMBOL to VALUE.
An error is raised if SYMBOL is not bound.

(set! (PROC ...) VALUE)
Generalized setter: equivalent to ((setter PROC) ... VALUE)"

	| binding val sym |

	aConsCell car isConsCell ifTrue:
	[
		^ self evalObject: 
			(((#setter inCons append: aConsCell caar inCons) inCons 
				append2: aConsCell cdar)
				append: aConsCell cdr)
	].	

	sym := self checkSymbol: aConsCell car.
	binding := self lispEnvironment scopedSymbolBinding: sym.
	binding ifNil: [self lispError: 'unbound symbol ', sym].
	binding value: (val := self evalObject: aConsCell cadr).	
	^ val
]

{ #category : #'LISP-special forms' }
ULisp >> setq: aConsCell [

"(setq SYMBOL)
Changes the value bound to SYMBOL.
If symbol is not bound then define it at top level.
-- you should not use this special form in Scheme --"

	| binding val sym |
	sym := self checkSymbol: aConsCell car.
	binding := self lispEnvironment scopedSymbolBinding: sym.
	binding ifNil: [self define: aConsCell. ^ self evalObject: aConsCell car].
	binding value: (val := self evalObject: aConsCell cadr).	
	^ val
]

{ #category : #'private - subclasses may implement' }
ULisp >> sourceFileExtension [

	^ '.scm'
]

{ #category : #private }
ULisp >> standardInput [
	^inputPort ifNil: [inputPort := LKIOPort forInput]
]

{ #category : #private }
ULisp >> standardOutput [
	^outputPort ifNil: [outputPort := LKIOPort forOutput]
]

{ #category : #private }
ULisp >> standardOutput: aLKIOPort [ 
	outputPort := aLKIOPort
]

{ #category : #'LISP-functions' }
ULisp >> string: aConsCell [

"(string CHARACTERS)
Return a string with CHARACTERS"

	^ String withAll: aConsCell topForms

]

{ #category : #'LISP-functions' }
ULisp >> stringSetD: aConsCell [

	aConsCell car at: aConsCell cadr + 1 put: aConsCell cdr cadr.
	^ aConsCell car


]

{ #category : #private }
ULisp >> subLispForTailWithEnvironment: env [

	^ self copy lispEnvironment: env newChild
]

{ #category : #'private - subclasses may implement' }
ULisp >> symbolFunction: aSymbol ifNone: aBlock [

	 ^ environment symbolValue: aSymbol ifNone: aBlock

]

{ #category : #'LISP-functions' }
ULisp >> symbolTOstring: aConsCell [

	^ aConsCell car asString
]

{ #category : #'private - subclasses may implement' }
ULisp >> symbolValue: aSymbol ifNone: aBlock [

	 ^ environment symbolValue: aSymbol ifNone: aBlock

]

{ #category : #'private - initialization' }
ULisp >> topEnvironments [

	^ {initialEnvironment . userEnvironment}
]

{ #category : #'private - initialization' }
ULisp >> userEnvironment [

	^ userEnvironment 
]

{ #category : #'LISP-functions' }
ULisp >> vectorSetD: aConsCell [

"(vector-set! VECTOR INDEX VALUE)
Set the INDEXth element of VECTOR be VALUE."

	^ aConsCell first at: aConsCell second + 1 put: aConsCell third


]

{ #category : #'LISP-functions' }
ULisp >> withInputFromFile: aConsCell [

"(with-input-from-file FILENAME THUNK)
"

	| result file stdin |

	stdin := self standardInput.
	
	[
		(file := StandardFileStream readOnlyFileNamed: aConsCell car)
			ifNil: [self lispError: 'Could not read file "', aConsCell car asString, '"'].
		self standardInput: (LKIOPort input: file).
		result := self evalObject: aConsCell cdr.
		file close.
	]
	ensure: [self standardInput: stdin].

	^ result
]

{ #category : #'LISP-functions' }
ULisp >> withOutputToFile: aConsCell [

"(with-output-to-file FILENAME THUNK)
"

	| result file stdout |

	stdout := self standardOutput.
	
	[
		(file := FileDirectory default forceNewFileNamed: aConsCell car)
			ifNil: [self lispError: 'Could not write to file "', aConsCell car asString, '"'].
		self standardOutput: (LKIOPort output: file).
		result := self evalObject: aConsCell cdr.
		file close.
	]
	ensure: [self standardOutput: stdout].

	^ result
]

{ #category : #'LISP-functions' }
ULisp >> writeChar: aConsCell [

"(write-char char [port])
Writes the character char (not an external representation of the character) to the given port "

	| port |

	(port := aConsCell cadr ifNil: [self standardOutput]) stream
		nextPutAll: aConsCell car asString.
	port endEntry.
	^ self trueValue
]
