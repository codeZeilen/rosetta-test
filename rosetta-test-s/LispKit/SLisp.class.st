"
a dynamic Lisp-2 dialect tightly integrated with Smalltalk.

	SLisp openNew 		""doIt""


features:
	
	- the 'smalltalk' function evaluates its single argument (a string) as Smalltalk code; this code can reference variables bound in SLisp, provided that their names follow Smalltalk syntax. example:

		(let ((x 1)) (smalltalk 'x'))  => 1
  

	- SLisp has access to the global Smalltalk namespace.

	- symbol 'self' is bound to the SLisp interpreter

	- unrecognizable Lisp code is converted on the fly into nested Smalltalk messages and silently evaluated. examples:

		(position (new Morph)) is equivalent to (smalltalk 'Morph new position') 

		(@ 10 15) is equivalent to (smalltalk '10@15') 

		(openInHand (position: (new Morph) (@ 100 200)))
			is equivalent to (smalltalk '(Morph new position: 100@200) openInHand') 

	- the special form with-smalltalk-syntax (represented by curly braces {}) allows insertion of Smalltalk-looking forms, in which regular lisp forms can be included within [] sections . examples:

		(with-smalltalk-syntax (Morph new position)) => 0@0
		{Morph new position} => 0@0
		{1 + 1 + 1} => 3
		(+ 10 {1 + [+ 2 2 {3 + 3 + 3}] + 1})  => 25
	

	- boolean values are Smalltalk's true and false (instead of #t and nil) . 


