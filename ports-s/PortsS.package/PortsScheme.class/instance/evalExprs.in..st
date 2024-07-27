evaluating
evalExprs: element in: env

	| x localEnv |
	x := element.	
	localEnv := env.
	
	[
	logging ifTrue: [Transcript showln: 'evaluating: ' , x printAsTree].
 	true 
		caseOf: {
			[x isSymbol] -> [ "symbol lookup"
				^ localEnv at: x].
			[(self isList: x) not] -> [  "literal"
				^ x].
			[#quote = x first] -> [ 
				^ x second].
			[#if = x first] -> [ 
				x := (self evalExprs: x second in: localEnv)
					ifTrue: [x third]
					ifFalse: [x fourth]].
			[#cond = x first] -> [  
				x allButFirst 
					detect: [:case | | test |
						test := case first.
						test = #else or: [self evalExprs: test in: localEnv]]
					ifFound: [:case |
						x := case second]
					ifNone: [^ nil]].
			[#'set!' = x first] -> [ 
				(localEnv find: x second) 
					at: x second
					put: (self evalExprs: x third in: localEnv)].
			[#'variable-unset!' = x first] -> [ 
				(localEnv find: x second) unset: x second].
			[#define = x first] -> [ 
				localEnv at: x second put: (self evalExprs: x third in: localEnv).
				^ nil].
			[#begin = x first] -> [ 
				x allButFirst allButLast do: [:beginElement |
					self evalExprs: beginElement in: localEnv].
				x := x last].
			[#lambda = x first] -> [ 
				^ PortsSchemeLambda new
					params: x second;
					body: x third;
					env: localEnv;
					interpreter: self;
					yourself]}
		otherwise: [ | evaluatedElements executableElement |
			"no special form"
			evaluatedElements := x collect: [:exp | self evalExprs: exp in: localEnv].
			executableElement := evaluatedElements first.
			true caseOf: {
					[executableElement isPortsSchemeProcedure] -> [
						x := executableElement body.
						localEnv := PortsSchemeEnv new
							setBindingsFor: executableElement params to: evaluatedElements allButFirst;
							parent: localEnv;
							yourself].
					[executableElement isPortsSchemePrimitive] -> [
						^ executableElement value: evaluatedElements allButFirst]}
				otherwise: [
					self error: 'Invalid expression: ' , x printString]].
	] repeat.