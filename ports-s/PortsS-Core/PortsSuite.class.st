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
	#category : #'PortsS-Core'
}

{ #category : #testing }
PortsSuite class >> isAbstract [

	^self name = #PortsSuite
			
]

{ #category : #running }
PortsSuite >> allTests [ 

	self assert: self suite notNil.
	allTests ifNil: [
		allTests := self 
			schemeEval: '(capability-all-tests root-capability)' 
			in: (PortsSchemeEnv new
				at: #'root-capability' put: rootCapability;
				parent: self portsEnvironment;
				yourself)].
	^ allTests
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
		in: (PortsSchemeEnv new
			at: #'current-test' put: aPortsTest;
			parent: self portsEnvironment;
			yourself).
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
PortsSuite >> testNameOf: anArray [ 
	
	^ self 
		schemeEval: '(test-name the-test)' 
		in: (PortsSchemeEnv new
			at: #'the-test' put: anArray;
			parent: self portsEnvironment;
			yourself).
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
