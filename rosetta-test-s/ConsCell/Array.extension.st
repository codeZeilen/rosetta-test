Extension { #name : #Array }

{ #category : #'*ConsCell' }
Array >> arrayForm [

	^ self
]

{ #category : #'*ConsCell' }
Array >> asCons [

	| cons |

	self size = 0 ifTrue: [^ nil].
	self size = 1 ifTrue: [^ ConsCell car: (self at: 1) asCons].

	self reverseDo: [:elt | 
		cons := ConsCell car: elt asCons cdr: cons].
	^ cons


]

{ #category : #'*ConsCell' }
Array >> asConsList [

	^ ConsCell fromList: self
]

{ #category : #'*ConsCell' }
Array >> asCyclicCons [

	^ self asCons in: [:cc | cc append: cc]


]

{ #category : #'*ConsCell' }
Array >> cycles [

	^ self storeCycles: IdentityDictionary new with: IdentitySet new

]

{ #category : #'*ConsCell' }
Array >> printOn: aStream depth: aNumber forLisp: aLisp level: cpl maxLevel: mpl length: len maxLength: mlen done: anIdentitySet cycles: anIdentityDictionary [

	(anIdentityDictionary keys includes: self)
	ifTrue: 
	[
		aStream nextPut: $#; 
				nextPutAll: (anIdentityDictionary at: self) asString; 
				nextPut: $=.
		anIdentitySet add: self.
	].

	aStream nextPutAll: (aLisp ifNil: ['#(']
		ifNotNil: [aLisp class vectorOpeningString]).
	self do: [:element | 
		(anIdentitySet includes: element)
		ifTrue:
		[
			aStream nextPut: $#; 
				nextPutAll: (anIdentityDictionary at: element) asString; 
				nextPut: $#
		]
		ifFalse:
		[
			element printOn: aStream depth: aNumber forLisp: aLisp 
				level: cpl maxLevel: mpl length: len maxLength: mlen 
				done: anIdentitySet cycles: anIdentityDictionary
		].
		aStream space
	].
	self ifNotEmpty: [aStream skip: -1].
	aStream nextPut: (aLisp ifNil: [$)]
		ifNotNil: [aLisp class vectorClosingChar])
]

{ #category : #'*ConsCell' }
Array >> printOn: aStream forLisp: aLisp [

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

{ #category : #'*ConsCell' }
Array >> storeCycles: anIdentityDictionary with: anIdentitySet [

	(anIdentitySet includes: self)
	ifTrue: 
	[
		(anIdentityDictionary keys includes: self)
			ifFalse: [anIdentityDictionary add: self -> (anIdentityDictionary size + 1)].
		^ anIdentityDictionary
	]. 
	anIdentitySet add: self.

	self do: [:ea |
		(ea isConsCell | ea isArray) ifTrue:
			[ea storeCycles: anIdentityDictionary with: anIdentitySet]].

	^ anIdentityDictionary
]
