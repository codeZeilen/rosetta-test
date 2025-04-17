Class {
	#name : #RosettaURLParsingRFCUrlSuite,
	#superclass : #RosettaSuite,
	#category : #'RosettaS-Suites'
}

{ #category : #placeholders }
RosettaURLParsingRFCUrlSuite >> parseError: parseResult env: env [

	<rosettaPlaceholderName: 'parse-error?'>

	^ false "Url parsing does not throw an error but completes the Url to an HTTP Url"
]

{ #category : #'suite definition' }
RosettaURLParsingRFCUrlSuite >> suiteSource [

	^ self readSuiteFileNamed: 'url-parsing-rfc.ros'
]

{ #category : #placeholders }
RosettaURLParsingRFCUrlSuite >> urlAuthority: url env: env [

	<rosettaPlaceholderName: 'url-authority'>
	
	^ url authority
]

{ #category : #placeholders }
RosettaURLParsingRFCUrlSuite >> urlParse: urlString env: env [

	<rosettaPlaceholderName: 'url-parse'>

	^ HierarchicalUrl absoluteFromText: urlString
]

{ #category : #placeholders }
RosettaURLParsingRFCUrlSuite >> urlScheme: url env: env [

	<rosettaPlaceholderName: 'url-scheme'>

	^ url scheme
]
