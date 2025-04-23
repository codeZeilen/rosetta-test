Extension { #name : #BlockClosure }

{ #category : #'*LispKit' }
BlockClosure >> applyInTailTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ self applyTo: aConsCell inLisp: aLisp asMacro: mflag

]

{ #category : #'*LispKit' }
BlockClosure >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	aConsCell ifNil: [^ self value].
	aConsCell cdr ifNil: [^ self value: (aConsCell car valueForLisp: aLisp)].
	aConsCell cdr cdr 
		ifNil: [^ self value: (aConsCell car valueForLisp: aLisp) value: (aConsCell cdr car valueForLisp: aLisp)].
	aConsCell cdr cdr cdr 
		ifNil: [^ self value: (aConsCell car valueForLisp: aLisp) value: (aConsCell cdr car valueForLisp: aLisp) value:(aConsCell cdr cdr car valueForLisp: aLisp)].

	^ self valueWithArguments:(Array streamContents: [:stream | 
				(aLisp evalList: aConsCell) storeTopFormsIn: stream])
]

{ #category : #'*LispKit' }
BlockClosure >> gcbench [

	Smalltalk garbageCollect.
	Smalltalk garbageCollect.
	^ self bench
]

{ #category : #'*LispKit' }
BlockClosure >> isCompiledProcedure [

	^ true
]
