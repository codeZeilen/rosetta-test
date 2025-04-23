Extension { #name : #Object }

{ #category : #'*LispKit' }
Object >> asOneLispValue [

	^ self
]

{ #category : #'*LispKit' }
Object >> isCompiled [

	^ false
]

{ #category : #'*LispKit' }
Object >> isCompiledProcedure [

	^ false
]

{ #category : #'*LispKit' }
Object >> isLKContinuation [

	^ false
]

{ #category : #'*LispKit' }
Object >> isLKIOPort [

	^ false
]

{ #category : #'*LispKit-LKOS' }
Object >> isLKOSClass [

	^ false
]

{ #category : #'*LispKit-LKOS' }
Object >> isLKOSGeneric [

	^ false
]

{ #category : #'*LispKit-LKOS' }
Object >> isLKOSInstance [

	^ false
]

{ #category : #'*LispKit-LKOS' }
Object >> isLKOSMethod [

	^ false
]

{ #category : #'*LispKit' }
Object >> isLKPrimitive [

	^ false
]

{ #category : #'*LispKit' }
Object >> isLKValues [

	^ false
]

{ #category : #'*LispKit' }
Object >> isLispClosure [

	^ false
]

{ #category : #'*LispKit' }
Object >> isMacro [

	^ false
]

{ #category : #'*LispKit' }
Object >> isProcedure [

	"protocol for a lisp procedure:
#environment -> return a Dictionary or nil
#lambdaForm -> return a lambda or macro expression (a ConsCell)
#isProcedure -> return true"

	^ false
]

{ #category : #'*LispKit' }
Object >> isQuotedCons [

	^ false
]

{ #category : #'*LispKit' }
Object >> isQuotedSymbol [

	^ false
]

{ #category : #'*LispKit' }
Object >> isTailCallWrapper [

	^ false
]

{ #category : #'*LispKit' }
Object >> lispPrintString [

	^ self printStringForLisp: nil.
]

{ #category : #'*LispKit-LKOS' }
Object >> lkosClass: aLisp [

	^ LKOSInstance class: #'<unknown>' inLisp: aLisp
]

{ #category : #'*LispKit' }
Object >> printStringForLisp: aLisp [

	^ String streamContents: [:s | self printOn: s forLisp: aLisp]
]

{ #category : #'*LispKit' }
Object >> printStringForLisp: aLisp limitedTo: limit [

	| limitedString |
	limitedString := String streamContents: [:s | self printOn: s forLisp: aLisp] limitedTo: limit.
	limitedString size < limit ifTrue: [^ limitedString].
	^ limitedString , '...'
]

{ #category : #'*LispKit' }
Object >> valueForLisp: aLisp [ 

	^ self
]

{ #category : #'*LispKit' }
Object >> valueForLisp: aLisp allowMultipleValues: mvflag inTail: tflag [

	^ self
]