with-smalltalk-syntax caveat:

	(these do not apply to text input, only when directly writing cons cells from arrays via #asCons)

	- since '#' is ignored by the conversion from Array to ConsCell, symbols can not be parsed correctly.
	so instead of 
		#(if {#symbol isSymbol} 0 1) 
	you must write 
		#(if {$#symbol isSymbol} 0 1) 
	which works because '$#' inserts a quoted Lisp form within a Smalltalk syntax 
	
	- the comma ',' can not be used as a Smalltalk selector since it is a specific syntactic sugar in backquoted forms.
	so instead of 
		#(setq string {'abc' , 'def'}) 
	you must write 
		#(setq string (smalltalk '''abc'' , ''def''')) 


demo:

do
	SLisp openNew 		
then type
	(widgets-example1)
... and see the source code in SLisp class>>widgets


"
Class {
	#name : #SLisp,
	#superclass : #ELisp,
	#instVars : [
		'syntax'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #libraries }
SLisp class >> defaultLibraries [

	^ #(glue #'provide-library' plist compilers #'small-macros' common widgets)
]

{ #category : #booleans }
SLisp class >> falseValue [

	^ false
]

{ #category : #booleans }
SLisp class >> falseValuePrintString [

	^ 'false'
]

{ #category : #libraries }
SLisp class >> glue [

	"helpers for writing compatible code among dialects"

	^ 
	#(progn

		(defun yes* () t)
		(defun no* () false)

	)
]

{ #category : #'private-subclasses may implement' }
SLisp class >> initialize [

	"SLisp initialize"

	Sugar := Dictionary
			with: $' -> #quote
			with: #` -> #quasiquote
			with: #, -> #unquote
			with: #,@ -> #'unquote-splicing'.

	Sugar add: $# -> #quotedLispInSmalltalkSyntax:.

	self compilePrimitiveLists
]

{ #category : #libraries }
SLisp class >> loop [

	^ #() "the loop macro is not implemented in SLisp at the moment"
]

{ #category : #booleans }
SLisp class >> preserveFalse [

	^ true
]

{ #category : #booleans }
SLisp class >> preserveTrue [

	^ true
]

{ #category : #rewriter }
SLisp class >> rewriteCurlyBlocks: aConsCell [.

	aConsCell wrapCurlyBlocksWith: #withSmalltalkSyntax:. 


]

{ #category : #rewriter }
SLisp class >> rewriteSquareBlocks: aConsCell [.

	aConsCell wrapSquareBlocksWith: #lispInSmalltalkSyntax:. 


]

{ #category : #'private-subclasses may implement' }
SLisp class >> sugarKeys [

	^ #(#, #',@' $' #` $#)
]

{ #category : #booleans }
SLisp class >> trueValue [

	^ true
]

{ #category : #booleans }
SLisp class >> trueValuePrintString [

	^ 'true'
]

{ #category : #rewriter }
SLisp class >> useCurlyBrackets [

	^ true
]

{ #category : #rewriter }
SLisp class >> useSquareBrackets [

	^ true
]

{ #category : #'private-subclasses may implement' }
SLisp class >> wantsFullArgumentsListsSupport [
	
	^ false
]

{ #category : #libraries }
SLisp class >> widgets [

	^ 
#(in-library widgets

	(defun make-button (label action)
	'Return a SimpleButtonMorph with LABEL triggering ACTION
ACTION must be a function or lambda expression of zero arguments'
		(let ((b (newWithLabel: SimpleButtonMorph label)))
			(target: b self)	
			(actionSelector: b `funcall:)
			(arguments: b (vector (list action)))))

	(defun get-button (label action)
	'Open in Hand a SimpleButtonMorph with LABEL triggering ACTION
ACTION must be a function or lambda expression of zero arguments'
		(openInHand (make-button label action)))

	"examples"
	(defun widgets-example1 ()
	'An example of get-button usage'
		(get-button 'spawn GUI' (lambda () {self topmostLisp openGui})))

	(defun widgets-example2 ()
	'An example of get-button usage'
		(get-button 'explore this Lisp' (lambda () {self topmostLisp explore})))
)
]

{ #category : #initialization }
SLisp >> constantBindings [

	| cb |

	cb := super constantBindings.	
	cb add: #self -> self.
	cb add: #true -> true.
	cb add: #false -> false.
	^ cb

]

{ #category : #'LISP-functions-arrays' }
SLisp >> elt: aConsCell [

"(elt SEQUENCE N)
Return element of SEQUENCE at index N.
SEQUENCE can be a list or an array. First index is 0."

	| o |

	(o := aConsCell car) isConsCell
		ifTrue: [^ aConsCell car nth: aConsCell cadr].

	"no vectors in SLisp"
	o isArray ifTrue: [^ o at: aConsCell cadr + 1].

	^ o at: aConsCell cadr + 1

	
]

{ #category : #private }
SLisp >> evalIrregularProcedure: aWouldBeProcedure withArguments: aConsCell [

	aWouldBeProcedure isSymbol ifFalse: 
	[^ super evalIrregularProcedure: aWouldBeProcedure withArguments: aConsCell].

	"we accept symbols as Smalltalk selectors"

	aConsCell cdr ifNil: 
		[^ (self evalObject: aConsCell car) perform: aWouldBeProcedure].

	^ (self evalObject: aConsCell car) 
			perform: aWouldBeProcedure 
			withArguments: (aConsCell cdr collect: [:form | 
									self evalObject: form]) topForms
]

{ #category : #private }
SLisp >> evalObject: anObject multipleValue: mvflag [

	"all code here to implement with-smalltalk-syntax..."

	| form cell selector i |

	(syntax = #smalltalk and: [anObject isConsCell]) 
		ifFalse: [^ super evalObject: anObject multipleValue: mvflag].

	"inserted Lisp form"
	(form := anObject) car == #lispInSmalltalkSyntax: ifTrue: 
		[^ (self copy syntax: #lisp) evalObject: anObject cadr multipleValue: mvflag].

	"inserted quoted Lisp form"
	form car == #quotedLispInSmalltalkSyntax: ifTrue: 
		[^ (self copy syntax: #lisp) 
		evalObject: (ConsCell car: #quote: cdr: anObject cdr) multipleValue: mvflag].

	"first pass: enclosing 0-arity messages"
	[form length > 2
		and: [(form nth: 1) numArgs = 0]]
	whileTrue: [form := ((ConsCell car: form first) addLast: form second) inCons cdr: (form nthcdr: 2)].

	"second pass: enclosing 1-arity cascaded messages"
	[form length > 3
		and: [(form nth: 1) last ~= $:]] "that is +, -, *, etc."
	whileTrue: [form := (((ConsCell car: form first) addLast: form second) addLast: form third) inCons cdr: (form nthcdr: 3)].
	
	"third pass: reordering parameters and building selector"
	selector := ''.
	cell := ConsCell new.
	i := 0.
	form do: [:elt |
		i odd ifTrue: [selector := selector, elt]
			ifFalse: [cell addLast: elt].
		i := i + 1].

	^ (self evalObject: form first) 
		perform: selector asSymbol 
		withArguments: (self evalList: cell cddr) topForms.

]

{ #category : #'entry points' }
SLisp >> evalString: aString [

	syntax = #smalltalk ifFalse: [^ super evalString: aString].

	^ self eval: (self class rewrite: (Compiler evaluate: aString asString) asCons) inCons
]

{ #category : #initialization }
SLisp >> guiColor [

	^ Color r: 0.8 g: 0.648 b: 0.344
	
]

{ #category : #initialization }
SLisp >> initialize [

	syntax := #lisp.
	super initialize.
]

{ #category : #GUI }
SLisp >> prompt [

	syntax = #smalltalk ifFalse: [^ super prompt].

	^ '[smalltalk]', super prompt 
]

{ #category : #private }
SLisp >> reader [

	^ SLispReader for: self
]

{ #category : #'entry points' }
SLisp >> smalltop: anObject [

	^ self top: {#withSmalltalkSyntax: . anObject} 
]

{ #category : #private }
SLisp >> subLisp: aSymbol form: aForm body: aConsCell environment: anLKEnvironment [

	|sublisp |
	
	sublisp := super subLisp: aSymbol form: aForm body: aConsCell environment: anLKEnvironment.

	sublisp symbolValuesAdd: #self -> sublisp.

	^ sublisp
]

{ #category : #'smalltalk invocation' }
SLisp >> symbolValue: aSymbol ifNone: aBlock [

	"use the Smalltalk namespace in last ressort"

	^ super symbolValue: aSymbol 
		ifNone: [Smalltalk at: aSymbol ifAbsent: [aBlock value]]

]

{ #category : #private }
SLisp >> syntax [

	^ syntax ifNil: [#lisp]
]

{ #category : #private }
SLisp >> syntax: aSymbol [

	syntax := aSymbol
]

{ #category : #'LISP-functions-arrays' }
SLisp >> vector: aConsCell [

"(vector &rest OBJECTS)
Return a newly created array with specified arguments as elements.
Any number of arguments, even zero arguments, are allowed."
	
	aConsCell ifNil: [^ #()].
	^ Array streamContents: [:str |
		1 to: aConsCell length do: [:i | str nextPut: (aConsCell nth: i-1)]]

]

{ #category : #'LISP-functions-arrays' }
SLisp >> vectorp: aConsCell [

"(vectorp: OBJECT)
Return t if OBJECT is an array."

	^ self class test: (aConsCell car isArray)
]

{ #category : #'LISP-special forms' }
SLisp >> withSmalltalkSyntax: aConsCell [

"(with-smalltalk-syntax &rest BODY)
Evaluate BODY with pseudo Smalltalk syntax. 
You can use {...} as syntactic sugar. 
For example:
	(+ 1 {(0 to: 10) size})
is expanded into
	(+ 1 (with-smalltalk-syntax ((0 to: 10) size))))
which is evaluated as
	(+ 1 (size (to: 0 10)))
and return
	12
You can use [...] to insert a regular Lisp form in BODY.
Examples:
	(+ 1 {2 + [+ 3 3] + 2})	
	{1 + [+ 2 2 {3 + 3}]}
"

	| lisp val |

	lisp := self copy syntax: #smalltalk.

	aConsCell do: [:c | val := lisp evalObject: c multipleValue: true].
	^ val
]
