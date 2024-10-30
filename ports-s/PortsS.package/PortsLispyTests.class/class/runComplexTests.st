as yet unclassified
runComplexTests
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