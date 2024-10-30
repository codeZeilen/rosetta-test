accessing
setBindingsFor: paramOrParams to: arguments

	paramOrParams isSymbol ifFalse: [
		paramOrParams size = arguments size ifFalse: [PortsTypeError signal]].
	self bindings: (paramOrParams isSymbol
		ifTrue: [{paramOrParams -> arguments}]
		ifFalse: [
			paramOrParams
				with: arguments
				collect: [:a :b | a -> b]]).