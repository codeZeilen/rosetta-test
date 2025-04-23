"
This is the unit test for the class SLisp. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #SLispTest,
	#superclass : #ELispTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
SLispTest class >> shouldInheritSelectors [

	^ true
]

{ #category : #'as yet unclassified' }
SLispTest >> setUp [

	lisp := SLisp new
]

{ #category : #'changes from kernel' }
SLispTest >> testAnd [

	self assert: (lisp top: #(and true 4 (* 10 45))) = 450.
	self assert: (lisp top: #(and true false (* 10 45))) = false.
	self assert: (lisp top: #(and () nil (* 10 45))) = 450.

]

{ #category : #'changes from kernel' }
SLispTest >> testAutoModifyingFunction [

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

]

{ #category : #'as yet unclassified' }
SLispTest >> testBasics [

	self assert: (lisp top: #(@ 10 15)) = (10@15).
	self assert: (lisp top: #(smalltalk '10@15')) = (10@15)
]

{ #category : #'changes from kernel' }
SLispTest >> testCompiler2 [

	"different behavior for funbound symbol"
]

{ #category : #'changes from kernel' }
SLispTest >> testDefun [

	self should: [lisp top: #(plus  5 4)] raise: Error. "not a LispError any more"

	lisp top: #(defun plus (x y) (+ x y)).

	self assert: (lisp top: #(plus  5 4)) = 9.
	self assert: (lisp top: #(plus (+ 1 1) (+ 2 2))) = 6.
]

{ #category : #'changes from kernel' }
SLispTest >> testIf [

	self assert: (lisp top: #(if true 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if nil 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if $'nil 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if #() 4 (* 10 45))) = 4.
	self assert: (lisp top: #(if false 4 (* 10 45))) = 450.

	self assert: (lisp top: #(if $'ok 4 (/ 1 0))) = 4.
	self should: [lisp top: #(if false 4 (/ 1 0))] raise: Error
]

{ #category : #'changes from kernel' }
SLispTest >> testLoop [

	"hangs forever. 
	loop code requires t/nil as booleans while we have true/false in SLisp"
]

{ #category : #'as yet unclassified' }
SLispTest >> testNameSpace [

	lisp top: #(setq p (@ 10 15)).
	self assert: (lisp top: #(smalltalk 'p + (1@2)')) = (11@17).

	self assert: (lisp top: #(let ((x 1)) (smalltalk 'x'))) = 1.
	self should: [lisp top: #(let ((#'n--uh!' 1)) (smalltalk 'n--uh!'))] raise: Error
]

{ #category : #'as yet unclassified' }
SLispTest >> testNameSpace2 [

	| q |

	lisp top: #(setq p 2).
	q := -2.
	self should: [lisp top: #(! 'q + p)')] raise: Error.	
	self assert: (lisp top: {#+ . q . #p}) = 0	
]

{ #category : #'as yet unclassified' }
SLispTest >> testNameSpace3 [

	lisp top: #(setq m (new Morph)).
	lisp top: #(progn {m position: (5@56)}).

	self assert: (lisp top: #(progn {m position})) = (5@56).	
]

{ #category : #'changes from kernel' }
SLispTest >> testOr [

	self assert: (lisp top: #(or true 4 (* 10 45))) = true.
	self assert: (lisp top: #(or nil true false (* 10 45))) = nil.
	self assert: (lisp top: #(or false)) = lisp falseValue.

]

{ #category : #'as yet unclassified' }
SLispTest >> testSelectorRedirection [

	"see #lispPerform:with:"

	self assert: (lisp top: #(size (rgbTriplet (blue Color)))) = 3


]

{ #category : #'changes from kernel' }
SLispTest >> testStringReader3 [

	self should: [lisp evalString: '(let ((true ''false)) true)'] raise: LispError .
	self assert: (lisp evalString: '(list true false)') = #(true false) asCons

]

{ #category : #'changes from kernel' }
SLispTest >> testStringReader8 [

	self assert: (lisp evalString: '(car (quote (self)))') == lisp.
	self assert: (lisp evalString: '(car (quote (true)))') == true.
	self assert: (lisp evalString: '(car (quote (false)))') == false.	

]

{ #category : #'as yet unclassified' }
SLispTest >> testVectors [

	self assert: (lisp top: #(rgbTriplet (blue Color))) = #(0.0 0.0 1.0).
	self assert: (lisp top: #(elt (rgbTriplet (blue Color)) 2)) = 1.0.
	self assert: (lisp top: #(vector-to-list (rgbTriplet (blue Color)))) = #(0.0 0.0 1.0) asCons

]

{ #category : #'as yet unclassified' }
SLispTest >> testVectors2 [

	self assert: (lisp top: #(apply $'vector (vector-to-list (rgbTriplet (blue Color))))) = #(0.0 0.0 1.0).


]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax [

	self assert: (lisp top: #(+ 2 {4 sqrt})) = 4.

	self assert: 
	(lisp top: #(progn {(5@6) flipBy: $#vertical centerAt: (0@ [- 5 5])})) = (5@-6).

	self assert: 
	(lisp top: #(progn {Morph new perform: $#yourself})) isMorph.

	self assert: (lisp top: #(+ 10 {1+ [+ 2 2 {3 + 3 + 3}] + 1})) = 25.
	
	self assert: (lisp top: #(if {5 isNumber} 'ok' 'no!')) = 'ok'.

	self assert: (lisp top: #(setq string (smalltalk '''abc'' , ''def'''))) = 'abcdef'.

	self assert: (lisp top:#(if {$#symbol isSymbol} 1 0)) = 1

]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax2 [

	self assert: (lisp top: #(progn {5 - 5})) = 0.
	self should: [lisp top: #(progn {5-5})] raise: Error
]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax3 [

	self assert: (lisp top: #(+ 1 {(0 to: 10) size})) = 12.

]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax4 [

	self assert: (lisp evalString: '(+ 1 {2 + [+ 3 3] + 2})') = 11.
	self assert: (lisp evalString: '{1 + [+ 2 2 {3 + 3}]}') = 11.

]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax5 [

	"beware of preference rules... better use parenthesis"

	self assert: (lisp evalString: '`(+ 1 ,{2 * (2 + 2)})') printString = '(+ 1 8)'.
	self assert: (lisp evalString: '`(+ 1 ,{2 * 2 + 2})') printString = '(+ 1 6)'
	

]

{ #category : #'changes from kernel' }
SLispTest >> testWithSmalltalkSyntax6 [

	self assert: (lisp evalString: '{#openInWorld copyFrom: 4 to: 7}') = 'nInW'
]
