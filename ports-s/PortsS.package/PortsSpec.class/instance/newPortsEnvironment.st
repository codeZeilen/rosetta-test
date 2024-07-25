accessing
newPortsEnvironment

	| newEnvironment |
	newEnvironment := LK1Environment new
		parent: self scheme topmostLisp lispEnvironment;
		yourself.
		
	self schemeEval: self portsLibrarySource in: newEnvironment.
	
	newEnvironment 
		addSymbolValue: #true -> true;
		addSymbolValue: #false -> false.
	
	^ newEnvironment