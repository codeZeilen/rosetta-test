"
a LispKernel primitive
"
Class {
	#name : #LKPrimitive,
	#superclass : #Object,
	#instVars : [
		'selector',
		'lisp'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKPrimitive class >> selector: aSymbol for: aLisp [

	(aLisp specialForms pointsTo: aSymbol) 
		ifTrue: [^ LKPrimitiveSpecial new selector: aSymbol; lisp: aLisp].

	^ self new selector: aSymbol; lisp: aLisp
		

]

{ #category : #'as yet unclassified' }
LKPrimitive >> applyInTailTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ self applyTo: aConsCell inLisp: aLisp asMacro: mflag

]

{ #category : #'as yet unclassified' }
LKPrimitive >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	(aConsCell isNil | mflag)
			ifTrue: [^ aLisp perform: selector with: aConsCell].

	^ aLisp perform: selector with: (aLisp evalList: aConsCell).
]

{ #category : #'as yet unclassified' }
LKPrimitive >> isLKPrimitive [

	^ true

]

{ #category : #'as yet unclassified' }
LKPrimitive >> isLKPrimitiveSpecial [

	^ false

]

{ #category : #'as yet unclassified' }
LKPrimitive >> lisp: aLispClass [

	lisp := aLispClass
]

{ #category : #'as yet unclassified' }
LKPrimitive >> lispCode [

	^ (lisp ultimateSourceCodeAt: selector 
		ifAbsent: [self error: 'missing primitive']) asString
]

{ #category : #'as yet unclassified' }
LKPrimitive >> printOn: aStream [

	aStream nextPutAll: 'primitive '; nextPutAll: selector

]

{ #category : #'as yet unclassified' }
LKPrimitive >> selector [

	^ selector
]

{ #category : #'as yet unclassified' }
LKPrimitive >> selector: aSymbol [

	selector := aSymbol
]
