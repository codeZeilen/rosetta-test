spec definition
createTestFile: fileName content: content env: env

	<portsPlaceholderName: #'create-test-file'> 
	FileStream fileNamed: fileName do: [:stream |
		stream nextPutAll: content].