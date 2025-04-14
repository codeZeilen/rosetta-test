Class {
	#name : #RosettaSuite,
	#superclass : #TestCase,
	#instVars : [
		'scheme',
		'rosettaEnvironment',
		'rootCapability',
		'version',
		'specName',
		'sources',
		'placeholders',
		'allTests',
		'placeholderFunctions',
		'setupFunctions',
		'teardownFunctions'
	],
	#classVars : [
		'CacheTimestamp'
	],
	#classInstVars : [
		'CachedTestNames',
		'CacheTimestamp'
	],
	#category : #'RosettaS-Core'
}

{ #category : #accessing }
RosettaSuite class >> allTestSelectors [

	^ [self testSelectors] on: Error do: [#()]
]

{ #category : #testing }
RosettaSuite class >> isAbstract [

	^self name = #RosettaSuite
			
]

{ #category : #testing }
RosettaSuite class >> isTestClass [
	^ true
]

{ #category : #accessing }
RosettaSuite class >> testSelectors [

	| tempInstance |
	tempInstance := self new.
	CacheTimestamp ifNil: [CacheTimestamp := DateAndTime now].
	(DateAndTime now - CacheTimestamp) > 2 seconds ifTrue: [
		CacheTimestamp := DateAndTime now.
		CachedTestNames := (tempInstance allTests collect: [:test |
			(tempInstance testNameOf: test) asSymbol])].
	^ CachedTestNames ifNil: [#()]
]

{ #category : #running }
RosettaSuite >> allTests [ 

	self assert: self suite notNil.
	allTests ifNil: [
		allTests := self 
			schemeEval: '(select-tests (capability-all-tests root-capability) only-tests only-capabilities exclude-tests exclude-capabilities)' 
			with: (Dictionary newFrom: {
				#'root-capability' -> rootCapability.
				#'only-tests' -> self onlyTests.
				#'only-capabilities' -> self onlyCapabilities.
				#'exclude-tests' -> self excludeTests.
				#'exclude-capabilities' -> self excludeCapabilities })].
	^ allTests
]

{ #category : #accessing }
RosettaSuite >> capabilityIdentifierOf: aRosettaTestObject [ 
	
	^ (self 
		schemeEval: '(capability-full-name (test-capability the-test))' 
		with: (Dictionary newFrom: {
			#'the-test' -> aRosettaTestObject})) asSymbol.
]

{ #category : #'private-rosetta' }
RosettaSuite >> createPlaceholder: aConsCell [

	| newPlaceholder |
	newPlaceholder := RosettaPlaceholder new
		placeholderName: aConsCell first;
		parameters: aConsCell second;
		docString: aConsCell third;
		env: self rosettaEnvironment.
		
	self rosettaEnvironment 
		at: newPlaceholder placeholderName asSymbol
		put: newPlaceholder.
		
	
	newPlaceholder
		function: (placeholderFunctions at: aConsCell first ifAbsent: nil).
		
	^ newPlaceholder
]

{ #category : #'test selection' }
RosettaSuite >> excludeCapabilities [
	"Use this method to specify that the tests from the listed capabilities should not be executed."

	^ #()
]

{ #category : #'test selection' }
RosettaSuite >> excludeTests [
	"Use this method to specify that the listed tests should not be executed. Has precedence over the capability exclusion mechanism."

	^ #()
]

{ #category : #running }
RosettaSuite >> fillPlaceholders [
	
	| placeholderMethods placeholderSelectorMap |
	placeholderMethods := self class localMethods select: [:m | 
			m pragmas anySatisfy: [:p | p keyword = #rosettaPlaceholderName:]]. 
	placeholderMethods := placeholderMethods groupBy: [:m | 
		m pragmas 
			detect: [:p | p keyword = #rosettaPlaceholderName:]
			ifFound: [:p | p argumentAt: 1]
			ifNone: [self error]].
	(placeholderMethods select: [:group | group size > 1]) keysAndValuesDo: [:placeholderName :methods | 
		Notification signal: 'Duplicate placeholder method for: ' , placeholderName].
		
	placeholderSelectorMap := placeholderMethods collect: [:group | group first selector].
	
	placeholders do: [:placeholder |
		placeholderSelectorMap 
			at: placeholder placeholderName
			ifPresent: [:placeholderSelector | 
				placeholder function: (MessageSend 
					receiver: self 
					selector: placeholderSelector)]].

]

{ #category : #running }
RosettaSuite >> gatherBridgeFunctions [

	| placeholderMethods |
	placeholderMethods := self class localMethods select: [:m | 
			m pragmas anySatisfy: [:p | p keyword = #rosettaPlaceholderName:]]. 
	placeholderMethods := placeholderMethods groupBy: [:m | 
		m pragmas 
			detect: [:p | p keyword = #rosettaPlaceholderName:]
			ifFound: [:p | p argumentAt: 1]
			ifNone: [self error]].
	(placeholderMethods select: [:group | group size > 1]) keysAndValuesDo: [:placeholderName :methods | 
		Notification signal: 'Duplicate placeholder method for: ' , placeholderName].
		
	placeholderFunctions := placeholderMethods collect: [:group | 
		MessageSend 
			receiver: self 
			selector: group first selector].
	
]

{ #category : #'private-rosetta' }
RosettaSuite >> isPlaceholderP: args [

	^ args first isKindOf: RosettaPlaceholder
]

{ #category : #'private-rosetta' }
RosettaSuite >> newRosettaEnvironment [

	| newEnvironment |
	newEnvironment := RosettaSchemeEnv new
		parent: self scheme topEnvironment;
		yourself.
		
	 self scheme evalString: self rosettaLibrarySource in: newEnvironment.

	newEnvironment 
		at: #assert put: [:args | 
			args size = 2
				ifTrue: [self assert: args first description: args second]
				ifFalse: [self assert: args first]];
		at: #'assert-equal' put: [:args | 
			args size = 3
				ifTrue: [self assert: args first equals: args second description: args third]
				ifFalse: [self assert: args first equals: args second]];
		at: #thread put: [:args | | newThread |
			newThread := [args first value: #()] newProcess.
			newThread resume.
			newThread];
		at: #'thread-wait-for-completion' put: [:args | args first terminate];
		at: #'thread-sleep!' put: [:args | Processor yield. args first seconds wait];
		at: #'create-placeholder' put: [:args | self createPlaceholder: args];
		at: #'is-placeholder?' put: [:args | self isPlaceholderP: args].
	
	^ newEnvironment
]

{ #category : #'test selection' }
RosettaSuite >> onlyCapabilities [
	"Use this method to specify that only tests form the listed capabilities and NO other should be executed. Has precedence over all exclude mechanisms."

	^ #()
]

{ #category : #'test selection' }
RosettaSuite >> onlyTests [
	"Use this method to specify that only the listed tests and NO other should be executed. Has precedence over all other selection mechanisms."

	^ #()
]

{ #category : #running }
RosettaSuite >> performTest [

	^ self allTests 
		detect: [:test | (self testNameOf: test) = testSelector]
		ifFound: [:test | self rosettaRunTest: test]
]

{ #category : #'private-rosetta' }
RosettaSuite >> rosettaEnvironment [

	^ rosettaEnvironment ifNil: [rosettaEnvironment := self newRosettaEnvironment]
]

{ #category : #'private-rosetta' }
RosettaSuite >> rosettaLibrarySource [

	^ (FileDirectory default / '..' / '..' / #rosetta / #rosetta) readOnlyFileNamed: 'rosetta.scm' do: [:rosettaFile |
		rosettaFile contents]
]

{ #category : #running }
RosettaSuite >> rosettaRun [

	"self assert: self suite notNil.
	self 
		fillPlaceholders;
		installPlaceholders.
	
	self allTests do: [:rosettaTest |
		self rosettaRunTest: rosettaTest]."
]

{ #category : #running }
RosettaSuite >> rosettaRunTest: aRosettaTest [

	self assert: self suite notNil.
	self 
		schemeEval: '(test-run current-test)' 
		with: (Dictionary newFrom: {
			#'current-test' -> aRosettaTest}).
]

{ #category : #'suite definition' }
RosettaSuite >> readSuiteFileNamed: suiteFileName [

	^ ((FileDirectory on: ThisOSProcess thisOSProcess getCwd) / 'suites') 
			readOnlyFileNamed: suiteFileName 
			do: [:fs | fs contents]
]

{ #category : #'private-scheme-evaluation' }
RosettaSuite >> scheme [

	^ scheme ifNil: [scheme := RosettaScheme new]
]

{ #category : #'private-scheme-evaluation' }
RosettaSuite >> schemeEval: schemeSource [

	^ self schemeEval: schemeSource in: self rosettaEnvironment
]

{ #category : #'private-scheme-evaluation' }
RosettaSuite >> schemeEval: schemeSource in: anEnvironment [

	^ self scheme 
		evalString: schemeSource
		in: anEnvironment
]

{ #category : #'private-scheme-evaluation' }
RosettaSuite >> schemeEval: schemeSource with: argumentDict [

	| newEnv |
	newEnv := RosettaSchemeEnv new
				parent: self rosettaEnvironment;
				yourself.
				
	argumentDict keysAndValuesDo: [:key :value |
		newEnv at: key put: value].

	^ self scheme 
		evalString: schemeSource
		in: newEnv
]

{ #category : #accessing }
RosettaSuite >> suite [
	
	 ^ rootCapability ifNil: [ | specData |
		self gatherBridgeFunctions.
		
		specData := self schemeEval: self suiteSource.
		specName := specData first.
		version := specData second.
		sources := specData third.
		placeholders := specData fourth.
		rootCapability := specData fifth.]
]

{ #category : #'suite definition' }
RosettaSuite >> suiteSource [
	"Should read the suite source code from somewhere, can contain the suite verbatim"
	
	self subclassResponsibility
]

{ #category : #accessing }
RosettaSuite >> testNameOf: aRosettaTestObject [ 
	
	^ self 
		schemeEval: '(test-full-name the-test)' 
		with: (Dictionary newFrom: {
			#'the-test' -> aRosettaTestObject})
]

{ #category : #'running - timeout' }
RosettaSuite >> timeoutForSetUp [

	^ 10
]

{ #category : #'running - timeout' }
RosettaSuite >> timeoutForTest [

	^ 5
]

{ #category : #'suite validation' }
RosettaSuite >> validate [
	
	self assert: self suite notNil.
	self fillPlaceholders.
	^ placeholders select: [:placeholder |
		placeholder isValid not].
]
