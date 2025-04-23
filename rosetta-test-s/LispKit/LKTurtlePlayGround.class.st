"
Simple playground for LispKit turtles (which are instances of LKTurtlePen)

	... see ELisp class>>turtleGraphics

examples: 

	ELisp new loadDefaultLibraries top: #
		(progn
			(turtle-show t)
			(turtle go: 20) 
			(turtle turn: 35) 
			(dotimes (n 4)
				(turtle* (go: 50) (turn: 90))))		 ""doIt""

	ELisp new loadDefaultLibraries top: #
		(progn
			(turtle-show t)
			(turtle color: (color blue)) 
			(turtle dragon: 6)
			(turtle color: (color red)) 
			(turtle dragon: 8))						 ""doIt""

	ELisp new loadDefaultLibraries top: #
		(progn
			(turtle-size 300 300)
			(turtle center)
			(turtle spiral:angle: 200 89)	
			(turtle-show t))  							 ""doIt""
"
Class {
	#name : #LKTurtlePlayGround,
	#superclass : #ImageMorph,
	#instVars : [
		'canvas',
		'pens'
	],
	#category : #LispKit
}

{ #category : #turtles }
LKTurtlePlayGround >> addPen [

	| pen |

	pens := pens, {pen := (LKTurtlePen newOnDisplay: self) center}.
	self addMorph: (PolygonMorph vertices: pen vertices 
							color: Color green borderWidth: 1 
							borderColor: Color black)
]

{ #category : #accessing }
LKTurtlePlayGround >> canvas [

	^ canvas
]

{ #category : #accessing }
LKTurtlePlayGround >> clear [

	canvas fillColor: Color white.
	self changed
]

{ #category : #private }
LKTurtlePlayGround >> extent: aPoint [

	| newImage |

	newImage := (Form extent: aPoint depth: image depth).
	newImage getCanvas  
		fillColor: Color white;
		drawImage: image at: 0@0.
	
	self image: newImage.
	canvas := self image getCanvas.
	pens ifNotNil: [pens do: [:p | p setDestForm: image.]]

]

{ #category : #private }
LKTurtlePlayGround >> initialize [

	super initialize.
	self image: (Form extent: 200@200 depth: Display depth).
	canvas := self image getCanvas.
	pens := #().
	self clear.
	self startStepping
]

{ #category : #turtles }
LKTurtlePlayGround >> pen [

	pens ifEmpty: [self addPen].

	^ pens first
]

{ #category : #turtles }
LKTurtlePlayGround >> step [

	pens with: submorphs do: [:p :m |
			m setVertices: (p vertices + self topLeft)]

	


]

{ #category : #turtles }
LKTurtlePlayGround >> stepTime [

	^ 100



]

{ #category : #turtles }
LKTurtlePlayGround >> wantsSteps [

	^ true



]
