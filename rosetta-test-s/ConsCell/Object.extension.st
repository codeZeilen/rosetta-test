Extension { #name : #Object }

{ #category : #'*ConsCell' }
Object >> asCons [

	^ self
]

{ #category : #'*ConsCell' }
Object >> cdr [

	self error: 'not a list'
]

{ #category : #'*ConsCell' }
Object >> inCons [

	^ ConsCell car: self
]

{ #category : #'*ConsCell' }
Object >> inQuotedCons [

	^ (ConsCell car: #quote) addLast: self
]

{ #category : #'*ConsCell' }
Object >> isConsCell [

	^ false
]

{ #category : #'*ConsCell' }
Object >> printOn: aStream depth: aNumber forLisp: aLisp level: cpl maxLevel: mpl length: len maxLength: mlen done: anIdentitySet cycles: anIdentityDictionary [

	^ self printOn: aStream forLisp: aLisp


]

{ #category : #'*ConsCell' }
Object >> printOn: aStream forLisp: aLisp [

	aStream nextPutAll: '#<'.
	self printOn: aStream.
	aStream nextPut: $>
]
