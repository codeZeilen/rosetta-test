"
All tests for ULisp that do not require loading the default libraries
"
Class {
	#name : #ULispTest,
	#superclass : #StaticLispTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
ULispTest >> setUp [

	lisp := ULisp new
]

{ #category : #'changes from kernel' }
ULispTest >> testAnd [

	self assert: (lisp top: #(and true 4 (* 10 45))) = 450.
	self assert: (lisp top: #(and true nil (* 10 45))) = 450.
	self assert: (lisp top: #(and true (* 10 45) nil)) isNil.
	self assert: (lisp top: #(and true false (* 10 45))) = lisp falseValue.
 	self assert: (lisp top: #(and () false (* 10 45))) = lisp falseValue.

]

{ #category : #'changes from kernel' }
ULispTest >> testApply [

	self assert: (lisp top: #(apply + 1 (list: 7))) = 8.
	self assert: (lisp top: #(apply + 1 2 (list:))) = 3.
	self assert: (lisp top: #(apply (lambda (x y) (* x y)) 1 $'(7))) = 7.
	self assert: (lisp top: #(apply + 1 10 (list: 7 10 10))) = 38.
	self assert: (lisp top: #(apply + (list: 7 10 10))) = 27.

	self assert: (lisp top: #(apply > (list (+ 1 3) 2))) = lisp trueValue.
	self assert: (lisp top: #(apply car $'((list (+ 1 1) 2)))) = #list.

	self should: [lisp top: #(apply $'+ 1 (list: 7))] raise: LispError.
	self should: [lisp top: #(apply $'(lambda (x y) (* x y)) 1 $'(7))] raise: LispError.


]

{ #category : #'changes from kernel' }
ULispTest >> testAtom [

	
]

{ #category : #'changes from kernel' }
ULispTest >> testCatch [

	"no catch"
]

{ #category : #'changes from kernel' }
ULispTest >> testCatch2 [

	"no catch"
]

{ #category : #'changes from kernel' }
ULispTest >> testCatch3 [

	"no catch"
]

{ #category : #reader }
ULispTest >> testComplex [

	self assert: (lisp evalString: '(* #c(1 2) #C(2 3))') = (-4 + 7 i).
	self assert: (lisp evalString: '(* 2+3i 1+2i)') = (-4 + 7 i).
	self assert: (lisp evalString: '-i') = -1 i.
	self assert: (lisp evalString: '+i') = 1 i.
	self assert: (lisp evalString: '-2i') = -2 i.
	self assert: (lisp evalString: '+2i') = 2 i.
	self assert: (lisp evalString: '-1/3i') = (-1/3) i.
	self assert: (lisp evalString: '+1/3i') = (1/3) i.	
	self assert: (lisp evalString: '-2e3i') = -2000.0 i.
	self assert: (lisp evalString: '+2e3i') = 2000.0 i.
	self assert: (lisp evalString: '-2e-1i') = -0.2 i.
	self assert: (lisp evalString: '+2e-1i') = 0.2 i.
	
	self assert: (lisp evalString: '(prin1-to-string #c(-1 1.5))') = '-1+1.5i'.

	self assert: (lisp evalString: '2+3i') = (2 + 3 i).
	self assert: (lisp evalString: '2/3+3i') = ((2/3) + 3 i).
	self assert: (lisp evalString: '2+3/2i') = (2 + (3/2) i).	
	self assert: (lisp evalString: '2/3-3i') = ((2/3) - 3 i).
	self assert: (lisp evalString: '2-3/2i') = (2 - (3/2) i).		
	self assert: (lisp evalString: '-2/3+3i') = ((-2/3) + 3 i).
	self assert: (lisp evalString: '-2+3/2i') = (-2 + (3/2) i).	
	self assert: (lisp evalString: '-2/3-3i') = ((-2/3) - 3 i).
	self assert: (lisp evalString: '-2-3/2i') = (-2 - (3/2) i).						
	self assert: (lisp evalString: '1/2+1/3i') = ((1/2) + (1/3) i).	
	self assert: (lisp evalString: '1/2-1/3i') = ((1/2) - (1/3) i).
	self assert: (lisp evalString: '-1/3i') = (-1/3) i.	
	self assert: (lisp evalString: '(+ 1/3 1/4 -1/5 -1/3i 405/50+2/3i)') = ((509/60) + (1/3) i).



]

{ #category : #reader }
ULispTest >> testComplex2 [

	self assert: (lisp evalString: '1+2e4i') = (1 + 20000.0 i).
	self assert: (lisp evalString: '2e4+i') = (20000.0 + 1 i).
	self assert: (lisp evalString: '1-2e4i') = (1 - 20000.0 i).
	self assert: (lisp evalString: '2e4-i') = (20000.0 - 1 i).
	
	self assert: (lisp evalString: '1+2e-4i') = (1 + 0.0002 i).
	self assert: (lisp evalString: '2e-4+i') = (0.0002 + 1 i).
	self assert: (lisp evalString: '1-2e-4i') = (1 - 0.0002 i).
	self assert: (lisp evalString: '2e-4-i') = (0.0002 - 1 i).
		
	self assert: (lisp evalString: '2e4+5/6i') = (20000.0 + (5/6) i).
	self assert: (lisp evalString: '1/3+2e4i') = ((1/3) + 20000.0 i).
]

{ #category : #reader }
ULispTest >> testComplex3 [

	self should: [lisp evalString: '3i'] raise: LispError.
	self should: [lisp evalString: '4/8i'] raise: LispError.
	self should: [lisp evalString: '2e4i'] raise: LispError.	
	self should: [lisp evalString: '2e-4i'] raise: LispError.	

]

{ #category : #reader }
ULispTest >> testComplex4 [

	self assert: (lisp evalString: '4.0+5/8i') = (4.0 + (5/8) i).
	self assert: (lisp evalString: '4.0+5/8i') real isFloat.
	
	self assert: (lisp evalString: '4.0+5i') = (4.0 + 5 i).
	self assert: (lisp evalString: '4.0+5i') imaginary isInteger.
	
	self assert: (lisp evalString: '2.0e10+9i') = (2.0e10 + 9i).
	self assert: (lisp evalString: '2.0e10+9i') imaginary isInteger.
	
	self assert: (lisp evalString: '2.0e10+9.0i') = (2.0e10 + 9i).
	self assert: (lisp evalString: '2.0e10+9.0i') imaginary isFloat.
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testCond [

	"done in ULispWithLibTest (requires libraries)"
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testDefcascade [
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testDefselectors [
]

{ #category : #'changes from kernel' }
ULispTest >> testDefun [

	"no defun. use define"
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testEq [
]

{ #category : #'changes from kernel' }
ULispTest >> testEqual [

	self assert: (lisp top: #(equal? 5 5)) = lisp trueValue.
	self assert: (lisp top: #(equal? 5 (+ 3 2))) = lisp trueValue.
	self assert: (lisp top: #(equal? (list 1 2) (list 1 2))) = lisp trueValue.

	self assert: (lisp top: #(equal? 5 10)) = lisp falseValue.
]

{ #category : #'as yet unclassified' }
ULispTest >> testForEach [

	lisp top: #(define x 0).
	lisp top: #(for-each (lambda (n) (set! x (+ x n))) $'(1 2 3)).
	self assert: (lisp top: #x) = 6
]

{ #category : #'changes from kernel' }
ULispTest >> testFuncall [

	
]

{ #category : #'changes from kernel' }
ULispTest >> testFunctionApplication [

 	self assert: (lisp top: #((identity identity) 12)) = 12.
 	self assert: (lisp top: #(((identity identity) identity) 12)) = 12.

	self assert: (lisp top: #((if (odd? 3) + -) 6 2)) = 8.

	self assert: (lisp top: #(let ((f (lambda (x) (+ x x))))
  									(f 8))) = 16
]

{ #category : #'changes from kernel' }
ULispTest >> testIf [

	self assert: (lisp top: #(if true 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if nil 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if false 4 (* 10 45))) = 450.
	self assert: (lisp top: #(if #() 4 (* 10 45))) = 4.

	self assert: (lisp top: #(if $'ok 4 (/ 1 0))) = 4.

]

{ #category : #'changes from kernel' }
ULispTest >> testLet [

	lisp top: #(define y 2).
	self assert: (lisp top: #(let ((y 1) (z y)) (list y z))) arrayForm = #(1 2).
	self assert: (lisp top: #y) = 2
]

{ #category : #'as yet unclassified' }
ULispTest >> testLetRec [

	lisp top: #(define (test1)
   					((let ((to-zero (lambda (n) (if (equal? 1 n) 0 (to-zero (- n 1))))))
      					to-zero) 10)).

	self should: [lisp top: #(test1)] raise: LispError.

	lisp top: #(define (test2)
   					((letrec ((to-zero (lambda (n) (if (equal? 1 n) 0 (to-zero (- n 1))))))
      					to-zero) 10)).

	self assert: (lisp top: #(test2)) = 0.


]

{ #category : #'changes from kernel' }
ULispTest >> testLetStar [

	lisp top: #(define y 2).
	self assert: (lisp top: #(let* ((y 1) (z y)) (list y z))) arrayForm = #(1 1).
	self assert: (lisp top: #y) = 2

]

{ #category : #'changes from kernel' }
ULispTest >> testMacro [

	
]

{ #category : #'as yet unclassified' }
ULispTest >> testMap [

	self assert: (lisp top: #(map + $'(1 2 3) $'(3 2 1))) = #( 4 4 4) asCons.
	self assert: (lisp top: #(map car $'((:un deux)))) = #(:un) asCons.
]

{ #category : #'changes from kernel' }
ULispTest >> testOr [

	self assert: (lisp top: #(or true 4 (* 10 45))) = lisp trueValue.
	self assert: (lisp top: #(or false true #f (* 10 45))) = true.
	self assert: (lisp top: #(or () nil)) isNil.
	self assert: (lisp top: #(or (not $'f) false)) = lisp falseValue..

]

{ #category : #'changes from kernel' }
ULispTest >> testPitFalls [

	"letrec tests"

	"see http://sisc-scheme.org/r5rs:=pitfall.scm"

	self assert: (lisp top: # 
(let ((cont false))
   (letrec ((x (call-with-current-continuation (lambda (c) (set! cont c) 0)))
            (y (call-with-current-continuation (lambda (c) (set! cont c) 0))))
     (if cont
         (let ((c cont))
           (set! cont false)
           (set! x 1)
           (set! y 1)
           (c 0))
         (+ x y))))) = 0.

	lisp top: #(define call/cc call-with-current-continuation).
	lisp top: #(define pair? consP:).

	self assert: (lisp top: # 
  (letrec ((x (call/cc list)) (y (call/cc list)))
    (cond ((procedure? x) (x (pair? y)))
	  ((procedure? y) (y (pair? x))))
    (let ((x (car x)) (y (car y)))
      (and (call/cc x) (call/cc y) (call/cc x))))) = true.

	lisp top: #(define eq? eq:).

	self assert: (lisp top: # 
  (letrec ((x (call-with-current-continuation
		  (lambda (c)
		    (list true c)))))
      (if (car x)
	  ((cadr x) (list false (lambda () x)))
	  (eq? x ((cadr x)))))) = true

]

{ #category : #'changes from kernel' }
ULispTest >> testPitFalls2 [

	"call/cc test"

	"see http://sisc-scheme.org/r5rs:=pitfall.scm"

	self assert: (lisp top: #
		(call-with-current-continuation (lambda (c) (0 (c 1))))) = 1.

]

{ #category : #'changes from kernel' }
ULispTest >> testPitFalls3 [

	"no identifiers are reserved"

	"see http://sisc-scheme.org/r5rs:=pitfall.scm"

	self assert: (lisp top: #
		((lambda lambda lambda) `x)) = #(x) asCons.

	self assert: (lisp top: #
		((lambda (begin) (begin 1 2 3)) (lambda lambda lambda))) 
			= #(1 2 3) asCons.

	self assert: (lisp top: #
		(let ((quote -)) (eqv? $'1 1))) = false.
	self assert: (lisp top: #
		(let ((quote -)) (eqv? (quote 1) 1))) = false.


]

{ #category : #'changes from kernel' }
ULispTest >> testPitFalls4 [

	"see http://sisc-scheme.org/r5rs:=pitfall.scm"

	self assert: (lisp top: #
		(let ((ls (list 1 2 3 4)))
    			(append ls ls `(5)))) = #(1 2 3 4 1 2 3 4 5) asCons.

	lisp loadDefaultLibraries. "needed for named let"

	self assert: (lisp top: #(let - ((n (- 1))) n)) = -1.


]

{ #category : #'changes from kernel' }
ULispTest >> testPitFalls5 [

	"see http://sisc-scheme.org/r5rs:=pitfall.scm"

	lisp top: #(define r false).
	lisp top: #(define a false).
	lisp top: #(define b false).
	lisp top: #(define c false).
	lisp top: #(define i 0).

	self assert: (lisp top: #
  (let () 
    (set! r (+ 1 (+ 2 (+ 3 (call-with-current-continuation (lambda (k) (set! a k) 4))))
               (+ 5 (+ 6 (call-with-current-continuation (lambda (k) (set! b k) 7))))))
    (if (not c) 
        (set! c a))
    (set! i (+ i 1))
    (case i
      ((1) (a 5))
      ((2) (b 8))
      ((3) (a 6))
      ((4) (c 4)))
    r)) = 28.

	lisp top: #(define r false).
	lisp top: #(define a false).
	lisp top: #(define b false).
	lisp top: #(define c false).
	lisp top: #(define i 0).

	self assert: (lisp top: #
  (let () 
    (set! r (+ 1 (+ 2 (+ 3 (call-with-current-continuation (lambda (k) (set! a k) 4))))
               (+ 5 (+ 6 (call-with-current-continuation (lambda (k) (set! b k) 7))))))
    (if (not c) 
        (set! c a))
    (set! i (+ i 1))
    (case i
      ((1) (b 8))
      ((2) (a 5))
      ((3) (b 7))
      ((4) (c 4)))
    r)) = 28.

]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testPrimitivesRepresentation [

	"done in ULispWithLibTest (requires libraries)"
]

{ #category : #fun }
ULispTest >> testPuttingSchemeToWork [

	"Putting Scheme to Work, by Olivier Danvy"
	
	lisp top: #

(define fix
 (let ((z (lambda (P)
             (lambda (u)
               (lambda (t)
                 (lambda (t)
                   (lambda (i)
                     (lambda (n)
                       (lambda (g)
                         (lambda (S)
                           (lambda (c)
                             (lambda (h)
                               (lambda (e)
                                 (lambda (m)
                                   (lambda (e)
                                     (lambda (t)
                                       (lambda (o)
                                         (lambda (W)
                                           (lambda (o)
                                             (lambda (r)
                                               (lambda (k)
                                                 (lambda (!)
                                                   (! (lambda (break)
							(((((((((((((((((((((W o) r) k)
									  W) o) r) k)
								      W) o) r) k)
								  W) o) r) k)
							      W) o) r) k) !)
							 break)))))))))))))))))))))))))
    (let ((Z z))
      (((((((((((((((((((z z) z) z) z) z) Z) Z) Z) Z) Z) Z) Z) z) z) z) z) z) z) z)))).

	self assert: (lisp top: #

	((fix (lambda (f)
        (lambda (n)
          (if (zero? n)
              1
              (* n (f (- n 1))))))) 9) 

	) = 362880
]

{ #category : #'changes from kernel' }
ULispTest >> testScope [

	self assert: (lisp top: #(let (func)
						(let ((x 10))
							(set! func (lambda (y) (+ x y))))
						(apply func $'(5)))) = 15


]

{ #category : #'changes from kernel' }
ULispTest >> testScope01 [

	self assert:
	(
		lisp top: #(let (func)
						(let ((x 10))
							(set! func (lambda (y) (+ x y))))
						(apply func $'(5)))
	) = 15.


]

{ #category : #'changes from kernel' }
ULispTest >> testScope02 [

	
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testScope12 [
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testScope13 [
]

{ #category : #'changes from kernel' }
ULispTest >> testScope15 [

	lisp top: #	(let ((x 10)) (define beuh 18)). 

	self should: [lisp top: #(begin beuh)] raise: Error
		
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testSetcar [
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testSetcdr [
]

{ #category : #'changes from kernel' }
ULispTest >> testSetq [

	"use set!"
]

{ #category : #'changes from kernel' }
ULispTest >> testStringEscapes [

	self assert: ((lisp top: {#'string->list' . {#'list->string' . $' . {$a . Character lf . $b}}}) printString = '(#\a #\newline #\b)').
	self assert: ((lisp top: {#'string->list' . {#'list->string' . $' . {$a . Character tab . $b}}}) printString = '(#\a #\tab #\b)').

	self assert: ((lisp top: #(eval (read '(prin1-to-string #\newline)'))) = '#\newline').





]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testStringReader6 [

	"done in ULispWithLibTest (requires libraries)"
]

{ #category : #'changes from kernel' }
ULispTest >> testStringReader7 [

	self assert: (lisp evalString: '(cadr (quote (1 nil)))') == #nil


]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testSymbols [

	"done in ULispWithLibTest (requires libraries)"
]

{ #category : #'as yet unclassified' }
ULispTest >> testTailCallOptimization [

	lisp top: #(defun test (n) (if (< n 5000) (test (+ n 1)) n)).
	self assert: (lisp top: #(test 0)) = 5000

]

{ #category : #'as yet unclassified' }
ULispTest >> testTopLevel [

	"see
	http://lists.racket-lang.org/users/archive/2010-August/041139.html"

	lisp evalString: '(define stop
     		(let ((k (call-with-current-continuation (lambda (k) k))))
       		(lambda ()
         			(display "stop?\n")
         			(k k))))'.

	self assert: (lisp evalString: '(begin (stop) (stop) 42)') = 42.
	self assert: lisp outputStream contents asString = ('stop?', String lf, 'stop?', String lf).
	
	lisp outputStream reset.
	self assert: (lisp evalString: '((lambda () (stop) (stop) 42))') = #stop.
	self assert: lisp outputStream contents asString = ('stop?', String lf).

]

{ #category : #'changes from kernel' }
ULispTest >> testUnwindProtect [

	
]

{ #category : #'changes from kernel' }
ULispTest >> testValues2 [

	self assert: (lisp top: #(call-with-values
  								(lambda () (values $'bond $'james))
  								(lambda (x y) (cons y x))))
		asString = '(james . bond)' 
]

{ #category : #'done in ULispWithLibTest' }
ULispTest >> testVectors [

	"done in ULispWithLibTest (requires libraries)"
]

{ #category : #'as yet unclassified' }
ULispTest >> testY [

	"from 'the Why of Y' by Richard P. Gabriel"
	
	lisp top: #(define y (lambda (f)
					(let ((g (lambda (h)
								(lambda (x) ((f (h h)) x)))))
					(g g)))).

	self assert: (lisp top: #(let ((f (y (lambda (h)
											(lambda (n)
												(if (< n 2) 1 (* n (h (- n 1)))))))))
									(f 10))) = 3628800
]
