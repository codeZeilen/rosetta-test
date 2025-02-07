Class {
	#name : #PortsSuite,
	#superclass : #TestCase,
	#instVars : [
		'scheme',
		'portsEnvironment',
		'rootCapability',
		'version',
		'specName',
		'sources',
		'placeholders',
		'allTests'
	],
	#classVars : [
		'CacheTimestamp'
	],
	#classInstVars : [
		'CachedTestNames',
		'CacheTimestamp'
	],
	#category : #'PortsS-Core'
}

{ #category : #accessing }
PortsSuite class >> allTestSelectors [

	^ self testSelectors
]

{ #category : #testing }
PortsSuite class >> isAbstract [

	^self name = #PortsSuite
			
]

{ #category : #testing }
PortsSuite class >> isTestClass [
	^ true
]

{ #category : #accessing }
PortsSuite class >> testSelectors [

	| tempInstance |
	tempInstance := self new.
	CacheTimestamp ifNil: [CacheTimestamp := DateAndTime now].
	(DateAndTime now - CacheTimestamp) > 2 seconds ifTrue: [
		CacheTimestamp := DateAndTime now.
		CachedTestNames := (tempInstance allTests collect: [:test |
			(tempInstance testNameOf: test) asSymbol])].
	^ CachedTestNames
]

{ #category : #running }
PortsSuite >> allTests [ 

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
PortsSuite >> capabilityIdentifierOf: aPortsTestObject [ 
	
	^ (self 
		schemeEval: '(capability-full-name (test-capability the-test))' 
		with: (Dictionary newFrom: {
			#'the-test' -> aPortsTestObject})) asSymbol.
]

{ #category : #'test selection' }
PortsSuite >> excludeCapabilities [
	"Use this method to specify that the tests from the listed capabilities should not be executed."

	^ #()
]

{ #category : #'test selection' }
PortsSuite >> excludeTests [
	"Use this method to specify that the listed tests should not be executed. Has precedence over the capability exclusion mechanism."

	^ #()
]

{ #category : #running }
PortsSuite >> fillPlaceholders [
	
	| placeholderMethods placeholderSelectorMap |
	placeholderMethods := self class localMethods select: [:m | 
			m pragmas anySatisfy: [:p | p keyword = #portsPlaceholderName:]]. 
	placeholderMethods := placeholderMethods groupBy: [:m | 
		m pragmas 
			detect: [:p | p keyword = #portsPlaceholderName:]
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
PortsSuite >> installPlaceholders [

	placeholders do: [:placeholder | 
		self portsEnvironment 
			at: placeholder placeholderName asSymbol
			put: placeholder]
]

{ #category : #'private-ports' }
PortsSuite >> newPortsEnvironment [

	| newEnvironment |
	newEnvironment := PortsSchemeEnv new
		parent: self scheme topEnvironment;
		yourself.

	newEnvironment 
		at: #assert put: [:args | 
			args size = 2
				ifTrue: [self assert: args first description: args second]
				ifFalse: [self assert: args first]];
		at: #'assert-equal' put: [:args | 
			args size = 3
				ifTrue: [self assert: args second equals: args first description: args third]
				ifFalse: [self assert: args second equals: args first]];
		at: #thread put: [:args | | newThread |
			newThread := [args first value: #()] newProcess.
			newThread resume.
			newThread];
		at: #'thread-wait-for-completion' put: [:args | args first terminate];
		at: #'thread-sleep!' put: [:args | args first seconds wait].
		
	
	^ newEnvironment
]

{ #category : #'test selection' }
PortsSuite >> onlyCapabilities [
	"Use this method to specify that only tests form the listed capabilities and NO other should be executed. Has precedence over all exclude mechanisms."

	^ #()
]

{ #category : #'test selection' }
PortsSuite >> onlyTests [
	"Use this method to specify that only the listed tests and NO other should be executed. Has precedence over all other selection mechanisms."

	^ #()
]

{ #category : #running }
PortsSuite >> performTest [

	^ self allTests 
		detect: [:test | (self testNameOf: test) = testSelector]
		ifFound: [:test | self portsRunTest: test]
]

{ #category : #'private-ports' }
PortsSuite >> portsEnvironment [

	^ portsEnvironment ifNil: [portsEnvironment := self newPortsEnvironment]
]

{ #category : #'private-ports' }
PortsSuite >> portsLibrarySource [

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'ports.scm' do: [:portsFile |
		portsFile contents]
]

{ #category : #running }
PortsSuite >> portsRun [

	"self assert: self suite notNil.
	self 
		fillPlaceholders;
		installPlaceholders.
	
	self allTests do: [:portsTest |
		self portsRunTest: portsTest]."
]

{ #category : #running }
PortsSuite >> portsRunTest: aPortsTest [

	self assert: self suite notNil.
	self 
		schemeEval: '(test-run current-test)' 
		with: (Dictionary newFrom: {
			#'current-test' -> aPortsTest}).
]

{ #category : #'private-scheme-evaluation' }
PortsSuite >> scheme [

	^ scheme ifNil: [scheme := PortsScheme new]
]

{ #category : #'private-scheme-evaluation' }
PortsSuite >> schemeEval: schemeSource [

	^ self schemeEval: schemeSource in: self portsEnvironment
]

{ #category : #'private-scheme-evaluation' }
PortsSuite >> schemeEval: schemeSource in: anEnvironment [

	^ self scheme 
		evalString: schemeSource
		in: anEnvironment
]

{ #category : #'private-scheme-evaluation' }
PortsSuite >> schemeEval: schemeSource with: argumentDict [

	| newEnv |
	newEnv := PortsSchemeEnv new
				parent: self portsEnvironment;
				yourself.
				
	argumentDict keysAndValuesDo: [:key :value |
		newEnv at: key put: value].

	^ self scheme 
		evalString: schemeSource
		in: newEnv
]

{ #category : #accessing }
PortsSuite >> suite [
	
	 ^ rootCapability ifNil: [ | specData |
		specData := self schemeEval: self suiteSource.
		specName := specData first.
		version := specData second.
		sources := specData third.
		placeholders := specData fourth.
		rootCapability := specData fifth.
		
		self 
			fillPlaceholders;
			installPlaceholders]
]

{ #category : #'suite definition' }
PortsSuite >> suiteSource [
	"Should read the suite source code from somewhere, can contain the suite verbatim"
	
	self subclassResponsibility
]

{ #category : #accessing }
PortsSuite >> testNameOf: aPortsTestObject [ 
	
	^ self 
		schemeEval: '(test-full-name the-test)' 
		with: (Dictionary newFrom: {
			#'the-test' -> aPortsTestObject})
]

{ #category : #'running - timeout' }
PortsSuite >> timeoutForSetUp [

	^ 10
]

{ #category : #'running - timeout' }
PortsSuite >> timeoutForTest [

	^ 5
]

{ #category : #'suite validation' }
PortsSuite >> validate [
	
	self assert: self suite notNil.
	self fillPlaceholders.
	^ placeholders select: [:placeholder |
		placeholder isValid not].
]
