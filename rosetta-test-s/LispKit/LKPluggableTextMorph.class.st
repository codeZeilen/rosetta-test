Class {
	#name : #LKPluggableTextMorph,
	#superclass : #PluggableTextMorph,
	#category : #'LispKit-GUI'
}

{ #category : #'as yet unclassified' }
LKPluggableTextMorph class >> mayHaveVignette [

	^ true
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph class >> newPage [

	^ (MGraphPluggableTextMorph on: MGraphWorkspace new
			text: #contents
			accept: #acceptContents:
			readSelection: nil 
			menu: #codePaneMenu:shifted:)
		color: (Color white alpha: 0.9)
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph >> buildMenu: aMenu [

	model buildMenu: aMenu.
	^ aMenu
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph >> setText: aText [
	scrollBar setValue: 0.0.
	textMorph
		ifNil: [textMorph := LKTextMorphForEditView new
						contents: aText wrappedTo: self innerBounds width-6.
				textMorph setEditView: self.
				scroller addMorph: textMorph]
		ifNotNil: [textMorph newContents: aText].
	self hasUnacceptedEdits: false.
	self setScrollDeltas.
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph >> spawn [
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph >> yellowButtonActivity [

	(self getMenu: false) invokeModal
]

{ #category : #'as yet unclassified' }
LKPluggableTextMorph >> yellowButtonActivity: shiftKeyState [

	(self getMenu: shiftKeyState) invokeModal
]
