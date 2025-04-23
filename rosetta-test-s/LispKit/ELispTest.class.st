"
This is the unit test for the class LispKernel. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #ELispTest,
	#superclass : #TestCase,
	#instVars : [
		'lisp'
	],
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
ELispTest >> defaultTimeout [

	^ 20
]

{ #category : #'as yet unclassified' }
ELispTest >> setUp [

 	lisp := ELisp new

]

{ #category : #'as yet unclassified' }
ELispTest >> testAnd [

	self assert: (lisp top: #(and true 4 (* 10 45))) = 450.
	self assert: (lisp top: #(and true nil (* 10 45))) isNil.
	self assert: (lisp top: #(and () nil (* 10 45))) isNil.

]

{ #category : #'as yet unclassified' }
ELispTest >> testAppend [

	(lisp top: #(setq uh $'(1 2))).
	self assert: (lisp top: #(eq: uh (append uh))) = lisp trueValue.
	self assert: (lisp top: #(eq: uh (append uh ()))) = lisp falseValue.

	(lisp top: #(setq oh $'(3 4))).
	self assert: (lisp top: #(append 5)) = 5.
	self assert: (lisp top: #(append uh oh)) = #(1 2 3 4) asCons.
	self assert: (lisp top: #uh) = #(1 2) asCons.
	self assert: (lisp top: #oh) = #(3 4) asCons.

	self assert: (lisp top: #(append uh oh oh oh)) = #(1 2 3 4 3 4 3 4) asCons.
	self assert: (lisp top: #uh) = #(1 2) asCons.
	self assert: (lisp top: #oh) = #(3 4) asCons.
]

{ #category : #'as yet unclassified' }
ELispTest >> testAppend2 [

	(lisp top: #(progn 
					(setq un $'(1 2))
					(setq trois $'(3 4))
					(setq ap (append un trois)))).

	self assert: (lisp top: #(eq: (cddr ap) trois))= lisp trueValue.

]

{ #category : #'as yet unclassified' }
ELispTest >> testApply [

	self assert: (lisp top: #(apply $'+ 1 (list: 7))) = 8.
	self assert: (lisp top: #(apply $'+ 1 2 (list:))) = 3.
	self assert: (lisp top: #(apply $'(lambda (x y) (* x y)) 1 $'(7))) = 7.
	self assert: (lisp top: #(apply $'+ 1 10 (list: 7 10 10))) = 38.
	self assert: (lisp top: #(apply $'+ (list: 7 10 10))) = 27.

	self assert: (lisp top: #(apply $'> (list (+ 1 3) 2))) = lisp trueValue.
	self assert: (lisp top: #(apply $'car $'((list (+ 1 1) 2)))) = #list.

]

{ #category : #'as yet unclassified' }
ELispTest >> testArithmetic [

	self assert: (lisp top: 45) = 45.
	self assert: (lisp top: #(+)) = 0.
	self assert: (lisp top: #(+ 4)) = 4.
	self assert: (lisp top: #(+ 4 (+ 10 45))) = 59.
	self assert: (lisp top: #(+ 4 (* 10 45))) = 454

]

{ #category : #'as yet unclassified' }
ELispTest >> testArray [

	self assert: ((lisp evalString: '#(1 2 3 4)') printStringForLisp: lisp) = '#(1 2 3 4)'.
	self assert: ((lisp evalString: '#(1 2 (3 4))') printStringForLisp: lisp) = '#(1 2 (3 4))'.
	self assert: ((lisp evalString: '#(1 2 #(3 4))') printStringForLisp: lisp) = '#(1 2 #(3 4))'.

]

{ #category : #'as yet unclassified' }
ELispTest >> testAtom [

	self assert: (lisp top: #(atom 5)) = lisp trueValue.
	self assert: (lisp top: #(atom (+ 3 2))) =  lisp trueValue.
	self assert: (lisp top: #(atom 'bouh')) = lisp trueValue.
	self assert: (lisp top: #(atom $k)) =  lisp trueValue.
	self assert: (lisp top: #(atom (list 1 2) (list 1 2))) =  lisp falseValue.
]

{ #category : #fun }
ELispTest >> testAutoModifyingFunction [

	"
	here is a function modifying its own source code while it is running !
	(note that this example works because dotimes is not a macro)
	"

	lisp loadDefaultLibraries.

	lisp top: #(defun counter (n &optional counts)
	(dotimes (i n counts)
		(add-to-list $'counts 0 "<--- the (0) cell is being dynamically changed")
		(let ((cell (cddadr (cdaddr (symbol-function $'counter)))))
 			(setcar cell (+ 1 (car cell)))))).

	self assert: (lisp top: #(counter 4)) = #(0 1 2 3) asCons.
	self assert: (lisp top: #(counter 4)) = #(4 5 6 7) asCons.
	self assert: (lisp top: #(counter 2)) = #(8 9) asCons.


	"
	the following example use a macro (loop) so the modification is only taken into account during the next expansion, that is the next function invocation
	"

	lisp top: #(defun counter (n)
	(let ((cell (nthcdr 10 (cadr (cdaddr (symbol-function $'counter))))))
		(loop for i from 1 to n
			do (setcar cell (+ 1 (car cell))) 
			collect 0 "<--- the (0) cell is being dynamically changed"))).

	self assert: (lisp top: #(counter 4)) = #(0 0 0 0) asCons.
	self assert: (lisp top: #(counter 4)) = #(4 4 4 4) asCons.
	self assert: (lisp top: #(counter 2)) = #(8 8) asCons.

	"
	credit:
	idea borrowed from the incMe example in the PicoLisp FAQ: 
	http://software-lab.de/faq.html
	"

]

{ #category : #'as yet unclassified' }
ELispTest >> testCatch [

	lisp top: #(defun outer-foo (x) (catch $'foo (inner-foo x))).
	lisp top: #(defun inner-foo (x) (if (equal x 10) (throw $'foo 'bouh') (+ 10 x)) 'the end').

	self assert: (lisp top: #(outer-foo 8)) = 'the end'.
	self assert: (lisp top: #(outer-foo 10)) = 'bouh'.



]

{ #category : #'as yet unclassified' }
ELispTest >> testCatch2 [

	lisp top: #(defun fun1 (x)  (catch $'trap (+ 3 (fun2 x)))).
	lisp top: #(defun fun2 (y)  (catch $'trap (* 5 (fun3 y)))). 
	lisp top: #(defun fun3 (z) (throw $'trap z)).

	self assert: (lisp top: #(fun1 7)) = 10.



]

{ #category : #'as yet unclassified' }
ELispTest >> testCatch3 [

	lisp top: #(defun fun1 (x)  (catch $'trap (+ 3 (fun2 x)))).
	lisp top: #(defun fun2 (y)  (catch $'snare (* 5 (fun3 y)))). 
	lisp top: #(defun fun3 (z) (throw $'trap z)).

	self assert: (lisp top: #(fun1 7)) = 7.



]

{ #category : #'as yet unclassified' }
ELispTest >> testCharacters [

	self assert: (lisp evalString: '#\tab') == Character tab.
	self assert: (lisp evalString: '#\return') == Character cr.
	self assert: (lisp evalString: '#\newline') == Character linefeed.
	self assert: (lisp evalString: '#\n') == $n.
	self assert: (lisp evalString: '(prin1-to-string #\newline)') = '#\newline'
]

{ #category : #'as yet unclassified' }
ELispTest >> testComplex [

	self assert: (lisp evalString: '(* #c(1 2) #C(2 3))') = (-4 + 7 i).
	self assert: (lisp evalString: '(prin1-to-string #c(-1 1.5))') = '#C(-1 1.5)'

]

{ #category : #'as yet unclassified' }
ELispTest >> testCond [

	self assert: (lisp top: #(cond 
								((listp (+ 1 1)) $'bah)
								((listp $'(+ 1 1)) 'one' 'two' $'yo)
								((listp 5) $'yep))) = #yo.

	self assert: (lisp top: #(cond 
								((listp (+ 1 1)) $'bah)
								((listp 5) $'yo))) = lisp falseValue.

	self assert: (lisp top: #(cond ((+ 1 1)))) = 2


]

{ #category : #'as yet unclassified' }
ELispTest >> testCons [

	self assert: (lisp top: #(progn (list 1 2 3))) arrayForm = #(1 2 3).
	self assert: (lisp top: #(progn (list 1 2 3) (* 10 2))) = 20.

	self assert: (lisp top: #(cons 5 4)) printString = '(5 . 4)'.
	self should: [(lisp top: #(cons 5 4)) arrayForm] raise: Error.
	self assert: (lisp top: #(cons 5 nil)) arrayForm = #(5).

	self assert: (lisp top: #(car (list 4 5))) = 4.
	self assert: (lisp top: #(cdr (list 4 5))) arrayForm = #(5).
	self assert: (lisp top: #(cdr (cons 5 4))) = 4
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefcascade [

	lisp loadDefaultLibraries.
	self assert: (lisp top: 
		#(send-cascade $'((at:put: 2 $a) (copyFrom:to: 1 2)) 'hello')) = 'ha'.

	lisp top: #(defcascade yo ((at:put: 2 $a) (copyFrom:to: 1 2))).

	self assert: (lisp top: #(yo 'mimi')) = 'ma'

]

{ #category : #'as yet unclassified' }
ELispTest >> testDefconstant [

	lisp top: #(defconstant x 'beuh').
	self should: [lisp top: #(let ((x 10)) x)] raise: LispError.
	self should: [lisp top: #(setq x 10)] raise: LispError.
	self should: [lisp top: #(defvar x 10)] raise: LispError.
	self assert: (lisp top: #(progn x)) = 'beuh'

]

{ #category : #'as yet unclassified' }
ELispTest >> testDefmacro [

	lisp top: #(defmacro add4 (x y z) `(+ ,x ,y ,@z)).
	self assert: (lisp top: #(add4 (+ 1 1) (+ 2 2) (10 10))) = 26
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefmacro2 [

	lisp top: #(defmacro with (sym val form)
				`(let ((,sym ,val))
					,form)).

	lisp top: #(setq bouh 18).
	self assert: (lisp top: #(with bouh 32 (+ 1 bouh))) = 33.	
	self assert: (lisp top: #bouh) = 18.
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefmacro3 [

	lisp top: #(defmacro add (x y . z) `(+ ,x ,y ,@z)).
	self assert: (lisp top: # (add 4 5 10 20)) = 39.	

	lisp top: #(defmacro add (x y &body z) `(+ ,x ,y ,@z)).
	self assert: (lisp top: # (add 4 5 10 20)) = 39.	

]

{ #category : #'as yet unclassified' }
ELispTest >> testDefselectors [

	lisp loadDefaultLibraries.
	lisp top: #(defselectors cadddr2 (cdr (nthcdr: 2) car)).
	self assert: (lisp top: #(cadddr2  $'(1 2 3 4 5 6))) = 4

]

{ #category : #'as yet unclassified' }
ELispTest >> testDefun [

	self should: [lisp top: #(plus  5 4)] raise: LispError.

	lisp top: #(defun plus (x y) (+ x y)).

	self assert: (lisp top: #(plus  5 4)) = 9.
	self assert: (lisp top: #(plus (+ 1 1) (+ 2 2))) = 6.
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefunWithKeywords [

	lisp top: #(defun test (a &optional b) (list a b)).

	self assert: (lisp top: #(test 1 2)) =  #(1 2) asCons.
	self assert: (lisp top: #(test 1) ) = #(1 nil) asCons.

	self should: [lisp top: #(test)] raise: LispError.
	self should: [lisp top: #(test 1 2 3)] raise: Error.
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefunWithKeywords2 [

	lisp top: #(defun test (a &rest b) (list a b)).

	self assert: (lisp top: #(test 1 2)) =  #(1 (2)) asCons.
	self assert: (lisp top: #(test 1 2 3) ) = #(1 (2 3)) asCons.
	self assert: (lisp top: #(test 1)) =  #(1 ()) asCons.

	self should: [lisp top: #(test)] raise: Error.
]

{ #category : #'as yet unclassified' }
ELispTest >> testDefunWithKeywords3 [

	lisp top: #(defun test (a &body b) (list a b)).
	self assert: (lisp top: #(test 1 2)) =  #(1 (2)) asCons.

	lisp top: #(defun test (a . b) (list a b)).
	self assert: (lisp top: #(test 1 2)) =  #(1 (2)) asCons.

	lisp top: #(defun test a a).  "note: this is not allowed in CLISP"
	self assert: (lisp top: #(test 1 2)) =  #(1 2) asCons.

]

{ #category : #'as yet unclassified' }
ELispTest >> testDefunWithKeywords4 [

	lisp class wantsFullArgumentsListsSupport ifFalse: [^ self].
	lisp loadDefaultLibraries.

	lisp top: #(defun beuh (a &optional b &key c d (e 17)) (list a b c d e)).

	self assert: (lisp top: #(beuh 1 2 :e 5 :c 12 :d 'a')) =  #(1 2 12 'a' 5) asCons.
	self assert: (lisp top: #(beuh 1 2) ) = #(1 2 nil nil 17) asCons.
]

{ #category : #'as yet unclassified' }
ELispTest >> testDelete [

	self assert: (lisp top: #(delq 5 $'(1 5 3 4 5 6))) = #(1 3 4 6) asCons.
	self assert: (lisp top: #(delq 5 $'(5 3 4 5 6))) = #(3 4 6) asCons.

	self assert: (lisp top: #(delete 5 $'(1 5 3 4 5 6))) = #(1 3 4 6) asCons.
	self assert: (lisp top: #(delete 5 $'(5 3 4 5 6))) = #(3 4 6) asCons.

	self assert: (lisp top: #(delq 'uh' $'(5 'uh' 4))) = #(5 'uh' 4) asCons.
	self assert: (lisp top: #(delete 'uh' $'(5 'uh' 4))) = #(5 4) asCons.

]

{ #category : #'as yet unclassified' }
ELispTest >> testDolist [

	lisp top: #(setq test nil).
	self assert: (lisp top: #(dolist (i $'(10 20 30) (+ 1 1))
									(setq test (append test (list (* i i)))))) = 2.
	self assert: (lisp top: #(progn test)) = #(100 400 900) asCons.
	self should: [lisp top: #(progn i)] raise: LispError
]

{ #category : #'as yet unclassified' }
ELispTest >> testDynamicScoping [

	lisp top: #(defun addx (y) (+ x y)).
	self assert: (lisp top: #(let ((x 10)) (addx 5))) = 15

]

{ #category : #'as yet unclassified' }
ELispTest >> testEq [

	self assert: (lisp top: #(eq 5 5)) =  lisp trueValue.
	self assert: (lisp top: #(eq 5 (+ 3 2))) =  lisp trueValue.
	self assert: (lisp top: #(eq (list 1 2) (list 1 2))) = lisp falseValue.

	(lisp top: #(setq uh $'(1 2))).
	self assert: (lisp top: #(eq: uh ` ,uh)) = lisp trueValue.
]

{ #category : #'as yet unclassified' }
ELispTest >> testEqual [

	self assert: (lisp top: #(equal 5 5)) = lisp trueValue.
	self assert: (lisp top: #(equal 5 (+ 3 2))) = lisp trueValue.
	self assert: (lisp top: #(equal (list 1 2) (list 1 2))) = lisp trueValue.

	self assert: (lisp top: #(equal 5 10)) = lisp falseValue.
]

{ #category : #'as yet unclassified' }
ELispTest >> testEval [

	lisp top: #(defun test () (eval $'(setq blep 452)) blep).
	self assert: (lisp top: #(test)) = 452.
	self assert: (lisp top: #(progn blep)) = 452.

	self should: [lisp top: #(let ((x 10)) (eval $'x))] raise: LispError.

	lisp top: #(defun test2 (n) (eval n)).
	self assert: (lisp top: #(test2 $'(+ 1 1))) = 2.
]

{ #category : #'as yet unclassified' }
ELispTest >> testFuncall [

	self assert: (lisp top: #(funcall $'+ 1 7)) = 8.
	self assert: (lisp top: #(funcall $'car (list 1 7))) = 1.
	self assert: (lisp top: #(funcall $'(lambda (x y) (* x y)) 1 7)) = 7.


]

{ #category : #'as yet unclassified' }
ELispTest >> testIf [

	self assert: (lisp top: #(if true 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if nil 4 (* 10 45))) = 450.
	self assert: (lisp top: #(if $'nil 4 (* 10 45))) = 450.
	self assert: (lisp top: #(if #() 4 (* 10 45))) = 450.

	self assert: (lisp top: #(if $'ok 4 (/ 1 0))) = 4.
	self should: [lisp top: #(if nil 4 (/ 1 0))] raise: Error
]

{ #category : #'as yet unclassified' }
ELispTest >> testLambda [

	self assert: (lisp top: #((lambda () 2))) = 2.
	self assert: (lisp top: #((lambda nil 2))) = 2.
	self assert: (lisp top: #(lambda (x y) (+ x y 2))) = #(lambda (x y) (+ x y 2)) asCons.
	self assert: (lisp top: #((lambda (x y) (+ x y 2)) 5 8)) = 15.

]

{ #category : #'as yet unclassified' }
ELispTest >> testLet [

	lisp top: #(setq y 2).
	self assert: (lisp top: #(let ((y 1) (z y)) (list y z))) arrayForm = #(1 2).
	self assert: (lisp top: #y) = 2

]

{ #category : #'as yet unclassified' }
ELispTest >> testLetStar [

	lisp top: #(setq y 2).
	self assert: (lisp top: #(let* ((y 1) (z y)) (list y z))) arrayForm = #(1 1).
	self assert: (lisp top: #y) = 2

]

{ #category : #'as yet unclassified' }
ELispTest >> testList [

	self assert: (lisp top: #(list 1 2 3)) arrayForm = #(1 2 3).
	self assert: (lisp top: #(list 1 2 (+ 4 5)))  arrayForm = #(1 2 9).
]

{ #category : #'as yet unclassified' }
ELispTest >> testLoop [

	lisp loadDefaultLibraries.
	lisp top: #(require-library $'loop).

	self assert: (lisp top: #(loop for i in $'(1 2 3)  collect i)) = #(1 2 3) asCons.
	self assert: (lisp top: #(loop for i from 1 to 4 collect i)) = #(1 2 3 4) asCons.
	self assert: (lisp top: #(loop until t finally (return 'a'))) = 'a'.

	"note: the following is allowed by CLtL2 but forbddien by ANSI CL"
	self assert: (lisp top: #(loop until t finally return 'a')) = 'a'.

]

{ #category : #'as yet unclassified' }
ELispTest >> testMacro [

	self assert: (lisp top: #((macro (x &rest y) `(+ ,x ,@y 2)) 5 4 3 1)) = 15.

]

{ #category : #'as yet unclassified' }
ELispTest >> testMultipleValue [

	self assert: (lisp top:#(values 1 2 3)) = (#(1 2 3) as: LKValues).
	self assert: (lisp top:#(values-list $'(1 2 3))) = (#(1 2 3) as: LKValues).

	self assert: (lisp top:#(+ (values 1 2 3) 1)) = 2.

	self assert: (lisp top:#(multiple-value-list (values 1 2 3))) = #(1 2 3) asCons.
	self assert: (lisp top:#(multiple-value-list 5)) = #(5) asCons.

	self assert: (lisp top:#(multiple-value-call (symbol-function $'+) (values 5 3) (values 19 4))) = 31.

	self assert: (lisp top:#(multiple-value-prog1 1 2 3)) = (#(1) as: LKValues).
	self assert: 
		(lisp top:#(multiple-value-prog1 (values 1 4) 2 3)) = (#(1 4) as: LKValues).
	self assert: (lisp top:#(prog1 (values 1 4) 2 3)) = 1.

	self assert: 
		(lisp top:#(multiple-value-bind (x) (values 5 3) (list x))) = 5 inCons.
	self assert: 
		(lisp top:#(multiple-value-bind (x y) (values 5 3) (list x y))) = #(5 3) asCons.
	self assert: 
		(lisp top:#(multiple-value-bind (x y) 5 (list x y))) = #(5 nil) asCons.
]

{ #category : #fun }
ELispTest >> testNonRecursiveFactorial [

	"just use a circular program !"

	lisp evalString: '(defun fact (n) #1=(if (< n 1) 1 (setq n (- n 1)) (* (+ 1 n) #1#)))'.

	self assert: (lisp top: #(fact 8)) = 40320
]

{ #category : #fun }
ELispTest >> testNonRecursiveFib [

	"fibonacci numbers - another circular program"

	lisp evalString: 
'(defun fib (n) 
	#1=(if (< n 2) 
			n 
			(+ (let ((n (- n 1))) #1#)
				(let ((n (- n 2))) #1#))))'.

	self assert: (lisp top: #(fib 10)) = 55
]

{ #category : #'as yet unclassified' }
ELispTest >> testOr [

	self assert: (lisp top: #(or true 4 (* 10 45))) = true.
	self assert: (lisp top: #(or nil true nil (* 10 45))) = true.
	self assert: (lisp top: #(or () nil)) isNil.

]

{ #category : #'as yet unclassified' }
ELispTest >> testPrimitivesRepresentation [

	self assert: (lisp top: #(symbol-function $'car)) printString = 'primitive car:'.
	self assert: (lisp top: #(symbol-function $'car:)) printString = 'primitive car:'.
	self assert: ((lisp top: #(primitives)) topForms includes: #car).
	self assert: ((lisp top: #(primitives)) topForms includes: #car:) not.
	self assert: (lisp top: #(primitivep $'car)) = lisp trueValue.	
	self assert: (lisp top: #(primitivep $'car:)) = lisp trueValue.	
	self assert: (lisp top: #(fboundp $'car)) = lisp trueValue.	
	self assert: (lisp top: #(fboundp $'car:)) = lisp trueValue.	
	self assert: (lisp top: #(eq (symbol-function $'car) (symbol-function $'car:))) = lisp trueValue.
	self assert: (lisp top: #(documentation $'car)) isString.	


]

{ #category : #'as yet unclassified' }
ELispTest >> testProgn [

	self assert: (lisp top: #(progn (list 1 2 3))) arrayForm = #(1 2 3).
	self assert: (lisp top: #(progn (list 1 2 3) (* 10 2))) = 20.
	self assert: (lisp top: #(progn)) isNil.
]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote1 [

	self assert: (lisp top: #(equal `(1 5 . ,(+ 2 3)) $'(1 5 . 5))) = lisp trueValue.
"	self assert: (lisp top: #(equal `(1 5 . (unquote (+ 2 3))) $'(1 5 . 5))) = lisp trueValue." "not implemented yet"


]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote2 [

	lisp top: #(setq x 10).
	self assert: (lisp top: #(progn `(,x 5))) = #(10 5) asCons.
	self assert: (lisp top: #(eval ` ,(car (list 1 2)))) = 1.
	self assert: (lisp top: #(progn `(let ((x ,(- x 8))) (progn `(,x 5))))) 
					= #(let ((x 2)) (progn (quasiquote ((unquote x) 5)))) asCons.

]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote3 [

	"example from paper 'Quasiquotation in Lisp' by Alan Bawden, attibuted to Mike MacMahon"

	| str |

	lisp top: #(setq autoeval (quote
					(let ((let $' `(let ((let $' ,let)) ,let))) `(let ((let $' ,let)) ,let))
					)).

	self assert: (lisp top: #(equal (eval autoeval) autoeval)) = lisp trueValue.

	"more striking forms:"

	str := '(let ((let (quote: (quasiquote: (let ((let (quote: (unquote let)))) (unquote let)))))) (quasiquote: (let ((let (quote: (unquote let)))) (unquote let))))'.

	self assert: ((lisp evalString: str) printStringForLisp: lisp) = str.

]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote4 [

	self assert: (lisp top: #(progn `(1 $'(2 ,(+ 1 3))))) = #(1 (quote (2 4))) asCons.
	self assert: (lisp top: #(progn `(1 `(2 ,(+ 1 3))))) = #(1 (quasiquote (2 (unquote (+ 1 3))))) asCons.



]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote5 [

	"note: GNU Emacs 21.2.1 fails to give the correct result, where CLISP 2.36 and PLT Scheme 350 do"

	self assert: (lisp top: #(progn `(list `(list 1 , $' , 2)))) 
					= #(list (quasiquote (list 1(unquote (quote 2))))) asCons.

	self assert: (lisp top: #(eval `(list `(list 1 , $' , 2)))) = #((list 1 2)) asCons

]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote6 [

	"note: both GNU Emacs 21.2.1 and CLISP 2.36 fail here, while PLT Scheme 350 answers correctly"

	self assert: (lisp top: # (eval ` `(, ,2))) 
					= #(2) asCons.

	self assert: (lisp top: # (eval ` `(, ,@(list 1 2 3 4 5)))) 
					= #(1 2 3 4 5) asCons.


]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote7 [

	self assert: (lisp top: #(quasiquote ((split) . pea))) = (#split inCons inCons cdr: #pea)
]

{ #category : #'as yet unclassified' }
ELispTest >> testQuasiquote8 [

	"MIT Scheme, PLT Scheme agree with the following, while Emacs Lisp, CLISP and SBCL return (1 unquote (+ 1 1)) :"
	self assert: (lisp top: #(quasiquote (1 unquote (+ 1 1)))) = (ConsCell car: 1 cdr: 2).

	"MIT Scheme agrees with the following, while PLT Scheme signals an error:"
	self assert: (lisp top: #(quasiquote (1 unquote (+ 1 1) 3))) = #(1 unquote (+ 1 1) 3) asCons
]

{ #category : #'to do' }
ELispTest >> testQuasiquote9 [

	self assert: (lisp evalString: ' `(,@''() . foo)') = #foo.
"
to do:
	self should: [lisp evalString: '''( . foo)'] raise: Error
"
]

{ #category : #'as yet unclassified' }
ELispTest >> testQuote [

	self assert: (lisp top: #(eval (eval (quote (list (quote +) 10 100 2))))) = 112.

]

{ #category : #'as yet unclassified' }
ELispTest >> testRewrite [

	self assert: (lisp top: #(defmacro add (x y) (quasiquote (+ (unquote x) (unquote y))))) 
				= (lisp top: #(defmacro add (x y) `(+ ,x ,y))).

	self assert: (lisp top: #(defmacro add (x y) (quasiquote (+ (unquote x) (unquote-splicing y))))) 
				= (lisp top: #(defmacro add (x y) `(+ ,x ,@y))).
]

{ #category : #'as yet unclassified' }
ELispTest >> testScope [

	"same behavior as in Emacs Lisp, while it works in Common Lisp and in Scheme"

	self should:
	[
		lisp top: #(let (func)
						(let ((x 10))
							(setq func (lambda (y) (+ x y))))
						(funcall func 5))
	] 
	raise: LispError

]

{ #category : #'as yet unclassified' }
ELispTest >> testSetcar [

	lisp top: #(setq animals $'(antelope giraffe lion tiger)).
	lisp top: #(setcar animals $'hippopotamus).
	self assert: (lisp top: #(car animals)) = #hippopotamus.


]

{ #category : #'as yet unclassified' }
ELispTest >> testSetcdr [

	self assert: (lisp top: #(progn (setq animals $'(antelope giraffe lion tiger))
					(setcdr animals $'(cat dog))
					(nth 2 animals))) = #dog.

	lisp top: #(setq animals $'(antelope giraffe lion tiger)).
	lisp top: #(setcdr animals $'(cat dog)).
	self assert: (lisp top: #(nth 2 animals)) = #dog.

]

{ #category : #'as yet unclassified' }
ELispTest >> testSetq [

	self should: [lisp top: #bouga] raise: LispError.
	self assert: (lisp top: #(setq bouga (+ 5 5))) = 10.
	self assert: (lisp top: #bouga) = 10.
	self assert: (lisp top: #(+ 1 bouga)) = 11.

	lisp top: #(setq x 10 y (+ x 10) z (* 2 y)).
	self assert: (lisp top: #(list x y z)) = #(10 20 40) asCons.


]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader [

	self assert: (lisp evalString: '(setq *boup--bloup* 15)') = 15 .
	self assert: (lisp evalString: '*boup--bloup*') = 15 .

	self assert: (lisp evalString: '(setq beuh//et-voila 16)') = 16 .
	self assert: (lisp evalString: 'beuh//et-voila') = 16 .

	self assert: (lisp evalString: '(setq |gloup:bah| 17)') = 17 .
	self assert: (lisp evalString: '|gloup:bah|') = 17 .

	self assert: (lisp evalString: '`(1 2 ,(+ 2 1) ,@(list 4 5))') = #(1 2 3 4 5) asCons.

	self assert: (lisp evalString: '3.1415') = 3.1415 .
	self assert: (lisp evalString: '2e-7') = 2.0e-7 .
	self assert: (lisp evalString: '.5') = 0.5 .
	self assert: (lisp evalString: '+.5') = 0.5 .
	self assert: (lisp evalString: '+1.5') = 1.5 .
	self assert: (lisp evalString: '-.5') = -0.5 .

	self assert: (lisp evalString: '1/2') = (1/2) .
	self assert: (lisp evalString: '-1/2') = (-1/2) .

	self assert: (lisp evalString: '"et''hop"') = 'et''hop' .
	self assert: (lisp evalString: '"un c''est \"un\""') = 'un c''est "un"' .

	self assert: (lisp evalString: '

(let ;test
; comments "comments" comments" 
	((x 10))
		(+ x 20) ;; beuh
)
') = 30

]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader2 [

	self assert: (lisp evalString: '`'',(cons ''a ''b)') asString = '(quote (a . b))'.
	self assert: (lisp evalString: '''`,(cons ''a ''b)') asString = '(quasiquote (unquote (cons (quote a) (quote b))))'.

	self assert: (lisp evalString: '(eval ``(,,@(list 1 2 3 4 5)))') asString = '(1 2 3 4 5)'.
	self assert: (lisp evalString: '(eval ``(,,2))') asString = '(2)'.
]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader3 [

	self assert: (lisp evalString: '(let ((true ''false)) true)') = #false .
	self should: [lisp evalString: '(list true false)'] raise: LispError .

]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader4 [

	self assert: (lisp evalString: '(+ 1 1 #| 5 4 |# 1)') = 3 .
	self assert: (lisp evalString: '(+ 1 1 #| 5 ; 4 |# 1)') = 3 .
	self assert: (lisp evalString: '(+ 1 1 #| 5 4|# 1)') = 3 .
	self assert: (lisp evalString: '(+ 1 1 #|5 4|# 1)') = 3 .
	self assert: (lisp evalString: '(+ 1 1 #| 5 )) ( 4 |# 1)') = 3 .
	self assert: (lisp evalString: '(concat "1 1" "#| 5 )) ( 4 |#" "1")') = '1 1#| 5 )) ( 4 |#1' .

]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader5 [

	self assert: (lisp evalString: '(+ 1 1 #. (+ 5 4) 1)') = 12 .
	self assert: (lisp evalString: '(+ 1 1 #.(+ 5 4) 1)') = 12 .


]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader6 [

	lisp loadDefaultLibraries.

	lisp evalString: '(setq x ''#0=(1 2 . #0#))'.	
	self assert: (lisp top: #(caddr x)) = 1 .
	self assert: (lisp top: #(nth 15 x)) = 2 .

	lisp evalString: '(setq y ''(1 2 #1=#(3 4) . #1#))' .
	self assert: (lisp top: #(eq (caddr y) (cdddr y))) = lisp trueValue .


]

{ #category : #'as yet unclassified' }
ELispTest >> testStringReader7 [

	self assert: (lisp evalString: '(cadr (quote (1 nil)))') isNil



]

{ #category : #'as yet unclassified' }
ELispTest >> testSymbols [

	self assert: (lisp top: #(eq (make-symbol 'uh') (make-symbol 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(eq (intern 'uh') (intern 'uh') )) == lisp trueValue.

	self assert: (lisp top: #(eq (make-symbol 'uh') (intern 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(let ((s (make-symbol 'uh')) (uh 20)) 
									(set s 10)
									(list (symbol-value s) uh))) = #(10 20) asCons
]

{ #category : #'as yet unclassified' }
ELispTest >> testTailCallOptimization [

	"this blows up CLISP and Emacs, works fine in SBCL"

	lisp top: #(defun test (n) (if (< n 5000) (test (+ n 1)) 'ok')).
	self assert: (lisp top: #(test 0)) = 'ok'

]

{ #category : #'as yet unclassified' }
ELispTest >> testTailCallOptimization2 [

	lisp top: #(setq x 0).
	lisp top: #(defun test (n) 
					(if (< n 500) 
						(progn 
							(princ n) 
							(let ((u x)) (setq x (+ x 1)) (test (+ u n 1)))) 
						(list x n))).

	self assert: (lisp top: #(test 0)) = #(32 528) asCons

]

{ #category : #'as yet unclassified' }
ELispTest >> testUnwindProtect [

	lisp top: #(defun dangerous (x) 
					(unwind-protect (/ 10 x) (setq comment 'things went ok'))).

	lisp top: #(setq comment 'no comment').
	self assert: (lisp top: #comment) = 'no comment'.
	self assert: (lisp top: #(dangerous 5)) = 2.
	self assert: (lisp top: #comment) = 'things went ok'.

	lisp top: #(setq comment 'no comment').
	self assert: (lisp top: #(dangerous 0)) isNil.
	self assert: (lisp top: #comment) = 'things went ok'.


]

{ #category : #'as yet unclassified' }
ELispTest >> testVectors [

	self assert: (lisp top: #(vector 1 '2' $'trois)) =  #(1 '2' trois).
	self assert: (lisp top: #(setq v (make-vector 3 $'Z))) =  #(Z Z Z).
	self assert: (lisp top: #(vectorp v)) = lisp trueValue.
	self assert: (lisp top: #(equal (vector `Z `Z `Z) v)) = lisp trueValue.
	self assert: (lisp evalString: '(equal #(Z Z Z) v)') = lisp trueValue.
	self assert: (lisp top: #(eq (vector `Z `Z `Z) v)) = lisp falseValue.
	self assert: (lisp top: #(vconcat v v)) =  #(Z Z Z Z Z Z)
]

{ #category : #'as yet unclassified' }
ELispTest >> testWhile [

	lisp top: #(progn 
					(setq i 5)
					(while (> i 0) (setq i (- i 1)))).

	self assert: (lisp top: #(progn i)) = 0
]
