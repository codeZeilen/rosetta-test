Class {
	#name : #PortsSchemeLambda,
	#superclass : #Object,
	#instVars : [
		'params',
		'body',
		'env',
		'interpreter'
	],
	#category : #'PortsS-Interpreter'
}

{ #category : #accessing }
PortsSchemeLambda >> body [

	^ body
]

{ #category : #accessing }
PortsSchemeLambda >> body: anObject [

	body := anObject.
]

{ #category : #accessing }
PortsSchemeLambda >> env [

	^ env
]

{ #category : #accessing }
PortsSchemeLambda >> env: anObject [

	env := anObject.
]

{ #category : #accessing }
PortsSchemeLambda >> interpreter [

	^ interpreter
]

{ #category : #accessing }
PortsSchemeLambda >> interpreter: anObject [

	interpreter := anObject.
]

{ #category : #testing }
PortsSchemeLambda >> isPortsSchemeProcedure [

	^ true
]

{ #category : #accessing }
PortsSchemeLambda >> params [

	^ params
]

{ #category : #accessing }
PortsSchemeLambda >> params: anObject [

	params := anObject.
]

{ #category : #'as yet unclassified' }
PortsSchemeLambda >> value: values [

	^ self interpreter 
		evalExprs: self body
		in: (PortsSchemeEnv new
				setBindingsFor: self params to: values;
				parent: self env;
				yourself)
]
