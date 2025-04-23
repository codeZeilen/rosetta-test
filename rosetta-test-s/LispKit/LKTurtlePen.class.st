"
A pen for a LKTurtlePlayground

	... see ELisp class>>turtleGraphics

"
Class {
	#name : #LKTurtlePen,
	#superclass : #Pen,
	#instVars : [
		'display'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKTurtlePen class >> newOnDisplay: aLKDisplay [

	^ (self newOnForm: aLKDisplay image) display: aLKDisplay
]

{ #category : #operations }
LKTurtlePen >> center [

	self place: display image center
]

{ #category : #private }
LKTurtlePen >> display: aLKDisplay [

	display := aLKDisplay
]

{ #category : #private }
LKTurtlePen >> drawFrom: startPoint to: stopPoint [ 
	
	super drawFrom: startPoint to: stopPoint.
	display changed
	
]

{ #category : #operations }
LKTurtlePen >> print: str [

	self print: str withFont: TextStyle defaultFont
]

{ #category : #private }
LKTurtlePen >> vertices [

	^ (Array with: -4@4 with: -4@-4 with: 8@0)
			collect: [:p | 
				(p rotateBy: (direction negated * Float pi / 180.0) about: (0@0)) 
					+ location] 
]
