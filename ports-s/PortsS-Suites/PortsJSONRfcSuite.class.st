Class {
	#name : #PortsJSONRfcSuite,
	#superclass : #PortsSuite,
	#category : #'PortsS-Suites'
}

{ #category : #placeholders }
PortsJSONRfcSuite >> fileContents: fileName env: env [

	<portsPlaceholderName: 'file-contents'>
	
	^ (FileDirectory default / '..' / '..' / #ports / 'suites' / 'json-rfc-fixtures') readOnlyFileNamed: fileName do: [:stream |
		stream binary.
		stream contents asString]
]

{ #category : #placeholders }
PortsJSONRfcSuite >> listJsonTestFiles: env [

	<portsPlaceholderName: 'list-json-test-files'>
	
	^ (FileDirectory default / '..' / '..' / #ports / 'suites' / 'json-rfc-fixtures') fileEntries collect: [:entry | entry name]
]

{ #category : #placeholders }
PortsJSONRfcSuite >> parse: jsonString env: env [

	<portsPlaceholderName: 'parse'>
	
	^ [Json readFrom: jsonString readStream]
		on: Exception
		do: [:e | e]
]

{ #category : #placeholders }
PortsJSONRfcSuite >> parseSuccess: parseResult env: env [

	<portsPlaceholderName: 'parse-success?'>
	
	^ (parseResult isKindOf: Exception) not
]

{ #category : #'suite definition' }
PortsJSONRfcSuite >> suiteSource [

	^ self readSuiteFileNamed: 'json-rfc.ports'
]
