Class {
	#name : #RosettaLispyTests,
	#superclass : #Object,
	#instVars : [
		'testsObject'
	],
	#classInstVars : [
		'rosettaScheme'
	],
	#category : #'RosettaS-Tests'
}

{ #category : #'as yet unclassified' }
RosettaLispyTests class >> complexTestsObject [

	^ (FileDirectory default / '..' / '..' / #rosetta) readOnlyFileNamed: 'lispy-tests2.json' do: [:testsFile |
		Json readFrom: testsFile]
]

{ #category : #'as yet unclassified' }
RosettaLispyTests class >> runComplexTests [
	"[RosettaLispyTests runComplexTests]"
	| scheme |
	scheme := RosettaScheme new.
	self complexTestsObject do: [:testData | | result expectedResult |
		expectedResult := testData at: 'expected'.
		[result := scheme evalString: (testData at: 'input')]
			on: RosettaSyntaxError
			do: [result := {#type -> 'SyntaxError'} asDictionary]
			on: RosettaTypeError
			do: [result := {#type -> 'TypeError'} asDictionary].
		(expectedResult isDictionary and: [expectedResult includesKey: #type])
			ifTrue: [self assert: (expectedResult at: #type) = (result at: #type)]
			ifFalse: [self assert: result = expectedResult]]
]

{ #category : #'as yet unclassified' }
RosettaLispyTests class >> runSimpleTests [
	"[RosettaLispyTests runSimpleTests]"
	| scheme |
	scheme := RosettaScheme new.
	self simpleTestsObject do: [:testData | | result |
		result := scheme evalString: (testData at: 'input').
		self assert: (result = (testData at: 'expected'))]
]

{ #category : #'as yet unclassified' }
RosettaLispyTests class >> simpleTestsObject [

	^ (FileDirectory default / '..' / '..' / #rosetta) readOnlyFileNamed: 'lispy-tests.json' do: [:testsFile |
		Json readFrom: testsFile]
]
