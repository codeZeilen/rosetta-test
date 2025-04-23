Class {
	#name : #LispKernelTest,
	#superclass : #TestCase,
	#category : #'LispKit-Tests'
}

{ #category : #'as yet unclassified' }
LispKernelTest >> testRewrite1 [

	self assert: 
	(LispKernel rewrite: #(asciiValue97) asCons) = {#a} asCons.

	self assert: 
	(LispKernel rewrite: {#asciiValue97} inCons) arrayForm = {{#a}}.

	
]
