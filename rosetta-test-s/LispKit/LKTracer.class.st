Class {
	#name : #LKTracer,
	#superclass : #LKMonitor,
	#instVars : [
		'depth'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKTracer >> depth [ 
	
	^ depth ifNil: [0]
]

{ #category : #'as yet unclassified' }
LKTracer >> goTopLevel [

	depth := 0
]

{ #category : #'as yet unclassified' }
LKTracer >> symbolsValuesAdded: anAssociation in: aLisp [

	| str |

	str := aLisp standardOutput stream.

	self tabulate: str to: self depth + 1.

	str nextPutAll: 'BIND ';
		nextPutAll: anAssociation key;
		nextPutAll: ' -> ';
		nextPutAll: (anAssociation value printStringForLisp: aLisp limitedTo: 100); cr. 
	aLisp standardOutput endEntry

]

{ #category : #'as yet unclassified' }
LKTracer >> tabulate: aStream to: d [

	| nl |

	nl := ((d - 1) / 30) floor.

	nl isZero ifFalse:
		[aStream nextPutAll: nl asString, '>'; space].

	((d - 1) \\ 30) timesRepeat: [aStream nextPut: $| ; space].

]

{ #category : #'as yet unclassified' }
LKTracer >> trace: anObject in: aLisp [

	| str | 

	depth := self depth + 1.

	(anObject isSymbol or: [anObject isConsCell ])
		ifFalse: [^ anObject].

	str := aLisp standardOutput stream.
"	str	nextPutAll: aLisp depth asString."

	self tabulate: str to: depth.

	str nextPutAll: (anObject printStringForLisp: aLisp limitedTo: 100); cr.
	aLisp standardOutput endEntry.

	^ anObject
]

{ #category : #'as yet unclassified' }
LKTracer >> traceResult: anObject for: bObject in: aLisp [

	| str | 

	str := aLisp standardOutput stream.

	depth := self depth - 1.
	depth < 0 ifTrue: [^ self].

	(bObject isSymbol or: [bObject isConsCell ])
		ifFalse: [^ self].

	self tabulate: str to: depth + 1.

	str	nextPutAll: '=> ';
		nextPutAll: (anObject printStringForLisp: aLisp limitedTo: 100); cr.

	aLisp standardOutput endEntry

]
