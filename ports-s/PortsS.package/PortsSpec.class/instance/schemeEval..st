private-scheme-evaluation
schemeEval: schemeSource

	| expr |
	expr := self schemeParse: schemeSource.
	self scheme 
		eval: expr
		inEnvironment: self portsEnvironment.