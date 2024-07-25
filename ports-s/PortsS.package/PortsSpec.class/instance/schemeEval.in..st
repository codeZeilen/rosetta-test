private-scheme-evaluation
schemeEval: schemeSource in: anEnvironment

	| expr |
	expr := self schemeParse: schemeSource.
	^ self scheme 
		eval: expr
		inEnvironment: anEnvironment