as yet unclassified
runSimpleTests
	"[PortsLispyTests runSimpleTests]"
	| scheme |
	scheme := PortsScheme new.
	self simpleTestsObject do: [:testData | | result |
		result := scheme evalString: (testData at: 'input').
		self assert: (result = (testData at: 'expected'))]