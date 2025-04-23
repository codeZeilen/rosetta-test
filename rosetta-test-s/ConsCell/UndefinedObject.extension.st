Extension { #name : #UndefinedObject }

{ #category : #'*ConsCell' }
UndefinedObject >> arrayForm [

	^ #()
]

{ #category : #'*ConsCell' }
UndefinedObject >> car [

	^ nil
]

{ #category : #'*ConsCell' }
UndefinedObject >> cdr [

	^ nil
]

{ #category : #'*ConsCell' }
UndefinedObject >> printOn: aStream forLisp: aLisp [

	aLisp ifNil: [^ self printOn: aStream].
	aStream nextPutAll: aLisp class nullPrintString

]

{ #category : #'*ConsCell' }
UndefinedObject >> safeTopForms [

	^ #()
]

{ #category : #'*ConsCell' }
UndefinedObject >> topForms [

	^ #()
]
