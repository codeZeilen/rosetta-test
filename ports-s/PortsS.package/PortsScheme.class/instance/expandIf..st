macro expansion
expandIf: exprs

	| resultExprs |
	resultExprs := exprs.
	"Expand short form: (if t c) -> (if t c nil)"
	exprs size = 3 ifTrue: [
		resultExprs := resultExprs , {nil}].
	self expr: resultExprs shouldFulfill: resultExprs size = 4.
	^ resultExprs collect: [:expr | self expand: expr]