suite validation
validate
	
	self assert: self suite notNil.
	self fillPlaceholders.
	^ placeholders select: [:placeholder |
		placeholder isValid not].