LISP-functions-ports
listSetD: aConsCell

	| list |
	list := aConsCell first cells.
	(list at: aConsCell second) car: aConsCell third.
	