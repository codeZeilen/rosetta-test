"
a Lisp-2 environment frame: provides distinct bindings for functions and values
"
Class {
	#name : #LK2Environment,
	#superclass : #LK1Environment,
	#instVars : [
		'symbolFunctions'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LK2Environment >> addSymbolFunction: aBinding [

	symbolFunctions add: aBinding
]

{ #category : #'as yet unclassified' }
LK2Environment >> allFboundSymbols [

	| env |

	env := self.

	^ (Array streamContents: [:str |
			[env notNil] whileTrue: [
				str nextPutAll: env symbolFunctions keys.
				env := env parent]]) 
		sort 
]

{ #category : #'as yet unclassified' }
LK2Environment >> initialize [ 

	super initialize.
	symbolFunctions := IdentityDictionary new.

]

{ #category : #'as yet unclassified' }
LK2Environment >> removeSymbolFunction: aSymbol [

	symbolFunctions removeKey: aSymbol
]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolFunction: aSymbol [

	"look-up for the function bound to aSymbol"

	 ^ self symbolFunctions at: aSymbol 
		ifAbsent: [upperBindings symbolFunction: aSymbol]
	
]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolFunction: aSymbol ifNone: aBlock [

	^ self symbolFunctions at: aSymbol 
		ifAbsent: [(upperBindings ifNil: [^ aBlock value])
						symbolFunction: aSymbol ifNone: aBlock]

]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolFunctions [ 

	^ symbolFunctions
]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolFunctionsDictionaryFor: aSymbol [

	"look-up for the dictionary in which a function binding for aSymbol should be stored"

	((self symbolFunctions includesKey: aSymbol) 
		or: [upperBindings isNil])
		ifTrue: [^ self symbolFunctions].

	^ upperBindings symbolFunctionsDictionaryFor: aSymbol

]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolPlists [

	^ symbolPlists ifNil: [symbolPlists := IdentityDictionary new]
]

{ #category : #'as yet unclassified' }
LK2Environment >> symbolPlists: aDictionary [

	symbolPlists := aDictionary
]
