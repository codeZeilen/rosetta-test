Extension { #name : #Symbol }

{ #category : #'*ConsCell' }
Symbol >> printOn: aStream forLisp: aLisp [

	aLisp ifNotNil: [^ aLisp printSymbol: self on: aStream].
	aStream nextPutAll: self




]
