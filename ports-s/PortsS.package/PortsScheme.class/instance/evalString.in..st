evaluating
evalString: aString in: anEnvironment

	| exprs |
	exprs := ((ULispReader for: ULisp new) readString: aString) arrayForm.
	exprs := self expand: exprs topLevel: true.
	^ self evalExprs: exprs in: anEnvironment