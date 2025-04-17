Class {
	#name : #RosettaPlaceholder,
	#superclass : #RosettaFunction,
	#instVars : [
		'placeholderName',
		'parameters',
		'docString'
	],
	#category : #'RosettaS-Interpreter'
}

{ #category : #accessing }
RosettaPlaceholder >> car [

	^ #placeholder
]

{ #category : #accessing }
RosettaPlaceholder >> docString [

	^ docString
]

{ #category : #accessing }
RosettaPlaceholder >> docString: anObject [

	docString := anObject.
]

{ #category : #'*RosettaS-Interpreter' }
RosettaPlaceholder >> isRosettaSchemePrimitive [

	^ true
]

{ #category : #testing }
RosettaPlaceholder >> isValid [

	^ self function notNil
]

{ #category : #accessing }
RosettaPlaceholder >> parameters [

	^ parameters
]

{ #category : #accessing }
RosettaPlaceholder >> parameters: anObject [

	parameters := anObject.
]

{ #category : #accessing }
RosettaPlaceholder >> placeholderName [

	^ placeholderName
]

{ #category : #accessing }
RosettaPlaceholder >> placeholderName: anObject [

	placeholderName := anObject.
]

{ #category : #printing }
RosettaPlaceholder >> printOn: aStream [

	super printOn: aStream.
	aStream 
		<< ': ';
		<< self placeholderName.
]

{ #category : #evaluating }
RosettaPlaceholder >> value: values [

	self assert: self function notNil.
	^ self function valueWithArguments: values , {self env}
]
