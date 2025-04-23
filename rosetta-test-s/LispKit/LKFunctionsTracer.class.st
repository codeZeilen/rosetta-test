Class {
	#name : #LKFunctionsTracer,
	#superclass : #LKTracer,
	#instVars : [
		'functions'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKFunctionsTracer >> functions: anArray [

	functions := anArray
]

{ #category : #'as yet unclassified' }
LKFunctionsTracer >> initialize [

	functions := #()
]

{ #category : #'as yet unclassified' }
LKFunctionsTracer >> subLisp: aForm from: aLisp [
"
	aLisp displayStream 
		nextPut: $\;
		nextPutAll: (aLisp depth + 1) asString ; tab;
		nextPutAll: (aForm printStringForLisp: aLisp limitedTo: 50); cr.
"
]

{ #category : #'as yet unclassified' }
LKFunctionsTracer >> trace: anObject in: aLisp [

	| str |

	(anObject isConsCell and: [functions includes: anObject car])
		ifFalse: [^ anObject].

	str := aLisp standardOutput stream.

	str	nextPutAll: aLisp depth asString ; tab;
		nextPutAll: ((aLisp upperForm ifNil: ['<top>']) printStringForLisp: aLisp limitedTo: 100); cr.
	str tab; nextPutAll: (anObject printStringForLisp: aLisp limitedTo: 100); cr.
	aLisp standardOutput endEntry.

	^ anObject
]

{ #category : #'as yet unclassified' }
LKFunctionsTracer >> traceResult: anObject for: bObject in: aLisp [
]
