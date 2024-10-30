LISP-functions-ports
createPlaceholder: aConsCell

	^ PortsPlaceholder new
		placeholderName: aConsCell first;
		parameters: aConsCell second;
		docString: aConsCell third