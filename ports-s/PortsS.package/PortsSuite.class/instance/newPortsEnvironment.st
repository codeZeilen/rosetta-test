private-ports
newPortsEnvironment

	| newEnvironment |
	newEnvironment := PortsSchemeEnv new
		parent: self scheme topEnvironment;
		yourself.

	newEnvironment 
		at: #assert put: [:args | self assert: args first];
		at: #'assert-equal' put: [:args | self assert: args first equals: args second].
	
	^ newEnvironment