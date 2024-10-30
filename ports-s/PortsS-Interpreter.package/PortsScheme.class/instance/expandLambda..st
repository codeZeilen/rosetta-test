macro expansion
expandLambda: exprs

	| parameters body finalBody |
	self expr: exprs shouldFulfill: exprs size >= 3.
	parameters := exprs second.
	body := exprs allButFirst: 2.
	self 
		expr: exprs 
		shouldFulfill: (parameters isSymbol or: [parameters isCollection and: [parameters allSatisfy: [:p | p isSymbol]]])
		message: 'lambda parameters need to be symbols'.
	finalBody := body size = 1 
		ifTrue: [body first]
		ifFalse: [#(begin) , body].
	^ {#lambda . parameters . self expand: finalBody}