"
a reader for textual Lisp code/data

based on Common Lisp the Language, 2nd edition, chapter 22.1
"
Class {
	#name : #LKReader,
	#superclass : #Object,
	#instVars : [
		'lisp',
		'labels'
	],
	#classInstVars : [
		'CharacterNames',
		'Macros',
		'SharpMacros',
		'SyntacticTypes'
	],
	#category : #'LispKit-Reader-Base'
}

{ #category : #'as yet unclassified' }
LKReader class >> characterNames [ 

	^ CharacterNames 
]

{ #category : #'as yet unclassified' }
LKReader class >> for: aLisp [

	^ self new lisp: aLisp
]

{ #category : #'as yet unclassified' }
LKReader class >> initialize [
	
	"LKReader initialize "
	"see Common Lisp the Language, 2nd edition, section 22.1.1"

	SyntacticTypes := Array new: 256 withAll: #constituent. "default"
	SyntacticTypes 
		atAll: #(9 10 12 13 32 160) put: #whiteSpace. "tab lf ff cr space +PLT compatibility"

	SyntacticTypes 
		atAll: (#($" $; $' $( $) $, $`) collect: [:c | c asciiValue]) 
		put: #terminatingMacro.

	SyntacticTypes at: $\ asciiValue put: #singleEscape.
	SyntacticTypes at: $| asciiValue put: #multipleEscape.
	SyntacticTypes at: $# asciiValue put: #nonTerminatingMacro.
		
	Macros := Dictionary new.
	{
		$# -> #sharpMacro:.
		$( -> #openList:.
		$) -> #closeList:.
		$' -> #quote:.
		$; -> #comment:.
		$" -> #string:.
		$` -> #backquote:.
		$, -> #unquote:.	
	}
	do: [:assoc | Macros add: assoc].

	SharpMacros := Dictionary new.
	{
		$# -> #sharpLabelReference:n:.
		$( -> #sharpVector:n:.
		$' -> #sharpFunction:n:.
		$* -> #sharpBitVector:n:.
		$= -> #sharpLabel:n:.
		$\ -> #sharpCharacter:n:.
		$, -> #sharpLoadTimeEvaluation:n:.
		$| -> #sharpBalancedComment:n:.
		$- -> #sharpReadTimeUnless:n:.
		$+ -> #sharpReadTimeWhen:n:.
		$. -> #sharpReadTimeEvaluation:n:.
		$: -> #sharpUninternedSymbol:n:.
		$a -> #sharpArray:n:.
		$A -> #sharpArray:n:.
		$b -> #sharpBinaryRational:n:.
		$B -> #sharpBinaryRational:n:.
		$c -> #sharpComplexNumber:n:.
		$C -> #sharpComplexNumber:n:.
		$o -> #sharpOctalRational:n:.
		$O -> #sharpOctalRational:n:.
		$p -> #sharpPathName:n:.
		$P -> #sharpPathName:n:.
		$r -> #sharpRadixNRational:n:.
		$R -> #sharpRadixNRational:n:.
		$s -> #sharpStructure:n:.
		$S -> #sharpStructure:n:.
		$x -> #sharpHexaRational:n:.
		$X -> #sharpHexaRational:n:.
		$; -> #sharpComment:n:.
		$< -> #sharpNonReadable:n:.
		"Specific to Smalltalk"
		$_ -> #sharpMethod:n:
	}
	do: [:assoc | SharpMacros add: assoc].

	CharacterNames := Dictionary new.
	{
		'newline' -> Character lf.
		'tab' -> Character tab.
		'linefeed' -> Character linefeed.
		'space' -> Character space.			
		'backspace' -> Character backspace.			
		'escape' -> Character escape.			
		'return' -> Character cr.			
		'rubout' -> Character delete.	
		'null' -> (Character codePoint: 0).				
	}
	do: [:assoc | CharacterNames add: assoc].

	"self initialize"
]

{ #category : #'as yet unclassified' }
LKReader class >> macros [

	^ Macros
]

{ #category : #'as yet unclassified' }
LKReader class >> sharpMacros [ 

	^ SharpMacros 
]

{ #category : #'as yet unclassified' }
LKReader class >> syntacticTypes [

	^ SyntacticTypes 
		
]

{ #category : #'as yet unclassified' }
LKReader class >> syntacticTypesAt: anInteger [

	anInteger > SyntacticTypes size ifTrue: [^ #constituent].

	^ SyntacticTypes at: anInteger 
		
]

{ #category : #macros }
LKReader >> backquote: aStream [

	^ #quasiquote inCons addLast: (self read: aStream)
]

{ #category : #macros }
LKReader >> closeList: aStream [

	^ self closeListMarker
]

{ #category : #macros }
LKReader >> closeListMarker [

	^ #'------(end------'
]

{ #category : #macros }
LKReader >> comment: aStream [

	| char |

	[char == Character lf  
		or: [char == Character cr] 
		or: [aStream atEnd]]
	whileFalse:
		[char := aStream next].

	^ nil
]

{ #category : #macros }
LKReader >> emptyListMarker [

	^ #'------()------'
]

{ #category : #'as yet unclassified' }
LKReader >> foundToken: aStream [

	"tells weither a token can be read from aStream"

	[aStream atEnd not 
		and: [(self class syntacticTypesAt: aStream peek asciiValue) == #whiteSpace]] 
	whileTrue: [aStream next].

	^ aStream atEnd not
]

{ #category : #'as yet unclassified' }
LKReader >> labels [

	^ labels ifNil: [labels := Dictionary new]
]

{ #category : #'as yet unclassified' }
LKReader >> lisp [

	^ lisp 
]

{ #category : #'as yet unclassified' }
LKReader >> lisp: aLisp [

	lisp := aLisp
]

{ #category : #macros }
LKReader >> openList: aStream [

	| list item lastCell |

	[item == self closeListMarker] whileFalse:
	[
		aStream atEnd ifTrue: [self error: 'open list'].
		item == #'.'
			ifTrue: "dotted pair notation" 
			[
				lastCell := (self read: aStream).
				"handle special case: [. , -> ,@] 
				for example`(a b . ,c) becomes `(a b ,@c)"
				(lastCell isConsCell and: [lastCell car == #unquote])
					ifTrue: [
								list := ((lastCell car: #'unquote-splicing') inCons cdr: list).
								lastCell := nil
								].
				"the form `(... . @, ...) is not allowed"
				(lastCell isConsCell and: [lastCell car == #'unquote-splicing'])
					ifTrue: [self error: 'inappropriate context for unquote-splicing'].
			]
			ifFalse: [list := (item inCons cdr: list)].
		item := self read: aStream.
	].

	(list ifNil: [^ self emptyListMarker]) cells do: [:cell |
		cell setcdr: lastCell.
		lastCell := cell].

	^ lastCell cdr ifNil: [self emptyListMarker]
]

{ #category : #macros }
LKReader >> quote: aStream [

	^ #quote inCons addLast: (self read: aStream)
]

{ #category : #'as yet unclassified' }
LKReader >> read: aStream [

	"this follows the algorithm described in
	Common Lisp the Language, 2nd edition, section 22.1.1"

	| x y token type ytype nme escflag caseMatters |

	token := self token void.
	token constants: lisp constantBindings.	
	type := #whiteSpace.
	nme := 0.
	escflag := false.
	caseMatters := lisp ifNil: [true] ifNotNil: [lisp ignoresCase not].
	
	[type == #whiteSpace] whileTrue: [
"step 1"
		aStream atEnd ifTrue: [^ LKIOPort eof].
		x := aStream next.
		type := self class syntacticTypesAt: (x asciiValue).
"step 4"
		(type == #terminatingMacro or: [type == #nonTerminatingMacro])
		ifTrue:	[	| val |
					val := self perform: (self class macros at: x) with: aStream.
					val == self emptyListMarker ifTrue: [^ nil].
					val ifNotNil: [^ val].
					type := #whiteSpace]].	
"step 5"
	type == #singleEscape 
		ifTrue: [token nextPut: aStream next. escflag := true].
"step 6"
	type == #multipleEscape ifTrue: [nme := nme + 1].
"step 7"	
	(nme even and: [type == #constituent]) 
		ifTrue: [token nextPut: (caseMatters ifFalse: [x asLowercase]
														ifTrue: [x])].
"step 8"
	[true] whileTrue: [	
		[nme even] whileTrue: [	
			y := aStream peek.
			(y isNil "e.g.   aStream atEnd"
				or: [(ytype := self class syntacticTypesAt: (y asciiValue)) 
						== #terminatingMacro or: [ytype == #whiteSpace]])
 				ifTrue: [(nme isZero & escflag not) 
							ifFalse: [^ token contents asSymbol]
							ifTrue: [^ token parsed]].
			aStream next. 
			(ytype == #constituent or: [ytype == #nonTerminatingMacro])
				ifTrue: [token nextPut: (caseMatters ifFalse: [y asLowercase]
														ifTrue: [y])].
			ytype == #singleEscape 
				ifTrue: [token nextPut: aStream next. escflag := true].
			ytype == #multipleEscape ifTrue: [nme := nme + 1]].
"step 9"
		[nme odd] whileTrue: [	
			aStream atEnd ifTrue: [self error: 'missing escape'].
			y := aStream next.
			ytype := self class syntacticTypesAt: (y asciiValue). 
			ytype == #multipleEscape 
				ifTrue: [nme := nme + 1]
				ifFalse: [ ytype == #singleEscape
								ifTrue: [token nextPut: aStream next. escflag := true]
								ifFalse: [token nextPut: y]]]].

]

{ #category : #'as yet unclassified' }
LKReader >> readString: aString [

	^ self read: (ReadStream on: aString)
]

{ #category : #'# macros' }
LKReader >> sharpArray: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpBalancedComment: aStream n: unused [

	| c nc depth |

	unused ifNotNil: [self error].

	depth := 0.

	[aStream atEnd] whileFalse:
	[
		c := aStream next.
		nc := aStream peek.
		(c == $# and: [nc == $|])
			ifTrue: [aStream next . depth := depth + 1].
		(c == $| and: [nc == $#])
			ifTrue: 
			[
				aStream next.
				depth isZero ifTrue: [^ nil].
				depth := depth - 1
			].
	].

	self error
]

{ #category : #'# macros' }
LKReader >> sharpBinaryRational: aStream n: unused [

	unused ifNotNil: [self error].

	^ Number readFrom: (self read: aStream) asString base: 2
]

{ #category : #'# macros' }
LKReader >> sharpBitVector: aStream n: unused [

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpCharacter: aStream n: unused [

	| char |

	unused ifNotNil: [self error].

	aStream skip: -1.
	char := (self read: aStream) asString.
	char size = 1 ifTrue: [^ char first].

	^ self class characterNames at: char asLowercase
]

{ #category : #'# macros' }
LKReader >> sharpComment: aStream n: unused [

	unused ifNotNil: [self error].

	self read: aStream.
	^ nil
]

{ #category : #'# macros' }
LKReader >> sharpComplexNumber: aStream n: unused [

	| cons |

	unused ifNotNil: [self error].

	cons := self read: aStream.
	^ Complex real: cons car imaginary: cons cadr
]

{ #category : #'# macros' }
LKReader >> sharpFunction: aStream n: unused [

	unused ifNotNil: [self error].

	^ #function inCons addLast: (self read: aStream)
]

{ #category : #'# macros' }
LKReader >> sharpHexaRational: aStream n: unused [

	| hn c nc |
	
	unused ifNotNil: [self error].

	nc := #($A $B $C $D $E $F).
	hn := WriteStream on: ''.

	[(c := aStream peek) notNil
		and: [c isDigit or: [nc identityIncludes: c asUppercase]]]
	whileTrue: [hn nextPut: aStream next].
	
	^ Number readFrom: hn contents asUppercase base: 16
]

{ #category : #'# macros' }
LKReader >> sharpLabel: aStream n: aNumber [

	| v |

	aNumber ifNil: [self error: 'incorrect label syntax'].

	v := self read: aStream.
	
	(self labels includesKey: aNumber)
		ifFalse: [self labels at: aNumber put: v]
		ifTrue: [(self labels at: aNumber) becomeForward: v].

	^ self labels at: aNumber
]

{ #category : #'# macros' }
LKReader >> sharpLabelReference: aStream n: aNumber [ 

	"if the reference is undefined at this point, let it be a dummy object to be replaced in place with the correct one later on (see the #becomeForward: call in #sharpLabel:n:"

	^ self labels at: aNumber 
			ifAbsent: [self labels at: aNumber put: {#badRef . aNumber}]
]

{ #category : #'# macros' }
LKReader >> sharpLoadTimeEvaluation: aStream n: unused [

	unused ifNotNil: [self error].

	^ lisp eval: (self read: aStream) inCons
]

{ #category : #macros }
LKReader >> sharpMacro: aStream [

	| number key |

	[aStream peek isDigit] whileTrue:
		[number := ((number ifNil: [0]) * 10) + (aStream next asciiValue - 48)].

	^ self perform: (key := self class sharpMacros at: aStream next) 
		withArguments: {aStream . number}


]

{ #category : #'# macros' }
LKReader >> sharpMethod: aStream n: unused [

	unused ifNotNil: [self error].

	^ #send1
]

{ #category : #'# macros' }
LKReader >> sharpNonReadable: aStream n: unused [

	unused ifNotNil: [self error].

	^ LKNonReadableObject new 
		printedRepresentation: (aStream upTo: $>) contents
]

{ #category : #'# macros' }
LKReader >> sharpOctalRational: aStream n: unused [

	unused ifNotNil: [self error].

	^ Number readFrom: (self read: aStream) asString base: 8
]

{ #category : #'# macros' }
LKReader >> sharpPathName: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpRadixNRational: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpReadTimeEvaluation: aStream n: unused [

	| sexp |

	unused ifNotNil: [self error].

	^ lisp eval: (sexp := self read: aStream) inCons

]

{ #category : #'# macros' }
LKReader >> sharpReadTimeUnless: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpReadTimeWhen: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpStructure: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpUninternedSymbol: aStream n: unused [

	unused ifNotNil: [self error].

	self notYetImplemented
]

{ #category : #'# macros' }
LKReader >> sharpVector: aStream n: aNumber [

	| v |

	aStream skip: -1.
	v := (self read: aStream) topForms.

	aNumber ifNotNil: 
	[
		v size > aNumber ifTrue: [self error: 'incorrect vector format'].
		v size < aNumber ifTrue:
		[  | nv |
			nv := Array new: aNumber withAll: v last.
			1 to: v size - 1 do: [:n |
				nv at: n put: (v at: n)].
			v := nv
		]
	].

	^ v.

	
]

{ #category : #macros }
LKReader >> string: aStream [

	| s |
	
	s := String streamContents: [:str |
		| c |
		[c == $"] whileFalse:
		[
			c := aStream next.
			(self class syntacticTypesAt: c asciiValue) == #singleEscape
				ifTrue: [str nextPut: c; nextPut: aStream next]
				ifFalse: [c == $" ifFalse: [str nextPut: c]]
		]].

	^ (lisp ifNil: [^s]) class stringRepresentedBy: s
		
			
	
]

{ #category : #'as yet unclassified' }
LKReader >> token [

	^ LKToken
]

{ #category : #macros }
LKReader >> unquote: aStream [

	aStream peek == $@
		ifTrue: 
		[
			aStream next.
			^ #'unquote-splicing' inCons addLast: (self read: aStream)
		].

	^ #unquote inCons addLast: (self read: aStream)
]
