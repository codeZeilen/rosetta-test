"
A LispKernel special form
"
Class {
	#name : #LKPrimitiveSpecial,
	#superclass : #LKPrimitive,
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LKPrimitiveSpecial >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ aLisp perform: selector with: aConsCell
]

{ #category : #'as yet unclassified' }
LKPrimitiveSpecial >> isLKPrimitiveSpecial [

	^ true

]
