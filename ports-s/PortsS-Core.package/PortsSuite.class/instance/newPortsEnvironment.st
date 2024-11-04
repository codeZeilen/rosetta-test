private-ports
newPortsEnvironment

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