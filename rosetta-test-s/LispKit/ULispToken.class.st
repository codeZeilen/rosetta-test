"
token for ULispReader
"
Class {
	#name : #ULispToken,
	#superclass : #LKToken,
	#instVars : [
		'couldBeComplex',
		'i',
		'startWithSign',
		'real',
		'ims'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #'as yet unclassified' }
ULispToken >> initialize [

	super initialize.
	couldBeComplex := true.
	startWithSign := false.
	i := nil



]

{ #category : #'as yet unclassified' }
ULispToken >> nextCharacter: aCharacter [

	"implements number parsing, including fraction and complex numbers, and even complex numbers with fractional real/imaginary parts. see ULispTest>>testComplex
	
	this obfuscated parser has been painstakingly written by hand with much trials and errors; it is probably good to be replaced altogether should an extension be wanted"

	nindex := nindex + 1.

	i 
	ifNotNil: [couldBeNumber := false]
	ifNil: [((aCharacter == $i) or: [aCharacter == $I]) ifTrue:
		[
			number ifNil: [number := 1]. 
			(couldBeComplex not or: [real notNil]) ifTrue:
			[		
				n1 ifNotNil: [number := self parsed].
				n1 := real.
				sign := ims ifNil: [1].
				couldBeComplex := true
			].
			i := nindex. 			
			^ self
		]].

	nindex = 1 ifTrue: 
	[
		((#($+ $-) pointsTo: aCharacter)	
			and: [n1 isNil]) ifTrue: [startWithSign := true].
		aCharacter == $- ifTrue: [sign := -1]
			ifFalse: [
				((self digit: aCharacter) notNil or: [#($+ $.) pointsTo: aCharacter])
				ifFalse: [couldBeNumber := false]].
	].
		
	couldBeNumber ifFalse: [^ self].

	dot ifNotNil: [dot := dot / 10].
	
	aCharacter == $. ifTrue: 
	[	
		base = 10 ifFalse: [couldBeNumber := false].
		couldBeFraction := false.
		n1 ifNotNil: [couldBeExponent := false].
		dot ifNotNil: [couldBeNumber := false] ifNil: [dot := 1].
	]
	ifFalse: [		
		(nindex > 1 
			and: [real isNil] 
			and: [#($+ $-) pointsTo: aCharacter])
		ifTrue: 
		["read real part of a complex number"
			real := self parsed.
			sign := 1.
			ims:=  aCharacter == $- ifTrue: [-1] ifFalse: [1].
			n1 := number := nil.
			dot := nil.
			couldBeExponent := couldBeFraction := true
		]
		ifFalse: 
		[
			(couldBeExponent
				and: [n1 isNil] 
				and: [number notNil]
				and: [#($e $E) pointsTo: aCharacter])
			ifTrue: [
				self getN1. 				
				couldBeFraction := couldBeComplex := false
			]
			ifFalse: 
			[
				(couldBeFraction
					and: [n1 isNil] 
					and: [aCharacter == $/])
				ifTrue: [self getN1. couldBeExponent := couldBeComplex := false]
				ifFalse: [
					 | d |
						(d := self digit: aCharacter) notNil 
						ifFalse: [
							((aCharacter == $i) or: [aCharacter == $I])
							ifFalse: [	(((aCharacter == $+) or: [aCharacter == $-])
											and: [nindex = 1])
										ifFalse: [couldBeNumber := false]
										ifTrue: [n1 ifNotNil: [couldBeFraction := false]]]]
						ifTrue: [
							number ifNil: [number := 0].
							dot ifNil:[number := (base * number) + d]
								ifNotNil: [number := number asFloat + (d * dot)]]]]]]
]

{ #category : #'as yet unclassified' }
ULispToken >> parsed [

	((couldBeNumber & couldBeComplex) and: [i notNil]) ifFalse: [^ super parsed].
	
	^ Complex
		real: (n1 ifNil: [startWithSign ifTrue: [0] ifFalse: [^ self contents asSymbol]]) 
		imaginary: number * sign

	

]
