Extension { #name : #Complex }

{ #category : #'*LispKit-LKOS' }
Complex >> lkosClass: aLisp [

	^ LKOSInstance class: #'<complex>' inLisp: aLisp
]

{ #category : #'*LispKit' }
Complex >> printOn: aStream forLisp: aLisp [

	aLisp ifNil: [^ self printOn: aStream].
	aStream nextPutAll: (aLisp class complexString: self base: 10)
]
