accessing
testNameOf: anArray 
	
	^ self 
		schemeEval: '(test-name the-test)' 
		in: (PortsSchemeEnv new
			at: #'the-test' put: anArray;
			parent: self portsEnvironment;
			yourself).