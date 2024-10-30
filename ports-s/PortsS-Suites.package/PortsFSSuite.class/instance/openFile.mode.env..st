spec definition
openFile: fileName mode: mode env: env

	<portsPlaceholderName: #open> 
	mode = 'r' ifTrue: [
		^ streams add: (FileStream readOnlyFileNamed: fileName)].
	mode = 'w' ifTrue: [
		^ streams add: (FileStream fileNamed: fileName)].
	^ Error new