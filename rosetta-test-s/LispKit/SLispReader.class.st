"
code reader for SLisp
"
Class {
	#name : #SLispReader,
	#superclass : #LKReader,
	#instVars : [
		'syntax'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #'as yet unclassified' }
SLispReader class >> initialize [

	super initialize.

	SyntacticTypes 
		atAll: (#($[ $] ${ $}) collect: [:c | c asciiValue]) 
		put: #terminatingMacro.

	{
		$[ -> #lispInSmalltalkSyntax:.
		$] -> #closeList:.
		${ -> #withSmalltalkSyntax:.
		$} -> #closeList:.
	}
	do: [:assoc | Macros add: assoc].

	"self initialize"
]

{ #category : #'as yet unclassified' }
SLispReader >> initialize [

	super initialize.
	syntax := #lisp
]

{ #category : #'as yet unclassified' }
SLispReader >> lispInSmalltalkSyntax: aStream [

	^ #lispInSmalltalkSyntax: inCons 
		addLast: (self openList: aStream syntax: #lisp)
]

{ #category : #'as yet unclassified' }
SLispReader >> openList: aStream syntax: aSymbol [

	| val prev |

	prev := syntax.
	syntax := aSymbol.
	val := super openList: aStream.
	syntax := prev.
	^ val
]

{ #category : #'as yet unclassified' }
SLispReader >> sharpMacro: aStream [

	syntax == #lisp ifTrue: [^ super sharpMacro: aStream].

	^ #lispInSmalltalkSyntax: inCons addLast: (self quote: aStream) 
]

{ #category : #'as yet unclassified' }
SLispReader >> withSmalltalkSyntax: aStream [

	^ #withSmalltalkSyntax: inCons addLast: 
		(self openList: aStream syntax: #smalltalk)
]
