Class {
	#name : #LKHalt,
	#superclass : #LKTracer,
	#instVars : [
		'functions'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKHalt >> functions: anArray [

	functions := anArray
]

{ #category : #'as yet unclassified' }
LKHalt >> initialize [

	functions := #()
]

{ #category : #'as yet unclassified' }
LKHalt >> symbolsValuesAdded: anAssociation in: aLisp [
]

{ #category : #'as yet unclassified' }
LKHalt >> trace: anObject in: aLisp [

	(anObject isConsCell and: [functions includes: anObject car])
		ifFalse: [^ anObject].

	aLisp debug.	
	aLisp halt: nil.

	^ anObject
]

{ #category : #'as yet unclassified' }
LKHalt >> traceResult: anObject for: bObject in: aLisp [

]
