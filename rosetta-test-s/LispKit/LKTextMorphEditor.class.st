Class {
	#name : #LKTextMorphEditor,
	#superclass : #LegacyTextMorphEditor,
	#category : #'LispKit-GUI'
}

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> cursorPageDown: characterStream [ 

	self isOnPromptLine
		ifTrue: [model insertNextCommand. ^ true].

	^ super cursorPageDown: characterStream 
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> cursorPageUp: characterStream [ 

	self isOnPromptLine
		ifTrue: [model insertPreviousCommand. ^ true].

	^ super cursorPageUp: characterStream 
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> encompassLine: anInterval [
	"Return an interval that encompasses the entire line, minus the promt if present at the beginning"

	| string left right |
	string := paragraph text string.
	left := (string lastIndexOf: Character cr startingAt: anInterval first - 1 ifAbsent:[0]) + 1.

	left == 
		(string indexOfSubCollection: model prompt startingAt: left ifAbsent: [nil]) 
	ifTrue: [left := left + model prompt size].

	right := (string indexOf: Character cr startingAt: anInterval last + 1 ifAbsent: [string size + 1]) - 1.
	^left to: right
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> evaluateSelection [
	"Treat the current selection as an expression; evaluate it and return the result"

	self lineSelectAndEmptyCheck: [^ ''].
	^ model evalText: self selectionAsStream contents
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> isOnPromptLine [

	^ self isPromptLine: self selectionInterval

]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> isPromptLine: anInterval [

	| string left |
	string := paragraph text string.
	left := (string lastIndexOf: Character cr startingAt: anInterval first - 1 ifAbsent:[0]) + 1.

	^ left == 
		(string indexOfSubCollection: model prompt startingAt: left ifAbsent: [nil]) 

]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> printIt [
	"Treat the current text selection as an expression; evaluate it. Insert the 
	description of the result of evaluation after the selection and then make 
	this description the new text selection."
	| result |
	result := self evaluateSelection.
	((result isKindOf: FakeClassPool) or: [result == #failedDoit])
			ifTrue: [view flash]
			ifFalse: [self afterSelectionInsertAndSelect: (result printStringForLisp: model)]
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> selectionAsStream [
	"Answer a ReadStream on the text in the paragraph that is currently 
	selected."

	^PositionableStream
		on: paragraph string
		from: self startIndex
		to: self stopIndex - 1
]

{ #category : #'as yet unclassified' }
LKTextMorphEditor >> spawn [

	
]
