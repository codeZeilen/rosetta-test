Class {
	#name : #PortsFSSuite,
	#superclass : #PortsSuite,
	#instVars : [
		'streams'
	],
	#category : #'PortsS-Suites'
}

{ #category : #'spec definition' }
PortsFSSuite >> closeFile: file env: env [

	<portsPlaceholderName: #close> 
	file close.
]

{ #category : #'spec definition' }
PortsFSSuite >> createTestFile: fileName content: content env: env [

	<portsPlaceholderName: #'create-test-file'> 
	FileStream fileNamed: fileName do: [:stream |
		stream nextPutAll: content].
]

{ #category : #failures }
PortsFSSuite >> expectedFailures [

	^ #('read on a write-only file is an error')
]

{ #category : #'spec definition' }
PortsFSSuite >> flushFile: file  env: env [

	<portsPlaceholderName: #flush> 
	file flush.
]

{ #category : #'initialize-release' }
PortsFSSuite >> initialize [

	super initialize.
	streams := Set new.
]

{ #category : #'spec definition' }
PortsFSSuite >> isFileDescriptor: file  env: env [

	<portsPlaceholderName: #'is-file-descriptor?'> 
	^ file isKindOf: FileStream
]

{ #category : #'spec definition' }
PortsFSSuite >> isFileError: obj env: env [

	<portsPlaceholderName: #'is-file-error?'> 
	^ obj isKindOf: Exception	
]

{ #category : #'spec definition' }
PortsFSSuite >> openFile: fileName mode: mode env: env [

	<portsPlaceholderName: #open> 
	mode = 'r' ifTrue: [
		^ streams add: (FileStream readOnlyFileNamed: fileName)].
	mode = 'w' ifTrue: [
		^ streams add: (FileStream fileNamed: fileName)].
	^ Error new
]

{ #category : #'spec definition' }
PortsFSSuite >> readFile: file length: length  env: env [

	<portsPlaceholderName: #read>
	^ file next: length
]

{ #category : #'spec definition' }
PortsFSSuite >> removeTestFile: fileName env: env [

	<portsPlaceholderName: #'remove-test-file'> 
	FileDirectory default deleteFileNamed: fileName.
]

{ #category : #'spec definition' }
PortsFSSuite >> suiteSource [

	^ (FileDirectory default / '..' / '..' / #ports / 'suites') readOnlyFileNamed: 'fs.ports' do: [:portsFile |
		portsFile contents]
]

{ #category : #running }
PortsFSSuite >> tearDown [

	streams do: [:s | s close].
]

{ #category : #'spec definition' }
PortsFSSuite >> writeFile: file content: content  env: env [

	<portsPlaceholderName: #write> 
	file nextPutAll: content.
]
