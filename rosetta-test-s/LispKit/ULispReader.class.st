"
code reader for ULisp (handles #f and #t)

"
Class {
	#name : #ULispReader,
	#superclass : #LKReader,
	#category : #'LispKit-Dialects'
}

{ #category : #'as yet unclassified' }
ULispReader class >> initialize [

	super initialize.

	{
		$f -> #sharpFalse:n:.
		$t -> #sharpTrue:n:.
		$F -> #sharpFalse:n:.
		$T -> #sharpTrue:n:.
		$d -> #sharpReadNumber:n:.
		$i -> #sharpReadInexactNumber:n:
	}
	do: [:assoc | SharpMacros add: assoc].

	" [..] for PLT Scheme compatibility:"

	SyntacticTypes 
		atAll: (#($[ $]) collect: [:c | c asciiValue]) 
		put: #terminatingMacro.

	{
		$[ -> #openList:.
		$] -> #closeList:.
	}
	do: [:assoc | Macros add: assoc].

	"self initialize"
]

{ #category : #'as yet unclassified' }
ULispReader >> sharpFalse: aStream n: usused [

	^ lisp falseValue
]

{ #category : #'as yet unclassified' }
ULispReader >> sharpReadInexactNumber: aStream n: unused [

	| num |

	unused ifNotNil: [self error].

	num := self read: aStream.
	(num isNumber or: [num isComplex]) 
		ifFalse: [lisp lispError: 'bad syntax for number'].

	num isComplex ifTrue: 
		[^ Complex real: num real asFloat imaginary: num imaginary asFloat].

	^ num asFloat
]

{ #category : #'as yet unclassified' }
ULispReader >> sharpReadNumber: aStream n: unused [

	| num |

	unused ifNotNil: [self error].

	num := self read: aStream.
	(num isNumber or: [num isComplex]) 
		ifFalse: [lisp lispError: 'bad syntax for number'].
	^ num
]

{ #category : #'as yet unclassified' }
ULispReader >> sharpTrue: aStream n: usused [

	^ lisp trueValue
]

{ #category : #'as yet unclassified' }
ULispReader >> sharpVector: aStream n: aNumber [

	| v |

	aStream skip: -1.
	v := (self read: aStream) topForms.

	aNumber ifNil: [^ v]. 

	v size > aNumber ifTrue: [self error: 'incorrect vector format'].
	v size < aNumber ifTrue:
	[  | nv |
		nv := Array new: aNumber withAll: v last.
		1 to: v size - 1 do: [:n |
			nv at: n put: (v at: n)].
		^ nv
	]

]

{ #category : #'as yet unclassified' }
ULispReader >> token [

	^ ULispToken
]
