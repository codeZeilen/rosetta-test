"
This is a variation on the Continuation from Seaside, by Avi Bryant.

It only snapshots the senders chain up to the top level invocation of the lisp interpreter (which is by convention its method #enterInterpreterContextAndEval:) so that we do not have the undesirable effects of a full Continuation which would leak out of Lisp

"
Class {
	#name : #LKContinuation,
	#superclass : #Continuation,
	#instVars : [
		'topMethod'
	],
	#category : #'LispKit-Continuations'
}

{ #category : #'instance creation' }
LKContinuation class >> upTo: aMethod [
	^ self new initializeFromContext: thisContext sender upTo: aMethod
]

{ #category : #private }
LKContinuation >> getTopSenderFrom: aContext [.

	aContext method == topMethod ifTrue: [^ aContext].

	^ self getTopSenderFrom: aContext sender.

	
]

{ #category : #private }
LKContinuation >> getTopSendersFrom: aContext [
	| valueStream context |
	valueStream := WriteStream on: (Array new: 20).
	context := self getTopSenderFrom: aContext. 

	[context notNil] whileTrue:
		[valueStream nextPut: context.
		1 to: context class instSize do: [:i | valueStream nextPut: (context instVarAt: i)].
		1 to: context size do: [:i | valueStream nextPut: (context localAt: i)].
		context := context sender].
	^ valueStream contents
]

{ #category : #private }
LKContinuation >> initializeFromContext: aContext upTo: aMethod [
	| valueStream context topSender |
	valueStream := WriteStream on: (Array new: 20).
	context := aContext.

	topMethod := aMethod.

	topSender := self getTopSenderFrom: aContext.

	[context notNil and: [context ~= topSender]] whileTrue:
		[valueStream nextPut: context.
		1 to: context class instSize do: [:i | valueStream nextPut: (context instVarAt: i)].
		1 to: context size do: [:i | valueStream nextPut: (context localAt: i)].
		context := context sender].
	values := valueStream contents
]

{ #category : #testing }
LKContinuation >> isLKContinuation [

	^ true
]

{ #category : #private }
LKContinuation >> restoreValuesWithTop: topSenders [
	| valueStream context  |

	valueStream := values readStream.
	[valueStream atEnd] whileFalse:
		[context := valueStream next.
		1 to: context class instSize do: [:i | context instVarAt: i put: valueStream next].
		1 to: context size do: [:i | context localAt: i put: valueStream next]].

	context privSender: topSenders first.

	valueStream := topSenders readStream.
	[valueStream atEnd] whileFalse:
		[context := valueStream next.
		1 to: context class instSize do: [:i | context instVarAt: i put: valueStream next].
		1 to: context size do: [:i | context localAt: i put: valueStream next]].

]

{ #category : #invocation }
LKContinuation >> value: v [

	| topSenders |

	topSenders := self getTopSendersFrom: thisContext.
	self terminate: thisContext.
	self restoreValuesWithTop: topSenders.
	thisContext swapSender: values first.
	^v
]
