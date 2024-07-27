accessing
setBindingsFor: paramOrParams to: arguments

	self bindings: (paramOrParams isSymbol
		ifTrue: [{paramOrParams -> arguments}]
		ifFalse: [
			paramOrParams
				with: arguments
				collect: [:a :b | a -> b]]).