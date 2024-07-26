evaluating
evalString: aString in: anEnvironment

	| exprs |
	exprs := ((ULispReader for: ULisp new) readString: aString) arrayForm.
	^ self evalExprs: exprs in: anEnvironment