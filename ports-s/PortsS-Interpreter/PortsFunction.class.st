Class {
	#name : #PortsFunction,
	#superclass : #Object,
	#instVars : [
		'function',
		'env'
	],
	#category : #'PortsS-Interpreter'
}

{ #category : #accessing }
PortsFunction >> env [

	^ env
]

{ #category : #accessing }
PortsFunction >> env: anObject [

	env := anObject.
]

{ #category : #accessing }
PortsFunction >> function [

	^ function
]

{ #category : #accessing }
PortsFunction >> function: anObject [

	function := anObject.
]
