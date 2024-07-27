private-testing
isPair: anObject

	^ anObject isCollection and: [anObject isString not] and: [anObject notEmpty]