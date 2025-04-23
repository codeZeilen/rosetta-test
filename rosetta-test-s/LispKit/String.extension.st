Extension { #name : #String }

{ #category : #'*LispKit' }
String >> capAtLinks [
	| stream here |
	stream := WriteStream on: (self species new: self size * 2).
	here := false.
	self do: [ :c |
		c == $-
			ifTrue: [ here := true ]
			ifFalse: [ stream nextPut: (here ifFalse: [c] ifTrue: [c asUppercase]).
					  here := false].
	].
	^stream contents
]

{ #category : #'*LispKit' }
String >> isAllLetters [
	"whether the receiver is composed entirely of letters"
	self do: [:c | c isLetter ifFalse: [^ false]].
	^ true
]

{ #category : #'*LispKit' }
String >> linkAtCaps [
	| stream  |
	stream := WriteStream on: (self species new: self size * 2).
	self do: [ :c |
		c isUppercase 
			ifTrue: [ stream nextPut: $-; nextPut: c asLowercase ]
			ifFalse: [ stream nextPut: c ].
	].
	^stream contents
]

{ #category : #'*LispKit-LKOS' }
String >> lkosClass: aLisp [

	^ LKOSInstance class: #'<string>' inLisp: aLisp
]
