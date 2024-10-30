macros
macroLet: args

	"args = list(args)
	    x = cons(_let, args)
	    require(x, len(args)>1)
	    bindings, body = args[0], args[1:]
	    require(x, all(isa(b, list) and len(b)==2 and isa(b[0], Symbol)
	                   for b in bindings), 'illegal binding list')
	    vars, vals = zip(*bindings)
	    return [[_lambda, list(vars)]+list(map(expand, body))] + list(map(expand, vals))"
	
	| bindings body vals vars |
	self expr: #(let), args shouldFulfill: args size > 1.
	bindings := args first.
	body := self expand: args allButFirst.
	
	self 
		expr: #(let), args
		shouldFulfill: (bindings allSatisfy: [:binding | binding size = 2 and: [binding first isSymbol]])
		message: 'illegal binding list'.
	vars := bindings collect: #first.
	vals := bindings collect: #second.
	vals := self expand: vals.
	
	^ {({#lambda . vars} , body)} , vals