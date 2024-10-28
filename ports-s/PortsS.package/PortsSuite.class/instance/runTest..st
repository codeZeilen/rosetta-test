running
runTest: aPortsTest

	self assert: self suite notNil.
	self 
		schemeEval: '(test-run current-test)' 
		in: (PortsSchemeEnv new
			at: #'current-test' put: aPortsTest;
			parent: self portsEnvironment;
			yourself).