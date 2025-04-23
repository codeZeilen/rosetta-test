Extension { #name : #Fraction }

{ #category : #'*LispKit-LKOS' }
Fraction >> lkosClass: aLisp [

	^ LKOSInstance class: #'<rational>' inLisp: aLisp
]

{ #category : #'*LispKit' }
Fraction >> printOn: aStream forLisp: aLisp [

	numerator printOn: aStream.
	aStream nextPut: $/. 
	denominator printOn: aStream
]
