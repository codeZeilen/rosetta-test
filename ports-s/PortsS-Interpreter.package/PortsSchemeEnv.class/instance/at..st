accessing
at: aSymbol

	^ bindings 
		at: aSymbol 
		ifAbsent: [
			self parent 
				ifNotNil: [self parent at: aSymbol]
				ifNil: ["TODO: This is thrown at the top env"
					self keyError: aSymbol]] 