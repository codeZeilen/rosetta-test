Extension { #name : #String }

{ #category : #'*ConsCell' }
String >> printOn: aStream forLisp: aLisp [

	aStream nextPut: $".
	aStream nextPutAll: 
		(aLisp ifNil: [self] ifNotNil: [aLisp class representString: self]).
	aStream nextPut: $"
]
