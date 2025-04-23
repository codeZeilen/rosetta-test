Extension { #name : #True }

{ #category : #'*ConsCell' }
True >> printOn: aStream forLisp: aLisp [

	aLisp ifNil: [^ self printOn: aStream].
	aStream nextPutAll: (aLisp class trueValuePrintString)
]
