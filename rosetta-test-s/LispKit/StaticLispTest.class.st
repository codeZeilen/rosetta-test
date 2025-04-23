"
This is the unit test for the class ULisp. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #StaticLispTest,
	#superclass : #ELispTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
StaticLispTest class >> shouldInheritSelectors [

	^ true
]

{ #category : #'as yet unclassified' }
StaticLispTest >> setUp [

	lisp := StaticLisp new
]

{ #category : #'changes from kernel' }
StaticLispTest >> testAutoModifyingFunction [
]

{ #category : #'to do' }
StaticLispTest >> testDefunWithKeywords4 [

	"fails. depends on code initially written for Emacs (full dynamic scoping)"
]

{ #category : #'changes from kernel' }
StaticLispTest >> testDynamicScoping [

	"no dynamic scoping"
]

{ #category : #'changes from kernel' }
StaticLispTest >> testLambda [

	self assert: (lisp top: #((lambda () 2))) = 2.
	self assert: (lisp top: #((lambda nil 2))) = 2.
	self assert: (lisp top: #(lambda (x y) (+ x y 2))) printString = '(lambda (x y) (+ x y 2))'.
	self assert: (lisp top: #((lambda (x y) (+ x y 2)) 5 8)) = 15.

]

{ #category : #'to do' }
StaticLispTest >> testLoop [

	"fails. depends on code initially written for Emacs (full dynamic scoping)"
]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope [

	self assert: (lisp top: #(let (func)
						(let ((x 10))
							(setq func (lambda (y) (+ x y))))
						(apply func $'(5)))) = 15


]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope01 [

	self assert:
	(
		lisp top: #(let (func)
						(let ((x 10))
							(setq func (lambda (y) (+ x y))))
						(apply func $'(5)))
	) = 15.
	
	self assert:
	(
		lisp top: #(progn 
						(let ((x 10))
							(defun func (y) (+ x y)))
						(func 5))
	) = 15.

]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope02 [

	lisp loadDefaultLibraries.

	lisp top: #(defun compose (f g) 
  					(lambda (x) (funcall f (funcall g x)))).

	self assert: (lisp top: #(funcall (compose $'sqrt $'abs) -9)) = 3.

]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope06 [

	lisp top: #(progn
					(setq z 1) 
					(defun foo () z)
					(defun baz ()
						(let ((z 2)) 
							(foo)))).

	self assert: (lisp top: #(baz)) = 1


]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope11 [

	lisp top: #(defun baz ()
					(let ((x 1)) 
						(lambda ()
							(setq x (+ x 1))))).

	lisp top: #(progn 
					(setq x1 (baz))
					(setq x2 (baz))).

	self assert: (lisp top: #(funcall x1)) = 2.
	self assert: (lisp top: #(funcall x1)) = 3.
	self assert: (lisp top: #(funcall x1)) = 4.
	self assert: (lisp top: #(funcall x2)) = 2.


]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope12 [

	lisp loadDefaultLibraries. "for first and second"

	lisp top: #(progn 
					(defun up-n-down ()
					(let ((x 0))
						(list
							(lambda () (setq x (+ x 1)))
							(lambda () (setq x (- x 1))))))
					(setq f1 (up-n-down)) 
					(setq f2 (up-n-down))). 

	self assert: (lisp top: #(funcall (first f1))) = 1.
	self assert: (lisp top: #(funcall (first f1))) = 2.
	self assert: (lisp top: #(funcall (first f1))) = 3.
	self assert: (lisp top: #(funcall (second f1))) = 2.
	self assert: (lisp top: #(funcall (first f2))) = 1.
	self assert: (lisp top: #(funcall (first f2))) = 2.
	self assert: (lisp top: #(funcall (first f2))) = 3.
	self assert: (lisp top: #(funcall (second f2))) = 2.
						
]

{ #category : #'changes from kernel' }
StaticLispTest >> testScope13 [

	lisp loadDefaultLibraries.

	lisp top: #(progn 
					(defun up-n-down ()
					(let ((x 0))
						(list
							(lambda () (setq x (+ x 1)))
							(let ((y 2))
								(lambda () (setq x (- x 1)))))))
					(setq f1 (up-n-down)) 
					(setq f2 (up-n-down))). 

	self assert: (lisp top: #(funcall (first f1))) = 1.
	self assert: (lisp top: #(funcall (first f1))) = 2.
	self assert: (lisp top: #(funcall (first f1))) = 3.
	self assert: (lisp top: #(funcall (second f1))) = 2.
	self assert: (lisp top: #(funcall (first f2))) = 1.
	self assert: (lisp top: #(funcall (first f2))) = 2.
	self assert: (lisp top: #(funcall (first f2))) = 3.
	self assert: (lisp top: #(funcall (second f2))) = 2.
						
]
