accessing
portsEnvironment

	^ portsEnvironment ifNil: [LK1Environment new
		parent: self scheme topmostLisp lispEnvironment;
		yourself]