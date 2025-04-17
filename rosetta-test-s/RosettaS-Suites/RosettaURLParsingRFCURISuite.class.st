Class {
	#name : #RosettaURLParsingRFCURISuite,
	#superclass : #RosettaSuite,
	#category : #'RosettaS-Suites'
}

{ #category : #placeholders }
RosettaURLParsingRFCURISuite >> parseError: parseResult env: env [

	<rosettaPlaceholderName: 'parse-error?'>

	^ parseResult isKindOf: Exception
]

{ #category : #'suite definition' }
RosettaURLParsingRFCURISuite >> suiteSource [

	^ self readSuiteFileNamed: 'url-parsing-rfc.ros'
]

{ #category : #placeholders }
RosettaURLParsingRFCURISuite >> urlAuthority: uri env: env [

	<rosettaPlaceholderName: 'url-authority'>
	
	^ uri authority asString
]

{ #category : #placeholders }
RosettaURLParsingRFCURISuite >> urlParse: urlString env: env [

	<rosettaPlaceholderName: 'url-parse'>

	^ urlString asURI
]

{ #category : #placeholders }
RosettaURLParsingRFCURISuite >> urlScheme: uri env: env [

	<rosettaPlaceholderName: 'url-scheme'>
	
	^ uri scheme asString
]
