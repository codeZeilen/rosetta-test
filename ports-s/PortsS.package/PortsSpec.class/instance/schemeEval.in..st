private-scheme-evaluation
schemeEval: schemeSource in: anEnvironment

	^ self scheme 
		evalString: schemeSource
		in: anEnvironment