evaluating
evalExprs: element in: env

	| x localEnv evaluatedElements executableElement rules |
	x := element.	
	localEnv := env.
	rules := {{[x isSymbol] . [ "symbol lookup"
			^ env at: x]}.
		{[x isString] . [  "literal"
			^ x]}.
		{[x isCollection not] . [  "literal"
			^ x]}.
		{[x first = #quote ] . [ 
			^ x second]}.
		{[x first = #if ] . [ 
			x := (self evalExprs: x second in: localEnv)
				ifTrue: [x third]
				ifFalse: [x fourth]]}.
		{[x first = #cond ] . [  
			x allButFirst 
				detect: [:case | | test |
					test := case first.
					test = #else or: [self evalExprs: test in: localEnv]]
				ifFound: [:case |
					x := case second]
				ifNone: [^ nil]]}.
		{[x first = #'set!' ] . [ 
			(localEnv find: x second) 
				at: x second
				put: (self evalExprs: x third in: localEnv)]}.
		{[x first = #'variable-unset!' ] . [ 
			(localEnv find: x second) unset: x second]}.
		{[x first = #define ] . [ 
			localEnv at: x second put: (self evalExprs: x third in: localEnv)]}.
		{[x first = #begin ] . [ 
			x allButFirst allButLast do: [:beginElement |
				self evalExprs: beginElement in: localEnv].
			x := x last]}.
		{[x first = #lambda ] . [ 
			^ PortsSchemeLambda new
				params: x second;
				body: x third;
				env: localEnv;
				yourself]}.
		{[true] . [
			"no special form"
			evaluatedElements := x collect: [:exp | self evalExprs: exp in: localEnv].
			executableElement := evaluatedElements first.
			executableElement isPortsSchemeProcedure ifTrue: [
				x := executableElement body.
				localEnv := PortsSchemeEnv new
					bindings: (executableElement params 
						with: evaluatedElements allButFirst 
						collect: [:a :b | a -> b]);
					parent: localEnv;
					yourself].
			executableElement isPortsSchemePrimitive ifTrue: [
				^ executableElement value: evaluatedElements allButFirst].]}}.
	[
		rules detect: [:rule | rule first value] ifFound: [:rule | rule second value] ifNone: [self error].
	] repeat.