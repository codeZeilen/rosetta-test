accessing
spec
	
	 ^ rootCapability ifNil: [ | specData |
		specData := self schemeEval: self specSource.
		specName := specData first.
		version := specData second.
		sources := specData third.
		placeholders := specData fourth.
		rootCapability := specData fifth.]