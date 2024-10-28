running
allTests 

	self assert: self suite notNil.
	^ self 
		schemeEval: '(capability-all-tests root-capability)' 
		in: (PortsSchemeEnv new
			at: #'root-capability' put: rootCapability;
			parent: self portsEnvironment;
			yourself).