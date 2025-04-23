Extension { #name : #Number }

{ #category : #'*LispKit-LKOS' }
Number >> lkosClass: aLisp [

	^ LKOSInstance class: #'<real>' inLisp: aLisp
]
