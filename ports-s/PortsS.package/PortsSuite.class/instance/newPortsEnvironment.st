private-ports
newPortsEnvironment

	| newEnvironment |
	newEnvironment := PortsSchemeEnv new
		parent: self scheme topEnvironment;
		yourself.
		
	self schemeEval: self portsLibrarySource in: newEnvironment.
	
	newEnvironment 
		at: #true put: true;
		at: #false put: false;
		at: #assert put: [:args | self assert: args first];
		at: #'assert-equal' put: [:args | self assert: args first equals: args second].
	
	^ newEnvironment