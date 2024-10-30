macro expansion
expandSet: exprs

	self expr: exprs shouldFulfill: exprs size = 3.
	self expr: exprs shouldFulfill: exprs second isSymbol message: 'set! should receive a symbol as the variable name'.
	^ {exprs first . exprs second . self expand: exprs third}