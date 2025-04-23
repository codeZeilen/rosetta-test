Extension { #name : #SequenceableCollection }

{ #category : #'*LispKit' }
SequenceableCollection >> cutAt: aNumber [

	self size <= aNumber ifTrue: [^ self].
	^ self first: aNumber
]
