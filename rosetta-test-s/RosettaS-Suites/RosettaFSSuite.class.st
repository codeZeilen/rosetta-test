Class {
	#name : #RosettaFSSuite,
	#superclass : #RosettaSuite,
	#instVars : [
		'streams'
	],
	#category : #'RosettaS-Suites'
}

{ #category : #'spec definition' }
RosettaFSSuite >> closeFile: file env: env [

	<rosettaPlaceholderName: #close> 
	file close.
]

{ #category : #'spec definition' }
RosettaFSSuite >> createTestFile: fileName content: content env: env [

	<rosettaPlaceholderName: #'create-test-file'> 
	FileStream fileNamed: fileName do: [:stream |
		stream nextPutAll: content].
]

{ #category : #failures }
RosettaFSSuite >> expectedFailures [

	^ #('read on a write-only file is an error')
]

{ #category : #'spec definition' }
RosettaFSSuite >> flushFile: file  env: env [

	<rosettaPlaceholderName: #flush> 
	file flush.
]

{ #category : #'initialize-release' }
RosettaFSSuite >> initialize [

	super initialize.
	streams := Set new.
]

{ #category : #'spec definition' }
RosettaFSSuite >> isFileDescriptor: file  env: env [

	<rosettaPlaceholderName: #'is-file-descriptor?'> 
	^ file isKindOf: FileStream
]

{ #category : #'spec definition' }
RosettaFSSuite >> isFileError: obj env: env [

	<rosettaPlaceholderName: #'is-file-error?'> 
	^ obj isKindOf: Exception	
]

{ #category : #'spec definition' }
RosettaFSSuite >> openFile: fileName mode: mode env: env [

	<rosettaPlaceholderName: #open> 
	mode = 'r' ifTrue: [
		^ streams add: (FileStream readOnlyFileNamed: fileName)].
	mode = 'w' ifTrue: [
		^ streams add: (FileStream fileNamed: fileName)].
	^ Error new
]

{ #category : #'spec definition' }
RosettaFSSuite >> readFile: file length: length  env: env [

	<rosettaPlaceholderName: #read>
	^ file next: length
]

{ #category : #'spec definition' }
RosettaFSSuite >> removeTestFile: fileName env: env [

	<rosettaPlaceholderName: #'remove-test-file'> 
	FileDirectory default deleteFileNamed: fileName.
]

{ #category : #'spec definition' }
RosettaFSSuite >> suiteSource [

	^ self readSuiteFileNamed: 'fs.ros'
]

{ #category : #running }
RosettaFSSuite >> tearDown [

	streams do: [:s | s close].
]

{ #category : #'spec definition' }
RosettaFSSuite >> writeFile: file content: content  env: env [

	<rosettaPlaceholderName: #write> 
	file nextPutAll: content.
]
