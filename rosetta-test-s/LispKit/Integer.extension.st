Extension { #name : #Integer }

{ #category : #'*LispKit-LKOS' }
Integer >> lkosClass: aLisp [

	^ LKOSInstance class: #'<integer>' inLisp: aLisp
]
