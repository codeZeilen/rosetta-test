Class {
	#name : #LispKitREPLMorph,
	#superclass : #REPLMorph,
	#category : #'LispKit-GUI'
}

{ #category : #'as yet unclassified' }
LispKitREPLMorph >> evaluator: aLispKernel [

	super evaluator: aLispKernel.
	evaluator focusOnREPL: self.


]

{ #category : #'as yet unclassified' }
LispKitREPLMorph >> formatAnswer: anObject [

	^ anObject printStringForLisp: evaluator

]

{ #category : #'as yet unclassified' }
LispKitREPLMorph >> setMyText: text [

	"ensure we have the lisp focus"
	evaluator focusOnREPL: self.
	super setMyText: text
]
