Class {
	#name : #LKSymbolsTracer,
	#superclass : #LKTracer,
	#instVars : [
		'symbols'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> initialize [

	symbols := #()
]

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> subLisp: aForm from: aLisp [
"
	aLisp displayStream 
		nextPut: $\;
		nextPutAll: (aLisp depth + 1) asString ; tab;
		nextPutAll: (aForm printStringForLisp: aLisp limitedTo: 50); cr.
"
]

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> symbols: anArray [

	symbols := anArray
]

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> symbolsValuesAdded: anAssociation in: aLisp [

	(symbols includes: anAssociation key)
		ifTrue: [
			aLisp standardOutput stream nextPutAll: 'BIND'; tab; 
				nextPutAll: anAssociation key;
				nextPutAll: ' -> ';
				nextPutAll: (anAssociation value printStringForLisp: aLisp limitedTo: 100); cr.
			aLisp standardOutput endEntry]

]

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> trace: anObject in: aLisp [

	| symbs str |

	(anObject isConsCell 
		and: [(symbs := symbols intersection: anObject safeTopForms) notEmpty])
		ifFalse: [^ anObject].

	str := aLisp standardOutput stream.

	str	nextPutAll: aLisp depth asString ; tab;
		nextPutAll: ((aLisp upperForm ifNil: ['<top>']) printStringForLisp: aLisp limitedTo: 100); cr.
	str tab; nextPutAll: (anObject printStringForLisp: aLisp limitedTo: 100); cr.
	symbs do: [:s |
		str tab; tab; nextPutAll: s, ' => ';
			nextPutAll: (aLisp symbolValue: s ifNone: ['<unbound>']) asString;
			cr].
	aLisp standardOutput endEntry.
	^ anObject

	


]

{ #category : #'as yet unclassified' }
LKSymbolsTracer >> traceResult: anObject for: bObject in: aLisp [
]
