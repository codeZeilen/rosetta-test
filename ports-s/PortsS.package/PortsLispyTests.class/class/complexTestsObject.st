as yet unclassified
complexTestsObject

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'lispy-tests2.json' do: [:testsFile |
		Json readFrom: testsFile]