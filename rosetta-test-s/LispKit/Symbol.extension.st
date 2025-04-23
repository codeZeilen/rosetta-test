Extension { #name : #Symbol }

{ #category : #'*LispKit' }
Symbol >> bindingsWithArguments: aConsCell [

	"complements the similar method in ConsCell"

	^ {self -> aConsCell}
]

{ #category : #'*LispKit-LKOS' }
Symbol >> lkosClass: aLisp [

	^ LKOSInstance class: #'<symbol>' inLisp: aLisp
]

{ #category : #'*LispKit' }
Symbol >> symbolsForBinding [

	"complements the similar method in ConsCell"

	^ {self}
]

{ #category : #'*LispKit' }
Symbol >> valueForLisp: aLisp [ 

	^ aLisp symbolValue: self ifNone: [aLisp lispError: 'no value for symbol ', self]
]

{ #category : #'*LispKit' }
Symbol >> valueForLisp: aLisp allowMultipleValues: mvflag inTail: tflag [

	^ aLisp symbolValue: self ifNone: [aLisp lispError: 'no value for symbol ', self]
]
