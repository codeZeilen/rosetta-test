Class {
	#name : #PortsLispyTests,
	#superclass : #Object,
	#instVars : [
		'testsObject'
	],
	#classInstVars : [
		'portsScheme'
	],
	#category : #'PortsS-Tests'
}

{ #category : #'as yet unclassified' }
PortsLispyTests class >> complexTestsObject [

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'lispy-tests2.json' do: [:testsFile |
		Json readFrom: testsFile]
]

{ #category : #'as yet unclassified' }
PortsLispyTests class >> runComplexTests [
	"[PortsLispyTests runComplexTests]"
	| scheme |
	scheme := PortsScheme new.
	self complexTestsObject do: [:testData | | result expectedResult |
		expectedResult := testData at: 'expected'.
		[result := scheme evalString: (testData at: 'input')]
			on: PortsSyntaxError
			do: [result := {#type -> 'SyntaxError'} asDictionary]
			on: PortsTypeError
			do: [result := {#type -> 'TypeError'} asDictionary].
		(expectedResult isDictionary and: [expectedResult includesKey: #type])
			ifTrue: [self assert: (expectedResult at: #type) = (result at: #type)]
			ifFalse: [self assert: result = expectedResult]]
]

{ #category : #'as yet unclassified' }
PortsLispyTests class >> runSimpleTests [
	"[PortsLispyTests runSimpleTests]"
	| scheme |
	scheme := PortsScheme new.
	self simpleTestsObject do: [:testData | | result |
		result := scheme evalString: (testData at: 'input').
		self assert: (result = (testData at: 'expected'))]
]

{ #category : #'as yet unclassified' }
PortsLispyTests class >> simpleTestsObject [

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'lispy-tests.json' do: [:testsFile |
		Json readFrom: testsFile]
]
