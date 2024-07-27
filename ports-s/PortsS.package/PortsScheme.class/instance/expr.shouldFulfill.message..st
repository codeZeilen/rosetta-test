macro expansion
expr: exprs shouldFulfill: aBoolean message: aMessage

	aBoolean ifFalse: [
		PortsSyntaxError signal: aMessage , ' in ', exprs printString].