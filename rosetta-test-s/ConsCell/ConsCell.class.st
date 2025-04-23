"
A Lisp cons cell, or a Prolog list

	It can be converted into an Array:
	(ConsCell car: 1 cdr: (ConsCell car: 2 cdr: nil)) arrayForm    ""printIt""

	... or not:
	(ConsCell car: 1 cdr: 2) arrayForm     ""doIt""

	It can be created from an Array:
	#('hello' 'world') asCons        ""printIt""





"
Class {
	#name : #ConsCell,
	#superclass : #Object,
	#instVars : [
		'car',
		'cdr'
	],
	#category : #ConsCell
}

{ #category : #'instance creation' }
ConsCell class >> caar: anObject [

	^ self car: (self car: anObject) 
]

{ #category : #'instance creation' }
ConsCell class >> car: anObject [

	^ self new car: anObject 
]

{ #category : #'instance creation' }
ConsCell class >> car: anObject cdr: bObject [

	^ self new car: anObject; cdr: bObject
]

{ #category : #'instance creation' }
ConsCell class >> fromList: anArray [

	| cons |

	anArray size = 0 ifTrue: [^ nil].
	anArray size = 1 ifTrue: [^ self car: (anArray at: 1)].
	anArray size = 2 ifTrue: 
		[^ self car: (anArray at: 1) cdr: (self car: (anArray at: 2))].

	anArray size to: 1 by: -1 do: [:index | 
			cons := self car: (anArray at: index) cdr: cons].
		
	^ cons
]

{ #category : #testing }
ConsCell >> = aConsCell [

	self isCircular ifTrue: 
		[^ self withCut = aConsCell withCut].

	self species = aConsCell species
		ifTrue: [^ car = aConsCell car and: [cdr = aConsCell cdr]]
		ifFalse: [^false]
]

{ #category : #'list operations' }
ConsCell >> addLast: anObject [

	self lastCell cdr: (self tailClass car: anObject)
]

{ #category : #'list operations' }
ConsCell >> append2: aConsCell [

	| a |

	a := aConsCell isConsCell ifTrue: [aConsCell listCopy] ifFalse: [aConsCell].
	self append: a
	
]

{ #category : #'list operations' }
ConsCell >> append: aConsCell [

	self lastCell cdr: aConsCell
	
]

{ #category : #conversion }
ConsCell >> arrayForm [

	^ Array streamContents: [:stream | self inArray: stream]


]

{ #category : #accessing }
ConsCell >> caar [

	^ car car
]

{ #category : #accessing }
ConsCell >> cadr [

	^ cdr car
]

{ #category : #accessing }
ConsCell >> car [

	^ car
]

{ #category : #accessing }
ConsCell >> car: anObject [

	car := anObject
]

{ #category : #accessing }
ConsCell >> cdar [

	^ car cdr
]

{ #category : #accessing }
ConsCell >> cddr [

	^ cdr cdr
]

{ #category : #accessing }
ConsCell >> cdr [

	^ cdr
]

{ #category : #accessing }
ConsCell >> cdr: anObject [

	cdr := anObject
]

{ #category : #'list operations' }
ConsCell >> cells [

	^ Array streamContents: [:str | 
		self cellsDo: [:cell | str nextPut: cell]]
]

{ #category : #'list operations' }
ConsCell >> cellsDo: aBlock [

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [aBlock value: cell. cell := cell cdr]


]

{ #category : #'list operations' }
ConsCell >> collect: aBlock [

	^ self class car: (aBlock value: car)
		cdr: (cdr isConsCell ifTrue: [cdr collect: aBlock] ifFalse: [cdr])
]

{ #category : #testing }
ConsCell >> cycles [

	^ self storeCycles: IdentityDictionary new with: IdentitySet new

]

{ #category : #'list operations' }
ConsCell >> detect: aBlock ifNone: bBlock [

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [
		(aBlock value: cell car) ifTrue: [^ cell car]. 
		cell := cell cdr].

	^ bBlock value

]

{ #category : #'list operations' }
ConsCell >> do: aBlock [

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [aBlock value: cell car. cell := cell cdr]


]

{ #category : #'list operations' }
ConsCell >> doWithCdr: aBlock [

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [aBlock value: cell car value: (cell := cell cdr)]


]

{ #category : #'list operations' }
ConsCell >> doWithCell: aBlock [

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [aBlock value: cell car value: cell . cell := cell cdr]

]

{ #category : #accessing }
ConsCell >> first [

	^ car
]

{ #category : #printing }
ConsCell >> fullPrintStringForLisp: aLisp [

	^ String streamContents: [:s | self printOn: s forLisp: aLisp]

]

{ #category : #accessing }
ConsCell >> get: anObject [

	"low-level property list support"

	| cell |
	cell := self.
	[cell isConsCell] whileTrue: [
			cell car == anObject ifTrue: [^ cell cadr].
			cell := cell cdr cdr].
	^ nil

	
]

{ #category : #testing }
ConsCell >> hash [
	"Hash is reimplemented because = is implemented."

	self isCircular ifTrue: [^ self withCut hash].

	^ car hash bitXor: cdr hash.
]

{ #category : #conversion }
ConsCell >> inArray: aStream [

	| k |

	k := car isConsCell ifTrue: [car arrayForm] ifFalse: [car].
	k ifNil: [k := #()].

	cdr isNil ifTrue: [^ aStream nextPut: k].
	cdr isConsCell ifTrue: [^ aStream nextPut: k; nextPutAll: cdr arrayForm].
	self error: 'Not a list'

]

{ #category : #testing }
ConsCell >> isCircular [

	^ self isCircular: IdentitySet new

]

{ #category : #testing }
ConsCell >> isCircular: anIdentitySet [

	cdr isConsCell ifFalse: [^ false].
	(anIdentitySet includes: cdr) ifTrue: [^ true].

	anIdentitySet add: self.
	^ cdr isCircular: anIdentitySet 
]

{ #category : #testing }
ConsCell >> isConsCell [

	^ true
]

{ #category : #testing }
ConsCell >> isList [

	^ self isList: (IdentitySet with: self)
]

{ #category : #testing }
ConsCell >> isList: anIdentitySet [

	(anIdentitySet includes: cdr) ifTrue: [^ false].
	anIdentitySet add: self.
	^ cdr isNil or: [cdr isConsCell and: [cdr isList: anIdentitySet]]
]

{ #category : #'procedure protocol' }
ConsCell >> isMacro [

	^ car == #macro
]

{ #category : #accessing }
ConsCell >> last [

	^ cdr ifNil: [self] ifNotNil: [cdr last]
]

{ #category : #'list operations' }
ConsCell >> lastCdr: anObject [

	self lastCell cdr: anObject
	
]

{ #category : #'list operations' }
ConsCell >> lastCell [

	| cell |
	cell := self.
	[cell cdr notNil] whileTrue: [cell := cell cdr].
	^ cell 
	
]

{ #category : #testing }
ConsCell >> length [

	^ self length: 1 with: IdentitySet new
	
]

{ #category : #testing }
ConsCell >> length: aNumber with: anIdentitySet [ 

	cdr isNil ifTrue: [^ aNumber].
	cdr isConsCell ifFalse: [self error: 'not a list'].
	(anIdentitySet includes: cdr) ifTrue: [^ Float infinity].

	anIdentitySet add: self.
	^ cdr length: aNumber + 1 with: anIdentitySet 
]

{ #category : #conversion }
ConsCell >> listCopy [

	^ self copy setcdr: (cdr isConsCell ifFalse: [cdr] ifTrue: [cdr listCopy])

]

{ #category : #accessing }
ConsCell >> nth: n [

	n isZero ifTrue: [^ car].
	cdr ifNil: [^ nil].
	n = 1 ifTrue: [^ cdr car].
	^ cdr nth: n - 1
]

{ #category : #accessing }
ConsCell >> nth: n ifAbsent: aBlock [

	n isZero ifTrue: [^ car].
	cdr ifNil: [^ aBlock value].
	n = 1 ifTrue: [^ cdr car].
	^ cdr nth: n - 1ifAbsent: aBlock
]

{ #category : #accessing }
ConsCell >> nthCell: n [

	n isZero ifTrue: [^ self].
	n = 1 ifTrue: [^ cdr].
	^ cdr nthCell: n - 1
]

{ #category : #accessing }
ConsCell >> nthCell: n ifAbsent: aBlock [

	n isZero ifTrue: [^ self].
	n = 1 ifTrue: [^ cdr ifNil: [aBlock value]].
	^ cdr nthCell: n - 1 ifAbsent: aBlock
]

{ #category : #accessing }
ConsCell >> nthcdr: n [

	n isZero ifTrue: [^ self].
	n = 1 ifTrue: [^ cdr].
	^ cdr nthcdr: n - 1
]

{ #category : #accessing }
ConsCell >> nthcdr: n ifAbsent: aBlock [

	n isZero ifTrue: [^ self].
	cdr ifNil: [n = 1 ifTrue: [^ nil] ifFalse: [aBlock value]].
	n = 1 ifTrue: [^ cdr].
	^ cdr nthcdr: n - 1ifAbsent: aBlock
]

{ #category : #printing }
ConsCell >> printOn: aStream [

	self printOn: aStream forLisp: nil

]

{ #category : #printing }
ConsCell >> printOn: aStream depth: aNumber forLisp: aLisp level: cpl maxLevel: mpl length: len maxLength: mlen done: anIdentitySet cycles: anIdentityDictionary [

	"the so-called 'level' controls the depth of nesting cons cells
	the 'length' controls the numbers of elements in a list to be printed
both refers to standard Common Lisp variables: respectively *print-level* and *print-length*

	see Common Lisp the Language,  2nd edition, chapter 22.1.6"

	| depth |

	depth := aNumber.

	(anIdentityDictionary identityIncludesKey: self)
	ifTrue: 
	[
		aStream nextPut: $#; 
				nextPutAll: (anIdentityDictionary at: self) asString; 
				nextPut: $=.
		anIdentitySet add: self.
	].

	depth isZero ifTrue: [aStream nextPut: $(].

	(car isConsCell | car isArray) ifTrue: 
	[
		(anIdentitySet includes: car) 
		ifTrue: 
		[
			aStream nextPut: $#; 
					nextPutAll: (anIdentityDictionary at: car) asString; 
					nextPut: $#
		]
		ifFalse:
		[
			(mpl notNil and: [cpl >= mpl]) 
				ifTrue: [aStream nextPut: $#]
				ifFalse: 
				[
					car printOn: aStream depth: 0 forLisp: aLisp 
						level: cpl + 1 maxLevel: mpl length: mlen maxLength: mlen
						done: anIdentitySet cycles: anIdentityDictionary
				]
		]
	]
	ifFalse: [car printOn: aStream depth: depth + 1 forLisp: aLisp 
						level: cpl + 1 maxLevel: mpl length: mlen maxLength: mlen
						done: anIdentitySet cycles: anIdentityDictionary].

	cdr ifNil: [^ aStream nextPut: $)].

	aStream space.

	(len notNil and: [len = 1]) ifTrue: [^ aStream nextPutAll: '...)'].

	(cdr isConsCell
		and: [(anIdentitySet includes: cdr) not]
		and: [(anIdentityDictionary identityIncludesKey: cdr) not]) ifTrue: 
	[
		^ cdr printOn: aStream depth: depth + 1 forLisp: aLisp 
			level: cpl maxLevel: mpl 
			length: (len ifNotNil: [len - 1]) maxLength: mlen
			done: anIdentitySet cycles: anIdentityDictionary
	].

	aStream nextPut: $.; space. 
	(anIdentitySet includes: cdr) 		
	ifTrue: 
	[
		aStream nextPut: $#; 
			nextPutAll: (anIdentityDictionary at: cdr) asString; 
			nextPut: $#
	]
	ifFalse: 
	[
		cdr printOn: aStream depth: 0 forLisp: aLisp 
			level: cpl maxLevel: mpl
			length: (len ifNotNil: [len - 1]) maxLength: mlen
		 	done: anIdentitySet cycles: anIdentityDictionary
	].
	aStream nextPut: $)

]

{ #category : #printing }
ConsCell >> printOn: aStream forLisp: aLisp [

	| mlen mlev |

	mlen := aLisp ifNil: [nil] ifNotNil: [aLisp printLength].
	mlev := aLisp ifNil: [nil] ifNotNil: [aLisp printLevel].

	(aLisp isNil or: [aLisp printCircle == aLisp trueValue])
	ifTrue:
	[
		^ self printOn: aStream depth: 0 forLisp: aLisp 
			level: 1 maxLevel: mlev length: mlen maxLength: mlen 
			done: IdentitySet new cycles: self cycles
	].

	self printOn: aStream depth: 0 forLisp: aLisp 
		level: 1 maxLevel: mlev length: mlen maxLength: mlen 
		done: IdentitySet new cycles: IdentityDictionary new

]

{ #category : #'list operations' }
ConsCell >> safeDo: aBlock [

	^ self safeDo: aBlock done: IdentitySet new
]

{ #category : #'list operations' }
ConsCell >> safeDo: aBlock done: anIdentitySet [

	(anIdentitySet includes: car)
		ifFalse: [aBlock value: self car. anIdentitySet add: car].

	((anIdentitySet includes: cdr) 
		or: [cdr isConsCell not]) ifTrue: [^ self].

	cdr safeDo: aBlock done: anIdentitySet


]

{ #category : #accessing }
ConsCell >> safeLength [

	cdr isNil ifTrue: [^ 1].
	cdr isConsCell ifFalse: [^ 2].
	^ cdr safeLength + 1

]

{ #category : #conversion }
ConsCell >> safeStoreTopFormsIn: aStream [

	aStream nextPut: car.
	cdr isConsCell ifTrue: [cdr safeStoreTopFormsIn: aStream] 


]

{ #category : #conversion }
ConsCell >> safeTopForms [

	cdr ifNil: [^ {car}].
	cdr isConsCell ifTrue:
	[
		cdr cdr ifNil: [^ {car . cdr car}].
		cdr cdr isConsCell ifTrue:
			[cdr cdr cdr ifNil: [^ {car . cdr car . cdr cdr car}]]
	].

	^ Array streamContents: [:stream | self safeStoreTopFormsIn: stream]


]

{ #category : #accessing }
ConsCell >> second [

	^ cdr car
]

{ #category : #accessing }
ConsCell >> setcar: anObject [

	self car: anObject
]

{ #category : #accessing }
ConsCell >> setcdr: anObject [

	self cdr: anObject
]

{ #category : #testing }
ConsCell >> storeCycles: anIdentityDictionary with: anIdentitySet [

	(anIdentitySet includes: self)
	ifTrue: 
	[
		(anIdentityDictionary identityIncludesKey: self)
			ifFalse: [anIdentityDictionary add: self -> (anIdentityDictionary size + 1)].
		^ anIdentityDictionary
	]. 
	anIdentitySet add: self.

	(car isConsCell | car isArray) ifTrue: 
		[car storeCycles: anIdentityDictionary with: anIdentitySet].
	(cdr isConsCell | cdr isArray) ifTrue: 
		[cdr storeCycles: anIdentityDictionary with: anIdentitySet].

	^ anIdentityDictionary
]

{ #category : #printing }
ConsCell >> storeOn: aStream [

	aStream nextPutAll: '(ConsCell car: '.
	car storeOn: aStream.
	aStream nextPutAll: ' cdr: '.
	cdr storeOn: aStream.
	aStream nextPut: $)
]

{ #category : #conversion }
ConsCell >> storeTopFormsIn: aStream [

	aStream nextPut: car.
	cdr ifNil: [^ self].
	cdr storeTopFormsIn: aStream 


]

{ #category : #conversion }
ConsCell >> tailClass [

	^ self class
]

{ #category : #accessing }
ConsCell >> third [

	^ cdr cdr car
]

{ #category : #conversion }
ConsCell >> topForms [

	cdr ifNil: [^ {car}].
	cdr cdr ifNil: [^ {car . cdr car}].
	cdr cdr cdr ifNil: [^ {car . cdr car . cdr cdr car}].

	^ Array streamContents: [:stream | self storeTopFormsIn: stream]


]

{ #category : #'tree operations' }
ConsCell >> treeDo: aBlock [

	aBlock value: self.
	car isConsCell ifTrue: [car treeDo: aBlock].
	cdr isConsCell ifTrue: [cdr treeDo: aBlock]


]

{ #category : #'list operations' }
ConsCell >> with: aConsCell collect: aBlock [

	^ self class car: (aBlock value: car value: aConsCell car)
		cdr: ((cdr isConsCell and: [aConsCell cdr isConsCell])
					ifTrue: [cdr with: aConsCell cdr collect: aBlock] ifFalse: [cdr])
]

{ #category : #testing }
ConsCell >> withCut [

	| cons c2 |
	cons := self veryDeepCopy.
	c2 := cons cdr.
	cons cdr: nil.		
	^ c2
]
