Class {
	#name : #ConsGenerator,
	#superclass : #Object,
	#instVars : [
		'cc'
	],
	#category : #ConsCell
}

{ #category : #'as yet unclassified' }
ConsGenerator class >> cyclicOn: anArray [

	^ self new consCell: anArray asCyclicCons
]

{ #category : #'as yet unclassified' }
ConsGenerator class >> on: anArray [

	^ self new consCell: anArray asCons
]

{ #category : #'as yet unclassified' }
ConsGenerator >> atEnd [

	^ cc cdr isNil
]

{ #category : #'as yet unclassified' }
ConsGenerator >> consCell [

	^ cc 
]

{ #category : #'as yet unclassified' }
ConsGenerator >> consCell: aConsCell [

	cc := aConsCell
]

{ #category : #'as yet unclassified' }
ConsGenerator >> next [

	^ cc car in: [:v | 
		cc := cc cdr.
		^ v]
]

{ #category : #'as yet unclassified' }
ConsGenerator >> next: anInteger [ 
	"Answer the next anInteger number of objects accessible by the receiver."

	| aCollection |
	aCollection := OrderedCollection new.
	anInteger timesRepeat: [aCollection addLast: self next].
	^aCollection
]

{ #category : #'as yet unclassified' }
ConsGenerator >> peek [

	self atEnd ifTrue: [^ nil].

	^ cc cadr
]
