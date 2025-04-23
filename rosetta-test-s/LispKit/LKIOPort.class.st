"
Interface presenting smalltalk streams as Lisp streams
"
Class {
	#name : #LKIOPort,
	#superclass : #Object,
	#instVars : [
		'inStream',
		'outStream',
		'status'
	],
	#category : #'LispKit-Reader-Base'
}

{ #category : #'as yet unclassified' }
LKIOPort class >> eof [

	^ #'<eof>'
]

{ #category : #'as yet unclassified' }
LKIOPort class >> forInput [

	^ self input: (ReadWriteStream on: Text new)

]

{ #category : #'as yet unclassified' }
LKIOPort class >> forOutput [

	^ self output: (WriteStream on: Text new)

]

{ #category : #'as yet unclassified' }
LKIOPort class >> input: aStream [

	aStream ifNil: [self error: 'no stream specified'].

	^ self new 
		status: #in;
		inStream: aStream
]

{ #category : #'as yet unclassified' }
LKIOPort class >> input: aStream output: bStream [

	^ self new 
		status: #bi;
		outStream: aStream;
		inStream: aStream
]

{ #category : #'as yet unclassified' }
LKIOPort class >> output: aStream [

	aStream ifNil: [self error: 'no stream specified'].

	^ self new 
		status: #out;
		outStream: aStream
]

{ #category : #proxy }
LKIOPort >> atEnd [

	^ self stream atEnd
]

{ #category : #'-- hacks --' }
LKIOPort >> clear [
	"Clear all characters and redisplay the view"
	self changed: #clearText.
"	self stream reset"
]

{ #category : #proxy }
LKIOPort >> close [

	self stream close

]

{ #category : #'-- hacks --' }
LKIOPort >> endEntry [
	"Display all the characters since the last endEntry, and reset the stream"

	self changed: #endEntry.
"	self dependents ifNotEmpty: [self reset]."
	
]

{ #category : #'-- hacks --' }
LKIOPort >> force [
	"Force all pending output to be processed"
	self changed: #force.
"	self stream reset"
]

{ #category : #'as yet unclassified' }
LKIOPort >> inStream [

	^ inStream 
]

{ #category : #'as yet unclassified' }
LKIOPort >> inStream: aStream [

	inStream := aStream
]

{ #category : #'as yet unclassified' }
LKIOPort >> isInput [

	^ status == #in
]

{ #category : #'as yet unclassified' }
LKIOPort >> isLKIOPort [

	^ true
]

{ #category : #'as yet unclassified' }
LKIOPort >> isOutput [

	^ status == #out
]

{ #category : #'as yet unclassified' }
LKIOPort >> isTwoWay [

	^ status == #bi
]

{ #category : #'as yet unclassified' }
LKIOPort >> outStream [

	^ outStream 
]

{ #category : #'as yet unclassified' }
LKIOPort >> outStream: aStream [

	outStream := aStream
]

{ #category : #proxy }
LKIOPort >> reset [

	self stream reset
]

{ #category : #'as yet unclassified' }
LKIOPort >> status [

	^ status 
]

{ #category : #'as yet unclassified' }
LKIOPort >> status: aSymbol [

	status := aSymbol
]

{ #category : #'as yet unclassified' }
LKIOPort >> stream [

	^ self isInput ifTrue: [inStream] ifFalse: [outStream]

]
