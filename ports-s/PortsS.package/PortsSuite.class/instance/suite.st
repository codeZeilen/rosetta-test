accessing
suite
	
	 ^ rootCapability ifNil: [ | specData |
		specData := self schemeEval: self suiteSource.
		specName := specData first.
		version := specData second.
		sources := specData third.
		placeholders := specData fourth.
		rootCapability := specData fifth.]