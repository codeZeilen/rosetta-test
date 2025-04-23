Extension { #name : #Array }

{ #category : #'*LispKit-LKOS' }
Array >> lkosClass: aLisp [

	^ LKOSInstance class: #'<vector>' inLisp: aLisp
]
