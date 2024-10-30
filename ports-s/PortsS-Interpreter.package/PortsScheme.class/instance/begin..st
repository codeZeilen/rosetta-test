LISP-special forms
begin: aConsCell

"(begin BODY)
Eval BODY sequentially; return the value from last evaluation"

	| val cell |
	cell := aConsCell.
	[val := self evalObject: cell car.
	cell := cell cdr.]
		doWhileTrue: [cell notNil].
	^ val