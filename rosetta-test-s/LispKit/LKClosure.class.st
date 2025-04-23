"
Wraps a Lisp form (actually a ConsCell) defining a lambda or macro along with its environment (see class LKEnvironment).

This is used to implement lexical scoping in specific Lisp dialects.

"
Class {
	#name : #LKClosure,
	#superclass : #Object,
	#instVars : [
		'form',
		'environment'
	],
	#category : #LispKit
}

{ #category : #testing }
LKClosure >> = aClosure [

	^ self species = aClosure species
		and: [form = aClosure lambdaForm]
		and: [environment = aClosure lispEnvironment]
]

{ #category : #testing }
LKClosure >> applyInTailTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ form applyTo: aConsCell inLisp: aLisp withEnvironment: environment asMacro: mflag noSubLisp: true

]

{ #category : #testing }
LKClosure >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ form applyTo: aConsCell inLisp: aLisp 
		withEnvironment: environment asMacro: mflag

]

{ #category : #accessing }
LKClosure >> form [

	^ form 
]

{ #category : #accessing }
LKClosure >> form: aConsCell [

	form := aConsCell
]

{ #category : #inspecting }
LKClosure >> inULisp [

	environment inspectWith: ULisp
]

{ #category : #testing }
LKClosure >> isLispClosure [

	^ true
]

{ #category : #testing }
LKClosure >> isMacro [

	^ form isMacro
]

{ #category : #testing }
LKClosure >> isProcedure [

	^ form isProcedure
]

{ #category : #'lambda protocol' }
LKClosure >> lambdaForm [

	^ form
]

{ #category : #accessing }
LKClosure >> lispCode [

	^ form 
]

{ #category : #accessing }
LKClosure >> lispEnvironment [

	^ environment 
]

{ #category : #accessing }
LKClosure >> lispEnvironment: aDictionary [

	environment := aDictionary
]

{ #category : #testing }
LKClosure >> lkosClass: aLisp [

	^ LKOSInstance class: #'<procedure>' inLisp: aLisp
]

{ #category : #printing }
LKClosure >> printOn: aStream [

	^ form printOn: aStream
]

{ #category : #printing }
LKClosure >> printOn: aStream forLisp: aLisp [

	^ aStream nextPutAll: '#<', form first, '-procedure>'
]

{ #category : #testing }
LKClosure >> procedureForArguments: aConsCell lisp: aLisp [

	"other kinds of procedure (e.g. generic functions) may return different actual procedures depending on the arguments"

	^ self
]
