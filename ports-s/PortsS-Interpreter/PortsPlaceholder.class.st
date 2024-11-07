Class {
	#name : #PortsPlaceholder,
	#superclass : #PortsFunction,
	#instVars : [
		'placeholderName',
		'parameters',
		'docString'
	],
	#category : #'PortsS-Interpreter'
}

{ #category : #accessing }
PortsPlaceholder >> car [

	^ #placeholder
]

{ #category : #accessing }
PortsPlaceholder >> docString [

	^ docString
]

{ #category : #accessing }
PortsPlaceholder >> docString: anObject [

	docString := anObject.
]

{ #category : #testing }
PortsPlaceholder >> isValid [

	^ self function notNil
]

{ #category : #accessing }
PortsPlaceholder >> parameters [

	^ parameters
]

{ #category : #accessing }
PortsPlaceholder >> parameters: anObject [

	parameters := anObject.
]

{ #category : #accessing }
PortsPlaceholder >> placeholderName [

	^ placeholderName
]

{ #category : #accessing }
PortsPlaceholder >> placeholderName: anObject [

	placeholderName := anObject.
]

{ #category : #printing }
PortsPlaceholder >> printOn: aStream [

	super printOn: aStream.
	aStream 
		<< ': ';
		<< self placeholderName.
]

{ #category : #evaluating }
PortsPlaceholder >> value: values [

	^ self function valueWithArguments: values , {self env}
]
