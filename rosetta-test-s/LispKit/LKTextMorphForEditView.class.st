Class {
	#name : #LKTextMorphForEditView,
	#superclass : #TextMorphForEditView,
	#category : #'LispKit-GUI'
}

{ #category : #'as yet unclassified' }
LKTextMorphForEditView >> installEditorToReplace: priorEditor [
	"Install an editor for my paragraph.  This constitutes 'hasFocus'.
	If priorEditor is not nil, then initialize the new editor from its state.
	We may want to rework this so it actually uses the prior editor."

	| stateArray |
	priorEditor ifNotNil: [stateArray := priorEditor stateArray].
	editor := LKTextMorphEditor new morph: self.
	editor changeParagraph: self paragraph.
	priorEditor ifNotNil: [editor stateArrayPut: stateArray].
	self selectionChanged.
	^ editor
]

{ #category : #'as yet unclassified' }
LKTextMorphForEditView >> keyStroke: evt [
	
"	editView lisp standardInput stream nextPut: evt keyCharacter."
	super keyStroke: evt
]
