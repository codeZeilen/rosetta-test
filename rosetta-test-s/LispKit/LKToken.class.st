Class {
	#name : #LKToken,
	#superclass : #WriteStream,
	#instVars : [
		'couldBeFraction',
		'couldBeExponent',
		'couldBeNumber',
		'base',
		'number',
		'dot',
		'sign',
		'nindex',
		'n1',
		'constants'
	],
	#category : #'LispKit-Reader-Base'
}

{ #category : #'as yet unclassified' }
LKToken class >> parse: aString [

	^ self parse: aString base: 10
	
]

{ #category : #'as yet unclassified' }
LKToken class >> parse: aString base: aNumber [

	| tok |
	tok := self void.
	tok base: aNumber.
	tok nextPutAll: aString.
	^ tok parsed
	
]

{ #category : #'as yet unclassified' }
LKToken class >> void [

	^ (self on: '') initialize
	
]

{ #category : #'as yet unclassified' }
LKToken >> base: aNumber [

	base := aNumber
]

{ #category : #'as yet unclassified' }
LKToken >> constants: aDictionary [

	constants := aDictionary
]

{ #category : #'as yet unclassified' }
LKToken >> digit: aCharacter [

	| value |
	value := aCharacter asciiValue.
	(value >= 48 and: [value <= (48 + base - 1)]) ifTrue: [^ value - 48].

	base > 10 ifFalse: [^ nil].

	(value >= 65 and: [value <= (65 + base - 11)]) ifTrue: [^ value - 55].
	(value >= 97 and: [value <= (97 + base - 11)]) ifTrue: [^ value - 87].

	^ nil
]

{ #category : #'as yet unclassified' }
LKToken >> getN1 [

	n1 := number * sign. 
	nindex := 0. 
	dot := nil. 
	sign := 1.
	number := nil
]

{ #category : #'as yet unclassified' }
LKToken >> initialize [

	couldBeNumber := true.
	couldBeFraction := couldBeExponent := true.
	base := 10.
	number := nil.
	dot := n1 := nil.
	sign := 1.
	nindex := 0.


]

{ #category : #'as yet unclassified' }
LKToken >> nextCharacter: aCharacter [

	nindex := nindex + 1.

	nindex = 1 ifTrue: 
	[
		aCharacter == $- 
			ifTrue: [sign := -1]
			ifFalse: [
				((self digit: aCharacter) notNil 
					or: [aCharacter == $+] or: [aCharacter == $.])
				ifFalse: [couldBeNumber := false]].
	].
		
	couldBeNumber ifFalse: [^ self].

	dot ifNotNil: [dot := dot / 10].
	aCharacter == $. ifTrue: [	
		base = 10 ifFalse: [couldBeNumber := false].
		couldBeFraction := false.
		n1 ifNotNil: [couldBeExponent := false].
		dot ifNotNil: [couldBeNumber := false] ifNil: [dot := 1].
	]
	ifFalse: [
		(couldBeExponent
			and: [n1 isNil] 
			and: [aCharacter == $e or: [aCharacter == $E]])
		ifTrue: [self getN1. couldBeFraction := false]
		ifFalse: [
			(couldBeFraction
				and: [n1 isNil] 
				and: [aCharacter == $/])
			ifTrue: [self getN1. couldBeExponent := false]
			ifFalse:
			[  | d |
				(d := self digit: aCharacter) notNil 
				ifFalse: [
					(((aCharacter == $+)	or: [aCharacter == $-])
						and: [nindex = 1])
					ifFalse: [couldBeNumber := false]
					ifTrue: [n1 ifNotNil: [couldBeFraction := false]]]
				ifTrue: [
					number ifNil: [number := 0].
					dot ifNil: [number := (base * number) + d]
					ifNotNil: [number := number asFloat + (d * dot)]]]]]

	
]

{ #category : #'as yet unclassified' }
LKToken >> nextPut: aCharacter [

	super nextPut: aCharacter.
	self nextCharacter: aCharacter
]

{ #category : #'as yet unclassified' }
LKToken >> nextPutAll: aCollection [ 
	"Append the elements of aCollection to the sequence of objects accessible 
	by the receiver. Answer aCollection."

	aCollection do: [:v | self nextPut: v].
	^aCollection
]

{ #category : #'as yet unclassified' }
LKToken >> parsed [

	(couldBeNumber not or: [number isNil]) ifTrue: [^ self parsedAsSymbol].

	n1 ifNotNil: 
	[
		(couldBeFraction and: [number isZero not]) ifTrue: [^ n1/number].
		couldBeExponent ifTrue: [^ n1 asFloat * (10 raisedTo: (number * sign))].
		^ self parsedAsSymbol
	].

	^ number * sign
]

{ #category : #'as yet unclassified' }
LKToken >> parsedAsSymbol [

	| sym |
	sym :=  self contents asSymbol.	
	^ (constants ifNil: [^ sym]) at: sym ifAbsent: [sym]

]
