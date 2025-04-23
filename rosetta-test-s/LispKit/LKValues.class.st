"
multiple values for Lisp

"
Class {
	#name : #LKValues,
	#superclass : #Array,
	#type : #variable,
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKValues >> asOneLispValue [

	^ self at: 1 ifAbsent: [nil]
]

{ #category : #'as yet unclassified' }
LKValues >> isLKValues [

	^ true
]

{ #category : #'as yet unclassified' }
LKValues >> printOn: aStream forLisp: aLisp [

	self isEmpty ifTrue: [^ self].
	self size = 1 ifTrue: [^ self first printOn: aStream forLisp: aLisp].

	1 to: self size -1do: [:i | 
		(self at: i) printOn: aStream forLisp: aLisp.
		aStream cr].

	self last printOn: aStream forLisp: aLisp
]

{ #category : #'as yet unclassified' }
LKValues >> valueForLisp: aLisp allowMultipleValues: mvflag inTail: tflag [

	mvflag ifFalse: [^ self asOneLispValue].
	^ self
]
