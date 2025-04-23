"
a Lisp-1 environment frame

defines symbol bindings, points to its parent frame (method #parent).
property lists are also stored here.

to interactively inspect an environment, send it #inspectWith: with a dialect class as argument.

"
Class {
	#name : #LK1Environment,
	#superclass : #Object,
	#instVars : [
		'upperBindings',
		'symbolPlists',
		'symbolValues'
	],
	#category : #LispKit
}

{ #category : #redirection }
LK1Environment >> addSymbolFunction: aBinding [

	self addSymbolValue: aBinding
]

{ #category : #'as yet unclassified' }
LK1Environment >> addSymbolValue: aBinding [

	symbolValues add: aBinding
]

{ #category : #'as yet unclassified' }
LK1Environment >> allBoundSymbols [

	| env |

	env := self.

	^ (Array streamContents: [:str |
			[env notNil] whileTrue: [
				str nextPutAll: env symbolValues keys.
				env := env parent]]) 
		sort 
]

{ #category : #'as yet unclassified' }
LK1Environment >> bindsSymbol: aSymbol [

	 ^ (self symbolBinding: aSymbol) notNil
]

{ #category : #'as yet unclassified' }
LK1Environment >> depth [

	upperBindings ifNil: [^ 0].
	^ upperBindings depth + 1
]

{ #category : #'as yet unclassified' }
LK1Environment >> initialize [ 

	super initialize.
	symbolValues := IdentityDictionary new.
]

{ #category : #inspection }
LK1Environment >> inspectWith: aLispClass [

	(aLispClass openNew) lispEnvironment self newChild
]

{ #category : #'as yet unclassified' }
LK1Environment >> newChild [

	^ self class new parent: self; symbolPlists: self symbolPlists
]

{ #category : #experimental }
LK1Environment >> nthParent: aNumber [

	| env |

	env := self.
	aNumber isZero ifTrue: [^ env].
	1 to: aNumber do: [:i | env := env parent].
	^ env 
]

{ #category : #'as yet unclassified' }
LK1Environment >> parent [

	^ upperBindings
]

{ #category : #'as yet unclassified' }
LK1Environment >> parent: someLKBindings [

	upperBindings := someLKBindings
]

{ #category : #'as yet unclassified' }
LK1Environment >> printOn: aStream forLisp: aLisp [ 

	| ds |

	ds := self depth.
	ds := ds isZero ifTrue: ['top'] ifFalse: [ds asString].

	aStream nextPutAll: '#<env.frame (', ds, ')>' 
]

{ #category : #experimental }
LK1Environment >> relativeLookUpValue: aSymbol [

	| env denv |

	denv := 0.
	env := self.

	[env bindsSymbol: aSymbol] whileFalse: [
		denv := denv + 1.
		env := env parent.
		env ifNil: [self error: 'no binding found for ', aSymbol]].

	^ env -> denv
]

{ #category : #'as yet unclassified' }
LK1Environment >> removeSymbolValue: aSymbol [

	symbolValues removeKey: aSymbol
]

{ #category : #'as yet unclassified' }
LK1Environment >> scopedSymbolBinding: aSymbol [

	 ^ (self symbolBinding: aSymbol) 
		ifNil: [(self parent ifNil: [^ nil]) scopedSymbolBinding: aSymbol]
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolBinding: aSymbol [

	 ^ self symbolValues array at: (self symbolValues scanFor: aSymbol)
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolPlists [

	^ symbolPlists ifNil: [symbolPlists := IdentityDictionary new]
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolPlists: aDictionary [

	symbolPlists := aDictionary
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValue: aSymbol [

	"look-up for the value bound to aSymbol"

	 ^ self symbolValues at: aSymbol 
		ifAbsent: [upperBindings symbolValue: aSymbol]
	
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValue: aSymbol ifNone: aBlock [

	"look-up for the value bound to aSymbol. if none found, evaluate aBlock"

	| b |
	b := self symbolBinding: aSymbol.
	b ifNotNil: [^ b value].
	^ (self parent ifNil: [^ aBlock value]) symbolValue: aSymbol ifNone: aBlock

]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValueBinding: aSymbol [

	| b |

	(b := self symbolBinding: aSymbol) ifNotNil: [^ b].

	^ (upperBindings ifNil: [^ nil]) symbolValueBinding: aSymbol
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValues [

	^ symbolValues
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValuesDictionaryFor: aSymbol [

	"look-up for the dictionary in which a value binding for aSymbol should be stored"

	((self symbolValues includesKey: aSymbol) 
		or: [upperBindings isNil])
		ifTrue: [^ self symbolValues].

	^ upperBindings symbolValuesDictionaryFor: aSymbol
]

{ #category : #'as yet unclassified' }
LK1Environment >> symbolValuesDictionaryFor: aSymbol ifNone: aBlock [

	(self bindsSymbol: aSymbol) ifTrue: [^ self symbolValues].
	^ (upperBindings ifNil: [^ aBlock value]) 
			symbolValuesDictionaryFor: aSymbol ifNone: aBlock
]
