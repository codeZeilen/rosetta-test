Extension { #name : #False }

{ #category : #'*ConsCell' }
False >> printOn: aStream forLisp: aLisp [

	aLisp ifNil: [^ self printOn: aStream].
	aStream nextPutAll: (aLisp class falseValuePrintString)
]
