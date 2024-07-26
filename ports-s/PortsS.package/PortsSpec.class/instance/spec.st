accessing
spec
	
	 ^ rootCapability ifNil: [ | specData setups tearDowns capabilities |
		specData := self schemeEval: self specSource.
		specName := specData car.
		version := specData cdr car.
		sources := specData cdr cdr car.
		placeholders := specData cdr cdr cdr car.

		specData := specData cdr cdr cdr cdr.
		capabilities := specData car.
		setups := specData cdr car.
		tearDowns := specData cdr cdr car.
		capabilities append: setups.
		capabilities append: tearDowns.
		rootCapability := self createRootCapability: capabilities.]