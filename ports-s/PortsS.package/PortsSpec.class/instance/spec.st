accessing
spec
	
	 ^ spec ifNil: [self schemeEval: self specSource]