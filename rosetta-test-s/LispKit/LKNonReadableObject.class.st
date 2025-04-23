Class {
	#name : #LKNonReadableObject,
	#superclass : #Object,
	#instVars : [
		'printedRepresentation'
	],
	#category : #'LispKit-Reader-Base'
}

{ #category : #accessing }
LKNonReadableObject >> printOn: aStream [

	self printOn: aStream forLisp: nil
	
]

{ #category : #accessing }
LKNonReadableObject >> printOn: aStream forLisp: aLisp [

	aStream nextPutAll: '#<'; nextPutAll: printedRepresentation; nextPut: $>
	
]

{ #category : #accessing }
LKNonReadableObject >> printedRepresentation [

	^ printedRepresentation 
]

{ #category : #accessing }
LKNonReadableObject >> printedRepresentation: aString [

	printedRepresentation := aString
]
