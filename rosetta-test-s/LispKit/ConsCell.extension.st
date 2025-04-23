Extension { #name : #ConsCell }

{ #category : #'*LispKit-evaluation' }
ConsCell >> applyInTailTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ self applyTo: aConsCell inLisp: aLisp withEnvironment: aLisp lispEnvironment asMacro: mflag noSubLisp: true

]

{ #category : #'*LispKit-evaluation' }
ConsCell >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	^ self applyTo: aConsCell inLisp: aLisp withEnvironment: aLisp lispEnvironment asMacro: mflag

]

{ #category : #'*LispKit-evaluation' }
ConsCell >> applyTo: args inLisp: aLisp withEnvironment: env asMacro: mflag [

" this is the core place for function application in LispKit

	args is a ConsCell providing the procedure arguments 
	mflag when true forces the arguments to be kept unevaluated
		just as they would for a macro invocation (while a false 
		value does not mean macro arguments are evaluated btw)
	env provides the environment for the procedure body
"
	| sublisp val body macrop arguments |

	body := cdr cdr.
	macrop := car == #macro .

	sublisp := aLisp subLisp: car 
				form: self body: body 
				environment: env newChild. 

	"evaluating (or not) the arguments"
	arguments := (mflag | macrop) ifTrue: [args] ifFalse: [aLisp evalList: args].

 	body ifNil: [^ nil].

	(self lambdaFormBindingsWith: arguments) 
		do: [:binding | 
				aLisp checkSymbol: binding key.
				sublisp symbolValuesAdd: binding].

	body doWithCdr: [:form :formcdr | 
		formcdr 
			ifNotNil: [sublisp evalObject: form]
			ifNil: [val := macrop 
						ifTrue: [sublisp evalObject: form]
						ifFalse: [sublisp evalTailObject: form]]].
		
	macrop ifTrue: [^ aLisp evalObject: val multipleValue: true].

	^ val
]

{ #category : #'*LispKit-evaluation' }
ConsCell >> applyTo: args inLisp: aLisp withEnvironment: env asMacro: mflag noSubLisp: sflag [

" this is the core place for function application in LispKit

	args is a ConsCell providing the procedure arguments 
	mflag when true forces the arguments to be kept unevaluated
		just as they would for a macro invocation (while a false 
		value does not mean macro arguments are evaluated btw)
	env provides the environment for the procedure body
"
	| sublisp val body macrop arguments |

	body := cdr cdr.
	macrop := car == #macro .

	"evaluating (or not) the arguments"
	arguments := (mflag | macrop) ifTrue: [args] ifFalse: [aLisp evalList: args].

	body ifNil: [^ nil].

	sublisp := sflag
		 ifTrue: [ aLisp subLispForTailWithEnvironment: env ]
		ifFalse: [ aLisp subLisp: car 
					form: self body: body 
					environment: env newChild]. 

	(self lambdaFormBindingsWith: arguments) 
		do: [:binding | 
				aLisp checkSymbol: binding key.
				sublisp symbolValuesAdd: binding].

	body doWithCdr: [:form :formcdr | 
		formcdr 
			ifNotNil: [sublisp evalObject: form]
			ifNil: [val := macrop 
						ifTrue: [sublisp evalObject: form]
						ifFalse: [sublisp evalTailObject: form]]].
		
	macrop ifTrue: [^ aLisp evalObject: val multipleValue: true].

	^ val
]

{ #category : #'*LispKit-evaluation' }
ConsCell >> bindingsWithArguments: aConsCell [

	"the receiver is a lambda form arguments specification, such as (x y) or
(a &optional b c). return the actual bindings when given aConsCell as arguments.

	this method provides only minimal arguments list parsing:
	handles &rest and &optional (no other keyword implemented).
	&body and . are synonyms of &rest"

	| symbs vals optf bindings n |

	symbs := self.
	(vals := aConsCell) ifNil: [^ {symbs cadr -> nil}].

	optf := false.
	bindings := Array new: symbs safeLength.
	n := 0.

	[symbs isNil and: [vals isNil]] whileFalse: 
	[
		| val sym |
		sym := symbs car ifNil: [LispKernel lispError: 'too many arguments'].
		symbs := symbs cdr.
		n := n + 1.

		(sym == #'&optional') 
			ifTrue: [optf := true . sym := symbs car. symbs := symbs cdr].

		(sym == #'&rest' or: [sym == #'&body'])
			ifTrue: [	
				val := vals.
				bindings at: n put: (symbs car -> val).
				^ bindings cutAt: n].

		vals ifNil: [optf ifFalse: [LispKernel lispError: 'not enough arguments']].
		val := vals car. 
		vals := vals cdr.
		bindings at: n put: (sym -> val).

		symbs isSymbol ifTrue: [
			val := vals.
			bindings at: n+1 put: (symbs -> val).
			^ bindings cutAt: n+1]
	].

	^ bindings cutAt: n
]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> cut: delim [

	self nest: delim.
	cdr car = delim second ifTrue: [^ self].
	^ cdr cut: delim
	

]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> cut: del with: o [

	self nest: del with: o.
	cdr car == del second ifTrue: [^ self].
	^ cdr cut: del with: o
	

]

{ #category : #'*LispKit-procedure protocol' }
ConsCell >> formatForDocumentationString [

	^ self collect: [:str | | s |

		"SScheme special:
		SLIB 'macros-that-work rename the variables, so get the name back"
		s := (str subStrings: 'û') first. 

		(s first = $& or: [s first = $:]) 
			ifTrue: [s asSymbol] ifFalse: [s asUppercase asSymbol]]
]

{ #category : #'*LispKit-procedure protocol' }
ConsCell >> isProcedure [

	^ car == #lambda or: [car == #macro]
]

{ #category : #'*LispKit-testing' }
ConsCell >> isQuotedCons [

	^ car == #quote or: [car == #quote:]
]

{ #category : #'*LispKit-testing' }
ConsCell >> isQuotedSymbol [

	^ (car == #quote or: [car == #quote:]) and: [cdr car isSymbol]
]

{ #category : #'*LispKit-procedure protocol' }
ConsCell >> lambdaForm [

	(car == #lambda or: [car == #macro])
		ifTrue: [^ self] ifFalse: [self error: 'not a lambda form']
]

{ #category : #'*LispKit-evaluation' }
ConsCell >> lambdaFormBindingsWith: aConsCell [

	"the receiver being a lambda form,  return the bindings when given aConsCell as arguments"

	^ (self second ifNil: [^ #()]) bindingsWithArguments: aConsCell

]

{ #category : #'*LispKit-conversion' }
ConsCell >> lispCode [

	^ self
]

{ #category : #'*LispKit-procedure protocol' }
ConsCell >> lispEnvironment [

	^ nil
]

{ #category : #'*LispKit-LKOS' }
ConsCell >> lkosClass: aLisp [

	^ LKOSInstance class: #'<pair>' inLisp: aLisp
]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> nest: delim [

	| cut |

	car isConsCell ifTrue: [car nest: delim].

	car = delim first ifFalse: [^ (cdr ifNil: [^ nil]) nest: delim].
	cut := cdr cut: delim.
	car := cdr.
	cdr := cut cdr cdr.
	cut setcdr: nil.
	cdr ifNotNil: [cdr nest: delim] 
]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> nest: del with: o [

	| cut |

	car isConsCell ifTrue: [car nest: del with: o].

	car == del first ifFalse: [^ (cdr ifNil: [^ nil]) nest: del with: o].
	cut := cdr cut: del with: o.
	car := (self class car: o cdr: (self class car: cdr)).
	cdr := cut cdr cdr.
	cut setcdr: nil.
	cdr ifNotNil: [cdr nest: del with: o] 
]

{ #category : #'*LispKit-evaluation' }
ConsCell >> symbolsForBinding [

	"return the symbols that would be locally bound by the receiver considered as a lambda form arguments list.

	handles &rest and &optional (no other keyword implemented).
	&body and . are synonyms of &rest

	see #bindingsWithArguments for the actual binding algorithm"

	| symbs |

	symbs := self.
	symbs isSymbol ifTrue: [^ {symbs}].
	symbs ifNil: [^ #()].

	^ Array streamContents: [:str |
		[symbs isNil or: [symbs car isNil]] 
		whileFalse: 
		[
			| sym |
			sym := symbs car.
			symbs := symbs cdr.

			(sym == #'&optional') 
				ifTrue: [sym := symbs car. symbs := symbs cdr].

			(sym == #'&rest' or: [sym == #'&body'])
				ifTrue: [str nextPut: symbs car. symbs := nil]
				ifFalse:
				[
					str nextPut: sym.
					symbs isSymbol ifTrue: [str nextPut: symbs. symbs := nil]]
				]
		]

]

{ #category : #'*LispKit-evaluation' }
ConsCell >> valueForLisp: aLisp [

	| func |

	"function lookup"
	func := aLisp lookUpFunction: car.
	(aLisp isProcedure: func)
		ifFalse: [^ aLisp evalIrregularProcedure: func withArguments: cdr].

	^  func applyTo: cdr inLisp: aLisp asMacro: false.


]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> wrapCurlyBlocksWith: o [

	self nest: #({}) with: o
]

{ #category : #'*LispKit-brackets rewriting' }
ConsCell >> wrapSquareBlocksWith: o [

	self nest: #([]) with: o
]
