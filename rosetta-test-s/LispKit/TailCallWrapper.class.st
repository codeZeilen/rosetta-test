"
Represent a Lisp/Scheme procedure invocation.

When tail call optimization happens, a TailCallWrapper is returned so that the embedded procedure call gets evaluated in the optimizing loop instead of being evaluated recursively, which would grow the stack.

The loop lives in method #evaluate. The first (scope-wise) TailCallWrapper must be returned as a regular value and be created with class-side method #startOn:Procedure:args:lisp: where it will hijack the interpreter and catch all tail calls before returning its actual value.

See LispKernel>>#evalTailObject: for usage
"
Class {
	#name : #TailCallWrapper,
	#superclass : #Object,
	#instVars : [
		'args',
		'lisp',
		'procedure',
		'id'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
TailCallWrapper class >> startOnProcedure: func args: args lisp: aLisp [

	"create a new TailCallWrapper instance which will act as a trampoline: 
	see instance side method #evaluate"

	| tcw |

	tcw :=  self new procedure: func; args: args; lisp: aLisp.
	aLisp inTail: tcw.
		
	^ tcw evaluate
]

{ #category : #accessing }
TailCallWrapper >> args [

	^ args 
]

{ #category : #accessing }
TailCallWrapper >> args: aConsCell [

	args  := aConsCell
]

{ #category : #evaluating }
TailCallWrapper >> evaluate [

	"the trampoline, aka tail call optimization loop"

	| val |
	
	val := self procedure applyTo: args inLisp: lisp asMacro: false.
	[val isTailCallWrapper] whileTrue:
		[val := val procedure applyInTailTo: val args inLisp: val lisp asMacro: false].

	^ val
	
]

{ #category : #accessing }
TailCallWrapper >> id [

	^ id 
]

{ #category : #accessing }
TailCallWrapper >> id: aSymbol [

	id := aSymbol
]

{ #category : #accessing }
TailCallWrapper >> isTailCallWrapper [

	^ true
]

{ #category : #accessing }
TailCallWrapper >> lisp [

	^ lisp
]

{ #category : #accessing }
TailCallWrapper >> lisp: aLisp [

	lisp  := aLisp.

]

{ #category : #accessing }
TailCallWrapper >> procedure [

	^ procedure 
]

{ #category : #accessing }
TailCallWrapper >> procedure: aConsCell [

	procedure :=  aConsCell
]
