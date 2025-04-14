Class {
	#name : #RosettaSchemeLambda,
	#superclass : #Object,
	#instVars : [
		'params',
		'body',
		'env',
		'interpreter'
	],
	#category : #'RosettaS-Interpreter'
}

{ #category : #accessing }
RosettaSchemeLambda >> body [

	^ body
]

{ #category : #accessing }
RosettaSchemeLambda >> body: anObject [

	body := anObject.
]

{ #category : #accessing }
RosettaSchemeLambda >> env [

	^ env
]

{ #category : #accessing }
RosettaSchemeLambda >> env: anObject [

	env := anObject.
]

{ #category : #accessing }
RosettaSchemeLambda >> interpreter [

	^ interpreter
]

{ #category : #accessing }
RosettaSchemeLambda >> interpreter: anObject [

	interpreter := anObject.
]

{ #category : #testing }
RosettaSchemeLambda >> isRosettaSchemeProcedure [

	^ true
]

{ #category : #accessing }
RosettaSchemeLambda >> params [

	^ params
]

{ #category : #accessing }
RosettaSchemeLambda >> params: anObject [

	params := anObject.
]

{ #category : #'as yet unclassified' }
RosettaSchemeLambda >> value: values [

	^ self interpreter 
		evalExprs: self body
		in: (RosettaSchemeEnv new
				setBindingsFor: self params to: values;
				parent: self env;
				yourself)
]
