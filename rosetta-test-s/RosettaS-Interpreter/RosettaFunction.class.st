Class {
	#name : #RosettaFunction,
	#superclass : #Object,
	#instVars : [
		'function',
		'env'
	],
	#category : #'RosettaS-Interpreter'
}

{ #category : #accessing }
RosettaFunction >> env [

	^ env
]

{ #category : #accessing }
RosettaFunction >> env: anObject [

	env := anObject.
]

{ #category : #accessing }
RosettaFunction >> function [

	^ function
]

{ #category : #accessing }
RosettaFunction >> function: anObject [

	function := anObject.
]
