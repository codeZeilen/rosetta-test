macro expansion
expandDefineAndMacro: exprs topLevel: isTopLevel
	"Covers define and define-macro"

	| body define variable |
	self expr: exprs shouldFulfill: exprs size >= 3.
	define := exprs first.
	variable := exprs second.
	body := exprs allButFirst: 2.
	
	((self isList: variable) and: [variable notEmpty]) 
		ifTrue: [ | functionName parameters | "define a function"
			functionName := variable first.
			parameters := variable allButFirst.
			^ self expand: {define . functionName . {#lambda . parameters}, body}]
		ifFalse: ["define a value"
			self expr: exprs shouldFulfill: exprs size = 3.
			self expr: exprs shouldFulfill: variable isSymbol message: 'define should receive a symbol as the variable name'.
			body := self expand: exprs third.
			#'define-macro' = define ifTrue: [ | macroProcedure |
				self expr: exprs shouldFulfill: isTopLevel message: 'macros can only be defined at top-level'.
				macroProcedure  := self eval: body.
				self expr: exprs shouldFulfill: macroProcedure isPortsSchemeProcedure message: 'macros needs to be a procedure'.
				macroTable at: variable put: macroProcedure. 
				^ nil].
			^ {define . variable . body}]
	
	