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

{ #category : #running }
RosettaLispyTests class >> runTests [
	"[RosettaLispyTests runTests]" 
	| scheme |
	scheme := RosettaScheme new.
	self testsObject do: [:testData | | result expectedResult |
		expectedResult := testData at: 'expected'.
		[result := scheme evalString: (testData at: 'input')]
			on: RosettaSyntaxError 
			do: [result := {#type -> 'SyntaxError'} asDictionary]
			on: RosettaTypeError
			do: [result := {#type -> 'TypeError'} asDictionary]
			on: Error
			do: [result := {#type -> 'Error'} asDictionary].
		(expectedResult isDictionary and: [expectedResult includesKey: #type])
			ifTrue: [self assert: (expectedResult at: #type) = (result at: #type)]
			ifFalse: [
				expectedResult 
					ifNil: [result isNil or: [result isCollection and: [result isEmpty]]]
					ifNotNil: [self assert: result = expectedResult]]]
]

{ #category : #running }
RosettaLispyTests class >> testsObject [

	^ (FileDirectory default / '..' / '..' / #'rosetta-test' / #'rosetta-test') readOnlyFileNamed: 'interpreter-tests.json' do: [:testsFile |
		Json readFrom: testsFile]
]
