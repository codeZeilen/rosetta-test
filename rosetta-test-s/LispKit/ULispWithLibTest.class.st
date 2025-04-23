"
All tests for ULisp that do require loading the default libraries
"
Class {
	#name : #ULispWithLibTest,
	#superclass : #StaticLispTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
ULispWithLibTest class >> shouldInheritSelectors [

	^ false
]

{ #category : #'as yet unclassified' }
ULispWithLibTest >> setUp [

	lisp := ULisp new loadDefaultLibraries
]

{ #category : #'as yet unclassified' }
ULispWithLibTest >> testAmb [

	lisp top: #(load-library `amb).

	lisp top: #
(define number-between
  (lambda (lo hi)
    (let loop ((i lo))
      (if (> i hi) (amb)
          (amb i (loop (+ i 1))))))).

	lisp top: #
(define gen-prime
  (lambda (hi)
    (let ((i (number-between 2 hi)))
      (assert (prime? i))
	 i))).

	self assert: (lisp top: #(bag-of (gen-prime 20))) 
		= #(2 3 5 7 11 13 17 19) asCons
]

{ #category : #'as yet unclassified' }
ULispWithLibTest >> testAmb2 [

	lisp top: #(load-library `amb).

	self assert: (lisp top: #
(let ((a (amb 1 2 3 4 5 6)) (b (amb 1 2 3 4 5 6))) (assert (= 7 (+ a b))) (list a b)))
	= #(1 6) asCons.

	self assert: (lisp top: #(amb)) = #(2 5) asCons.
	self assert: (lisp top: #(amb)) = #(3 4) asCons.
	self assert: (lisp top: #(amb)) = #(4 3) asCons.
	self assert: (lisp top: #(amb)) = #(5 2) asCons.
	self assert: (lisp top: #(amb)) = #(6 1) asCons.

	self should: [lisp top: #(amb)] raise: LispError.

	self assert: (lisp top: #
(bag-of 
(let ((a (amb 1 2 3 4 5 6)) (b (amb 1 2 3 4 5 6))) (assert (= 7 (+ a b))) (list a b))))
		= #((1 6) (2 5) (3 4) (4 3) (5 2) (6 1)) asCons
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC [

	lisp top: #(define reciprocals
  					(lambda (ls)
    						(call-with-current-continuation
      						(lambda (k)
        							(map (lambda (x)
               							(if (= x 0)
                   								(k 'zero found')
                   								(/ 1 x)))
             								ls))))).

	self assert: (lisp top: #(reciprocals (list 2 (/ 1 3) 5 (/ 1 4))))
					=  { 1/2 . 3 . 1/5 . 4} asCons.

	self assert: (lisp top: #(reciprocals (list 2 (/ 1 3) 0 5 (/ 1 4))) ) asOneLispValue
					= 'zero found'

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC2 [

	lisp top: #(begin

(define retry false)

(define factorial
  (lambda (x)
    (if (= x 0)
        	(call-with-current-continuation (lambda (k) (set! retry k) 1))
        (* x (factorial (- x 1))))))
).

	self assert: (lisp top: #(factorial 4)) = 24.
	self assert: (lisp top: #(retry 1)) = 24.
	self assert: (lisp top: #(retry 2)) = 48.


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC3 [

	self assert: (lisp top: #(let ((x (call/cc (lambda (k) k))))
  									(x (lambda (ignore) 'hi')))) = 'hi'
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC4 [

	"according to R. Kent Dybvig (author of book 'The Scheme Programming Language'), the example below is 'the most confusing Scheme program of its size'"

	self assert: (lisp top: #(((call/cc (lambda (k) k)) (lambda (x) x)) 'HEY!')) = 'HEY!'
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC5 [

	lisp top: #(define k (call/cc (lambda (k) k))).
	lisp top: #(k 18).

	self assert: (lisp top: #k) = 18.

	lisp top: #(define k (call/cc call/cc)).
	lisp top: #(k 'yo').

	self assert: (lisp top: #k) = 'yo'

	"why it is so explained there: 	http://notvincenz.blogspot.com/2006/11/continuations.html"

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC6 [

	"the incredibly obfuscated factorial example from
	http://okmij.org/ftp/Scheme/callcc-calc-page.html

	as Oleg says:
	note, that there is no overt recursion nor iteration nor self-application"

	lisp top: #(define fact
         ((lambda (f)
            ((lambda (u) (u (lambda (x)
                      (lambda (n) ((f (u x)) n)))))
             (call/cc (call/cc (call/cc 
                (call/cc (call/cc (lambda (x) x))))))))
           (lambda (f) (lambda (n)
                (if (<= n 0) 1 (* n (f (- n 1)))))))).

	self assert: (lisp top: #(fact 10)) = 3628800

	

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC7 [

	"
	mondo-bizarro by Eugene Kohlbecker
	ACM SIGPLAN Lisp Pointers, Volume 1, Issue 2 (June-July 1987) pp 22-28
	"

	lisp top: #(define mondo-bizarro 
	(lambda ()
    		(let ((result '') 
                 (y (call-with-current-continuation (lambda (c) c))))
        	 (set! result (concat result '1'))
        	 (call-with-current-continuation (lambda (c) (y c)))
        	 (set! result (concat result '2'))
        	 (call-with-current-continuation (lambda (c) (y c)))
        	 (set! result (concat result '3'))))).

	self assert: (lisp top: #(mondo-bizarro)) = '11213'

	

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCallCC8 [

	"same as #testCallCC7, only with let*"

	lisp top: #(define mondo-bizarro 
	(lambda ()
    		(let* ((result '') 
                 (y (call-with-current-continuation (lambda (c) c))))
        	 (set! result (concat result '1'))
        	 (call-with-current-continuation (lambda (c) (y c)))
        	 (set! result (concat result '2'))
        	 (call-with-current-continuation (lambda (c) (y c)))
        	 (set! result (concat result '3'))))).

	self assert: (lisp top: #(mondo-bizarro)) = '11213'

	

]

{ #category : #'broken - to be fixed' }
ULispWithLibTest >> testCallCC9 [

	"http://list.cs.brown.edu/pipermail/plt-scheme/2009-February/030299.html"

	lisp top: #(define r false).
	lisp top: #(define count-calls 0).
	lisp top: #(begin
  (call/cc
    (lambda (k)
      (set! r k)
      true))
  (set! count-calls (+ count-calls 1))).

"I don't know what to expect, actually... "
"
	self assert: (lisp top: #(r true)) = 1
"
	

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testCond [

	self assert: (lisp top: #(cond 
								((list? (+ 1 1)) $'bah)
								((list? $'(+ 1 1)) $'yo)
								((list? 5) $'yep))) = #yo.

	self assert: (lisp top: #(cond 
								((list? (+ 1 1)) $'bah)
								((list? 5) $'yo))) = lisp falseValue.

	self assert: (lisp top: #(cond ((+ 1 1)))) = 2.

	self assert: (lisp top: #(cond 
								((list? (+ 1 1)) $'bah)
								(else $'yo))) = #yo.

	self assert: (lisp top: #(cond 
								((+ 2 2) => sqrt)
								(else $'yo))) = 2.

	self assert: (lisp top: #(cond 
								((assv $'b $'((a 1) (b 2))) => cadr)
		     					(else #f))) = 2
"
	... not implemented yet

	lisp loadDefaultLibraries.

	self assert: (lisp top: #(let ((=> 5)) (cond (1 => add1)))) = (lisp top: #(progn add1))
"
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDefcascade [

	self assert: (lisp top: 
		#(send-cascade $'((at:put: 2 $a) (copyFrom:to: 1 2)) 'hello')) = 'ha'.

	lisp top: #(defcascade yo ((at:put: 2 $a) (copyFrom:to: 1 2))).

	self assert: (lisp top: #(yo 'mimi')) = 'ma'

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDefine [

	lisp top: #(define (quadruple x)
   					(let ((double (lambda (x) (+ x x))))
      					(double (double x)))).

	self assert: (lisp top: #(quadruple 3)) = 12.

	lisp top: #(define quinze 15).
	self assert: (lisp top: #(begin quinze)) = 15.


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDefineMacro [

	lisp top: #(define-macro when1
  					(lambda (test . branch)
    						`(if ,test
        			 			(begin ,@branch)))).

	self assert: (lisp top: #(when1 (equal? 1 1) 12 45)) = 45.
	
	lisp top: #(define-macro (when2 test . branch)
    					`(if ,test
        		 			(begin ,@branch))).

	self assert: (lisp top: #(when2 (equal? 1 1) 12 45)) = 45.
	
	lisp top: #(defmacro when3 (test . branch)
    					`(if ,test
        		 			(begin ,@branch))).

	self assert: (lisp top: #(when3 (eq? 1 1) 12 45)) = 45.
	
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDefselectors [

	lisp top: #(defselectors cadddr2 (cdr (nthcdr: 2) car)).
	self assert: (lisp top: #(cadddr2  $'(1 2 3 4 5 6))) = 4

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDelayedEvaluation [

	lisp top: #(begin 

(define stream-car
  (lambda (s)
    (car (force s))))

(define stream-cdr
  (lambda (s)
    (cdr (force s))))

(define counters
  (let next ((n 1))
    (delay (cons n (next (+ n 1))))))
).

	self assert: (lisp top: #(stream-car counters)) = 1.
	self assert: (lisp top: #(stream-car (stream-cdr counters))) = 2.

	lisp top: #(begin 

(define stream-add
  (lambda (s1 s2)
    (delay (cons
             (+ (stream-car s1) (stream-car s2))
             (stream-add (stream-cdr s1) (stream-cdr s2))))))

(define even-counters
  (stream-add counters counters))
).

	self assert: (lisp top: #(stream-car even-counters)) =  2.
	self assert: (lisp top: #(stream-car (stream-cdr even-counters))) = 4
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDo [

	self assert: (lisp top: 
		#(let ((x (list 1 3 5 7 9)))
			(do ((x x (cdr x)) 
				(sum 0 (+ sum (car x)))) 
				((null? x) sum)))) = 25.

	self assert: (lisp top: 
		#(do ((vec (make-vector 5))
				(i 0 (+ i 1)))
				((= i 5) vec)
				(vector-set! vec i i))) = #(0 1 2 3 4)

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testDolist [

	lisp top: #(define test nil).
	self assert: (lisp top: #(dolist (i $'(10 20 30) (+ 1 1))
									(set! test (append test (list (* i i)))))) = 2.
	self assert: (lisp top: #(begin test)) = #(100 400 900) asCons.
	self should: [lisp top: #(begin i)] raise: LispError
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testEq [

	self assert: (lisp top: #(eq? 5 5)) = lisp trueValue.
	self assert: (lisp top: #(eq? 5 (+ 3 2))) = lisp trueValue.
	self assert: (lisp top: #(eq? (list 1 2) (list 1 2))) = lisp falseValue.
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testEval [

	lisp top: #(define test (lambda () (eval $'(define blep 452)) blep)).
	self assert: (lisp top: #(test)) = 452.
	self assert: (lisp top: #(begin blep)) = 452.

	self should: [lisp top: #(let ((x 10)) (eval $'x))] raise: LispError.

	lisp top: #(define test2 (lambda (n) (eval n))).
	self assert: (lisp top: #(test2 $'(+ 1 1))) = 2.
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testFluidLet [

	lisp top: #(begin
					(define counter 1)
					(define bump-counter
	  					(lambda ()
 	   						(set! counter (+ counter 1))
	    						counter))).

	self assert: (lisp top: #(bump-counter)) = 2.
	self assert: (lisp top: #(bump-counter)) = 3.

	self assert: (lisp top: #(fluid-let ((counter 99))
  									(list (bump-counter)  
										(bump-counter)  
										(bump-counter)))) = #(100 101 102) asCons.
	
	self assert: (lisp top: #(begin counter)) = 3.
	
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testLast [

	self assert: (lisp top: #(last $'(1 2 3 4))) = 4.      "srfi-1"
	self assert: (lisp top: #(last-pair $'(1 2 3 4))) = #(4) asCons.

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testLetRec2 [

	lisp top: #(define (property-list-search lis target)
   					(letrec ((loop (lambda (l)
                     						(cond 	((null? l) false)
                           							((eq? (car l) target) (car (cdr l)))
                           							(true (loop (cdr (cdr l))))))))
      					(loop lis))) .

	self assert: (lisp top: #(property-list-search
									$'(:un 1 :deux 2 :trois 3)
									$':deux)) = 2.


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testLetRec3 [

	self assert: (
	lisp top: #(letrec ((local-even? (lambda (n)
                     						(if (= n 0) true
                         						(local-odd? (- n 1)))))
      				 (local-odd? (lambda (n)
                    						(if (= n 0) false
                        						(local-even? (- n 1))))))
  					(list (local-even? 23) (local-odd? 23))) 
	) = #(false true) asCons.



]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testLoop [

	"loop returns multiple values, hence the #asOneLispValue message"

	lisp top: #(load-library $'loop).

	self assert: (lisp top: #(loop for i in $'(1 2 3)  collect i)) asOneLispValue 
		= #(1 2 3) asCons.
	self assert: (lisp top: #(loop for i from 1 to 4 collect i)) asOneLispValue 
		= #(1 2 3 4) asCons.
	self assert: (lisp top: #(loop until true finally (return 'a'))) asOneLispValue
		 = 'a'.

	"note: the following is allowed by CLtL2 but forbddien by ANSI CL"
	self should: [lisp top: #(loop until true finally return 'a')] raise: LispError
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testNamedLet [

	lisp top: #(define list?
  					(lambda (x)
    						(let race ((h x) (t x))
      						(if (pair? h)
          						(let ((h (cdr h)))
            							(if (pair? h)
               							(and (not (eq? h t))
                     								(race (cdr h) (cdr t)))
                							(null? h)))
          						(null? h))))).

	self assert: (lisp top: #(list? (list 2 (/ 1 3) 5 (/ 1 4))))	=  lisp trueValue.

	self assert: (lisp top: #(list? (cons 2 17))) = lisp falseValue.

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testNamedLet2 [

	self assert: (lisp top: #(let loop
               ((numbers `(3 -2 1 6 -5))
                (nonneg `())
                (neg `()))
            (cond ((null? numbers)
                   (list nonneg neg))
                  ((>= (car numbers) 0)
                   (loop (cdr numbers)
                         (cons (car numbers) nonneg)
                         neg))
                  (else
                   (loop (cdr numbers)
                         nonneg
                         (cons (car numbers) neg))))))
	= #((6 1 3) (-5 -2)) asCons

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testPregexp [

	"http://www.ccs.neu.edu/home/dorai/pregexp/pregexp.html"

	lisp top: #(load-library $'pregexp).
	lisp top: #(test-pregexp).

	self assert: (lisp top: #(begin #'*failed*')) = 0

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testPrimitivesRepresentation [

	self assert: (lisp top: #(symbol-function $'car)) printString = 'primitive car:'.
	self assert: (lisp top: #(symbol-function $'car:)) printString = 'primitive car:'.
	self assert: (lisp top: #car) printString = 'primitive car:'.
	self assert: (lisp top: #car:) printString = 'primitive car:'.
	self assert: ((lisp top: #(primitives)) topForms includes: #car).
	self assert: ((lisp top: #(primitives)) topForms includes: #car:) not.
	self assert: (lisp top: #(primitive? car)) = lisp trueValue.	
	self assert: (lisp top: #(primitive? car:)) = lisp trueValue.	
	self assert: (lisp top: #(eq? car car:)) = lisp trueValue.
	self assert: (lisp top: #(procedure? car)) = lisp trueValue.	
	self assert: (lisp top: #(procedure? car:)) = lisp trueValue.	
	self assert: (lisp top: #(documentation $'car)) isString.	


]

{ #category : #'as yet unclassified' }
ULispWithLibTest >> testPseudoSyntaxRules [

	lisp top: #(load-library $'#'pseudo-syntax-rules').

	self assert: (lisp top: #(let-syntax ((either (syntax-rules ()
                      								 ((either x y) (with ((tmp (gensym)))
                                       								(let ((tmp x))
                                        								 	(if tmp tmp y)))))))
 								 (either 'this' 'that'))) = 'this'.

	self assert: (lisp top: #(let-syntax ((either (syntax-rules ()
                      								 ((either x y) (with ((tmp (gensym)))
                                       								(let ((tmp x))
                                        								 	(if tmp tmp y)))))))
 								 (either false 'that'))) = 'that'.
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testQuasiquote2 [

	lisp top: #(define x 10).
	self assert: (lisp top: #(begin `(,x 5))) = #(10 5) asCons.
	self assert: (lisp top: #(begin `(let ((x ,(- x 8))) (begin `(,x 5))))) 
					= #(let ((x 2)) (begin (quasiquote ((unquote x) 5)))) asCons.

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testR4RS [

	"use R4RS compliance tests from file r4rstest.scm in SCM version 5e2
	http://www.swiss.ai.mit.edu/~jaffer/SCM.html"

	lisp ignoreCase.

	lisp top: #(load (system-path 'ulisp/tests/r4rstest.scm')).
	lisp top: #(test-cont).
	lisp top: #(test-sc4).
	lisp top: #(test-delay).

	self assert: (lisp top: #errs) isNil


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testSLIB [

	"http://swiss.csail.mit.edu/~jaffer/SLIB.html"
	
	"this somewhat tests version 3b1 "

	lisp top: #(require $'factor).

	self assert: (lisp top: #(factor 565)) = #(113 5) asCons
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testSchelog [

	lisp top: #(load-library $'schelog).
	lisp top: #(load (system-path 'ulisp/schelog/examples/bible.scm')).
	self assert: (lisp top: #(terachs-kids-test)) asOneLispValue arrayForm 
			= #((cc (haran nachor abraham))).
	self assert: (lisp top: #(#'terachs-kids-test-2')) asOneLispValue arrayForm 
			= #((kk (abraham nachor haran))).



]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testScope06 [

	lisp top: #(begin
					(define z 1) 
					(define (foo) z)
					(define (baz)
						(let ((z 2)) 
							(foo)))).

	self assert: (lisp top: #(baz)) = 1



]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testScope11 [

	lisp top: #(define (baz)
					(let ((x 1)) 
						(lambda ()
							(set! x (+ x 1))))).

	lisp top: #(begin 
					(define x1 (baz))
					(define x2 (baz))).

	self assert: (lisp top: #(apply x1 $'())) = 2.
	self assert: (lisp top: #(apply x1 $'())) = 3.
	self assert: (lisp top: #(apply x1 $'())) = 4.
	self assert: (lisp top: #(apply x2 $'())) = 2.


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testScope12 [

	lisp top: #(begin 
					(define (up-n-down)
					(let ((x 0))
						(list
							(lambda () (set! x (+ x 1)))
							(lambda () (set! x (- x 1))))))
					(define f1 (up-n-down)) 
					(define f2 (up-n-down))). 

	self assert: (lisp top: #(apply (first f1) $'())) = 1.
	self assert: (lisp top: #(apply (first f1) $'())) = 2.
	self assert: (lisp top: #(apply (first f1) $'())) = 3.
	self assert: (lisp top: #(apply (second f1) $'())) = 2.
	self assert: (lisp top: #(apply (first f2) $'())) = 1.
	self assert: (lisp top: #(apply (first f2) $'())) = 2.
	self assert: (lisp top: #(apply (first f2) $'())) = 3.
	self assert: (lisp top: #(apply (second f2) $'())) = 2.


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testScope13 [

	lisp top: #(begin 
					(define (up-n-down)
					(let ((x 0))
						(list
							(lambda () (set! x (+ x 1)))
							(let ((y 2))
								(lambda () (set! x (- x 1)))))))
					(define f1 (up-n-down)) 
					(define f2 (up-n-down))). 

	self assert: (lisp top: #(apply (first f1) $'())) = 1.
	self assert: (lisp top: #(apply (first f1) $'())) = 2.
	self assert: (lisp top: #(apply (first f1) $'())) = 3.
	self assert: (lisp top: #(apply (second f1) $'())) = 2.
	self assert: (lisp top: #(apply (first f2) $'())) = 1.
	self assert: (lisp top: #(apply (first f2) $'())) = 2.
	self assert: (lisp top: #(apply (first f2) $'())) = 3.
	self assert: (lisp top: #(apply (second f2) $'())) = 2.
						
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testSetcar [

	lisp top: #(define animals $'(antelope giraffe lion tiger)).
	lisp top: #(set-car! animals $'hippopotamus).
	self assert: (lisp top: #(car animals)) = #hippopotamus.
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testSetcdr [

	self assert: (lisp top: #(begin (define animals $'(antelope giraffe lion tiger))
					(set-cdr! animals $'(cat dog))
					(list-ref animals 2))) = #dog.

	lisp top: #(define animals $'(antelope giraffe lion tiger)).
	lisp top: #(set-cdr! animals $'(cat dog)).
	self assert: (lisp top: #(list-ref animals 2)) = #dog.

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testStringReader6 [

	lisp evalString: '(define x ''#0=(1 2 . #0#))'.	
	self assert: (lisp top: #(caddr x)) = 1 .
	self assert: (lisp top: #(list-ref x 15)) = 2 .

	lisp evalString: '(define y ''(1 2 #1=#(3 4) . #1#))' .
	self assert: (lisp top: #(eq? (caddr y) (cdddr y))) = lisp trueValue .


]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testSymbols [

	self assert: (lisp top: #(eq? (#'string->uninterned-symbol' 'uh') (#'string->uninterned-symbol' 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(eq? (#'string->symbol' 'uh') (#'string->symbol' 'uh') )) == lisp trueValue.

	self assert: (lisp top: #(eq? (#'string->uninterned-symbol' 'uh') (#'string->symbol' 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(let ((s (#'string->uninterned-symbol' 'uh')) (uh 20)) 
									(eval `(define ,s 10))
									(list (eval s) uh))) = #(10 20) asCons
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testTailCallOptimization2 [

	lisp top: #(define incx false).
	lisp top: #(define getx false).
	lisp top: #(let ((x 0)) 
					(set! incx (lambda () (set! x (+ x 1)))) 
					(set! getx (lambda () x))).

	lisp top: #(define (test n) 
					(if (< n 500) 
						(let ((u (getx))) 
							(incx) 
							(test (+ u n 1)))
						(list (getx) n))).

	self assert: (lisp top: #(test 0)) = #(32 528) asCons

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testTinyClos [

	"http://community.schemewiki.org/?Tiny-CLOS"

	lisp top: #(load-library $'tiny-clos).
	lisp top: #(begin

(define initialize-slots
    (lambda (object initargs)
      (let ((not-there (list $'shes-not-there)))
	(for-each (lambda (slot)
		    (let ((name (car slot)))
		      (let ((value  (getl initargs name not-there)))
			(if (#'eq?' value not-there)
			    $'do-nothing
			    (#'slot-set!' object name value)))))
		  (class-slots (class-of object))))))

(define #'<pos>' (make #'<class>'                         
		    $'direct-supers (list #'<object>')  
		    $'direct-slots  (list $'x $'y)))   

(add-method initialize
    (make-method (list #'<pos>')
      (lambda (call-next-method pos initargs)
	(call-next-method)
	(initialize-slots pos initargs))))

(define p1 (make #'<pos>' $'x 1 $'y 2))
(define p2 (make #'<pos>' $'x 3 $'y 5))

).

	self assert: (lisp top: #(slot-ref p1 $'x)) = 1.
	self assert: (lisp top: #(slot-ref p2 $'y)) = 5.

]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testValues [

	lisp top: 
#(define split
  (lambda (ls)
    (if (or (null? ls) (null? (cdr ls)))
        (values ls ())
        (call-with-values
          (lambda () (split (cddr ls)))
          (lambda (odds evens)
            (values (cons (car ls) odds)
                    (cons (cadr ls) evens))))))) .

	self assert: (lisp top: #(split $'(a b c d e f))) 
		= (LKValues with: #(a c e) asCons with: #(b d f) asCons)
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testValues3 [

	self assert: (lisp top: #(call-with-values
  									(lambda () (call/cc (lambda (k) (k 2 3))))
 									(lambda (x y) (list x y)))) = #(2 3) asCons
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testVectors [

	lisp top: #(define v (make-vector 3 $'Z)).
	self assert: (lisp top: #v) = #(Z Z Z).
	self assert: (lisp top: #(vector? v)) = lisp trueValue.
	self assert: (lisp top: #(equal? (vector `Z `Z `Z) v)) = lisp trueValue.
	self assert: (lisp top: #(eq? (vector `Z `Z `Z) v)) = lisp falseValue.
	self assert: (lisp top: #(vconcat v v)) = #(Z Z Z Z Z Z).

	lisp top: #(define ev (vector 1 2 (vector 3))).
	self assert: (lisp top: #(equal? (#'list->vector' (#'vector->list' ev)) ev)) = lisp trueValue 
]

{ #category : #'changes from kernel' }
ULispWithLibTest >> testWhile [

	lisp top: #(begin 
					(define i 5)
					(while (> i 0) (set! i (- i 1)))).

	self assert: (lisp top: #i) = 0
]
