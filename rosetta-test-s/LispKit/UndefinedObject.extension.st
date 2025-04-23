Extension { #name : #UndefinedObject }

{ #category : #'*LispKit-LKOS' }
UndefinedObject >> lkosClass: aLisp [

	^ LKOSInstance class: #'<null>' inLisp: aLisp
]
