Class {
	#name : #RosettaJSONRfcSuite,
	#superclass : #RosettaSuite,
	#category : #'RosettaS-Suites'
}

{ #category : #placeholders }
RosettaJSONRfcSuite >> fileContents: fileName env: env [

	<rosettaPlaceholderName: 'file-contents'>
	
	^ (self fixtureFolderNamed: 'json-rfc-fixtures') readOnlyFileNamed: fileName do: [:stream |
		stream binary.
		stream contents asString]
]

{ #category : #placeholders }
RosettaJSONRfcSuite >> listJsonTestFiles: env [

	<rosettaPlaceholderName: 'list-json-test-files'>
	
	^ (self fixtureFolderNamed: 'json-rfc-fixtures') fileEntries collect: [:entry | entry name]
]

{ #category : #placeholders }
RosettaJSONRfcSuite >> parse: jsonString env: env [

	<rosettaPlaceholderName: 'parse'>
	
	^ [Json readFrom: jsonString readStream]
		on: Exception
		do: [:e | e]
]

{ #category : #placeholders }
RosettaJSONRfcSuite >> parseSuccess: parseResult env: env [

	<rosettaPlaceholderName: 'parse-success?'>
	
	^ (parseResult isKindOf: Exception) not
]

{ #category : #'suite definition' }
RosettaJSONRfcSuite >> suiteSource [

	^ self readSuiteFileNamed: 'json-rfc.ros'
]
