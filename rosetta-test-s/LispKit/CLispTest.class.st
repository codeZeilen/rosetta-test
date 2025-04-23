"
This is the unit test for the class CLisp. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #CLispTest,
	#superclass : #StaticLispTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
CLispTest class >> shouldInheritSelectors [

	^ true
]

{ #category : #'as yet unclassified' }
CLispTest >> setUp [

	lisp := CLisp new
]

{ #category : #'as yet unclassified' }
CLispTest >> testScope03 [

	lisp top: #(progn
					(setq regular 5)
 					(defun check-regular () regular)).

	self assert: (lisp top: #(check-regular)) = 5.
	self assert: (lisp top: #(let ((regular 6)) (check-regular))) = 5.

	lisp top: #(progn
					(defvar special 5)
 					(defun check-special () special)).

	self assert: (lisp top: #(check-special )) = 5.
	self assert: (lisp top: #(let ((special 6)) (check-special ))) = 6.

]

{ #category : #'as yet unclassified' }
CLispTest >> testScope04 [

	self should: [
	lisp top: #(let ((x 1) (y 2))
					(let ((y 2) (z 3)) 
						(+ x y z)) 
					z)
	] raise: Error.

	lisp top: #(defvar z 10).

	lisp assert: (
	lisp top: #(let ((x 1) (y 2))
					(let ((y 2) (z 3)) 
						(setq sum (+ x y z)))
					z)
	) = 10.

	self assert: (lisp top: #sum) = 6.


]

{ #category : #'as yet unclassified' }
CLispTest >> testScope05 [

	lisp top: #(progn
					(defvar z 1) 
					(defun foo () z)
					(defun baz ()
						(let ((z 2)) 
						(foo)))).

	self assert: (lisp top: #(baz)) = 2


]

{ #category : #'as yet unclassified' }
CLispTest >> testScope07 [


	lisp top: #(progn
					(defun baz ()
						(let ((x 2))
							(list x (symbol-value $'x)))) 
					(defun foo ()
						(let ((x 1))
							(baz)))).

	self should: [lisp top: #(foo)] raise: LispError


]

{ #category : #'changes from kernel' }
CLispTest >> testScope08 [

	lisp top: #(progn
					(defun baz ()
						(let ((x 2))
							(list x (symbol-value $'x)))) 
					(defun foo ()
						(let ((x 1))
							(declare (special x)) 
							(baz)))).

	self assert: (lisp top: #(foo)) = #(2 1) asCons

]

{ #category : #'as yet unclassified' }
CLispTest >> testScope09 [

	lisp top: #(progn
					(defvar x 1)
					(defun baz () x)
					(defun foo ()
						(let ((x 2)) 
							(baz)))).

	self assert: (lisp top: #(foo)) = 2


]

{ #category : #'as yet unclassified' }
CLispTest >> testScope10 [

	lisp top: #(progn
					(setq x 1)
					(defun baz () x)
					(defun foo ()
						(let ((x 2)) 
						(baz)))).

	self assert: (lisp top: #(foo)) = 1.

	lisp top: #(progn
					(defvar x 1)
					(defun baz () x)
					(defun foo ()
						(let ((x 2)) 
						(baz)))).

	self assert: (lisp top: #(foo)) = 2


]

{ #category : #'changes from kernel' }
CLispTest >> testScope20 [

	lisp top: #(progn
					(defvar x 45)
					(let ((y 2)) (setq x y))).

	self assert: (lisp top: #x) = 2.

	lisp top: #	(setq x 10).

	self assert: (lisp top: #x) = 10.

]

{ #category : #'changes from kernel' }
CLispTest >> testScope21 [

	lisp top: #(progn
					(defvar x 45)
					(let ((y 2)) (makunbound $'x))).

	self should: [lisp top: #x] raise: LispError.


]

{ #category : #'changes from kernel' }
CLispTest >> testScope22 [

	self should: [lisp top: #(progn
					(defvar x 45)
					(let ((x 2)) (makunbound $'x) x))] raise: LispError



]

{ #category : #'changes from kernel' }
CLispTest >> testScope23 [

	lisp top: #(defun bouh () joe).

	self should: [lisp top: #(bouh)] raise: LispError.
	self should: [lisp top: #(let ((joe 5)) (bouh))] raise: LispError.

	self assert: (lisp top: #(let ((joe 5)) (declare (special joe)) (bouh))) = 5

]

{ #category : #'changes from kernel' }
CLispTest >> testScope24 [

	"from Common Lisp the Language, 2nd edition, section 9.2"

	lisp top: #(defvar x).
	lisp top: #(defvar sum).
	lisp top: #(defun foo (x) (list x y)).

	self should: [lisp top: #(foo 25)] raise: LispError.

	lisp top: #(defun test (x y)   
					(declare (special y))  
					(let ((y 3) (x (* x 2)))   
						(setq sum (+ y (locally (declare (special y)) y)))   
						(let ((y 4)) (declare (special y)) (foo x)))).

	self assert: (lisp top: #(test 1 10)) = #(2 4) asCons.
	self assert: (lisp top: #sum) = 13.

	lisp top: #(defun test (x y)   
					(declare (special y))  
					(let ((y 3) (x (* x 2)))   
						(setq sum (+ y (locally (declare (special y)) y)))   
						(let ((y 4)) (foo x)))).

	self assert: (lisp top: #(test 1 10)) = #(2 10) asCons.
	self assert: (lisp top: #sum) = 13.
	self should: [lisp top: #x] raise: LispError.
	self should: [lisp top: #y] raise: LispError
]

{ #category : #'changes from kernel' }
CLispTest >> testSymbols [

	self assert: (lisp top: #(eq (make-symbol 'uh') (make-symbol 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(eq (intern 'uh') (intern 'uh') )) == lisp trueValue.

	self assert: (lisp top: #(eq (make-symbol 'uh') (intern 'uh'))) == lisp falseValue.

	self assert: (lisp top: #(let ((s (make-symbol 'uh')) (uh 20)) 
									(set s 10)
									(list (eval s) uh))) = #(10 20) asCons
]

{ #category : #'changes from kernel' }
CLispTest >> testUnboundDynamicVariables [

	self should: [lisp top: #(locally (declare (special y)) y)] raise: LispError.

	lisp top: #(defvar uh).
	self should: [lisp top: #uh] raise: LispError.
	
]
