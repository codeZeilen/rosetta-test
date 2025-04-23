"
Continuation class borrowed from Seaside
(author: Avi Bryant) 
"
Class {
	#name : #Continuation,
	#superclass : #Object,
	#instVars : [
		'values'
	],
	#category : #Continuation
}

{ #category : #'instance creation' }
Continuation class >> current [
	^ self fromContext: thisContext sender
]

{ #category : #'instance creation' }
Continuation class >> currentDo: aBlock [
	^ aBlock value: (self fromContext: thisContext sender)
]

{ #category : #'instance creation' }
Continuation class >> fromContext: aStack [
	^self new initializeFromContext: aStack
]

{ #category : #private }
Continuation >> initializeFromContext: aContext [
	| valueStream context |
	valueStream := WriteStream on: (Array new: 20).
	context := aContext.
	[context notNil] whileTrue:
		[valueStream nextPut: context.
		1 to: context class instSize do: [:i | valueStream nextPut: (context instVarAt: i)].
		1 to: context size do: [:i | valueStream nextPut: (context localAt: i)].
		context := context sender].
	values := valueStream contents
]

{ #category : #testing }
Continuation >> isContinuation [

	^ true
]

{ #category : #invocation }
Continuation >> numArgs [
	^ 1
]

{ #category : #'as yet unclassified' }
Continuation >> restoreValues [
	| valueStream context |
	valueStream := values readStream.
	[valueStream atEnd] whileFalse:
		[context := valueStream next.
		1 to: context class instSize do: [:i | context instVarAt: i put: valueStream next].
		1 to: context size do: [:i | context localAt: i put: valueStream next]]
]

{ #category : #private }
Continuation >> terminate: aContext [
	| context |
	context := aContext.
	[context notNil] whileTrue: [context := context swapSender: nil]

]

{ #category : #invocation }
Continuation >> value [
	self value: nil
]

{ #category : #invocation }
Continuation >> value: v [
	self terminate: thisContext.
	self restoreValues.
	thisContext swapSender: values first.
	^v
]

{ #category : #invocation }
Continuation >> valueWithArguments: v [
	v size == 1 ifFalse: [^self error: 'continuations can only be resumed with one argument'].
	self value: v first
]
