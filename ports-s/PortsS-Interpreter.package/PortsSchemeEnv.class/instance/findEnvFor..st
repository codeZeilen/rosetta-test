private
findEnvFor: aSymbol

	^ (bindings includesKey: aSymbol) 
		ifTrue: [self]
		ifFalse: [
			self parent 
				ifNil: [self keyError: aSymbol]
				ifNotNil: [self parent findEnvFor: aSymbol]]