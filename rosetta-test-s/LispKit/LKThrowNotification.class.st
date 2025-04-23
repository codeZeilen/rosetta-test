"
used to implement catch & throw


"
Class {
	#name : #LKThrowNotification,
	#superclass : #Notification,
	#instVars : [
		'value'
	],
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKThrowNotification >> value [

	^ value
]

{ #category : #'as yet unclassified' }
LKThrowNotification >> value: anObject [

	value := anObject
]
