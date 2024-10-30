LISP-functions-ports
nullP: args

	^ args first isNil or: [args isCollection and: [args isEmpty]]