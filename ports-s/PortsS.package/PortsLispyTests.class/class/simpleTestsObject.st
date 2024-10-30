as yet unclassified
simpleTestsObject

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'lispy-tests.json' do: [:testsFile |
		Json readFrom: testsFile]