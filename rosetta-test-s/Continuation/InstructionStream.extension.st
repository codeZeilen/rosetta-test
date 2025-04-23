Extension { #name : #InstructionStream }

{ #category : #'*continuation' }
InstructionStream >> localAt: aNumber [
	"This method should belong to Context, but it is here for backward compatibility with images prior to 6.0 where ContextPart exists"
	^ self at: aNumber
]

{ #category : #'*continuation' }
InstructionStream >> localAt: aNumber put: anObject [
	"This method should belong to Context, but it is here for backward compatibility with images prior to 6.0 where ContextPart exists"
	^ self at: aNumber put: anObject
]
