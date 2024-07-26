private-ports
createRootCapability: capabilityContents

	 ^ self 
		schemeEval: '(capability "root" root-contents)' 
		in: (LK1Environment new
			addSymbolValue: #'root-contents' -> capabilityContents;
			parent: self portsEnvironment;
			yourself)