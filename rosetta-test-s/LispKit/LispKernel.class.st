"
minimal kernel for a Lisp implementation

	LispKernel openNew  ""doIt""


provides:

	a Lisp-2 interpreter with
	- dynamic scoping
	- fundamental special forms: let, setq, defun, defmacro ...
	- a few dozens functions: list, car, funcall, ...
	- catch/throw, unwind-protect
	- tail call optimization
	- a GUI


usage:

	subclasses of LispKernel can implement their own dialect of Lisp, by adding new functions and special forms and/or by overriding methods.
	see ELisp, SLisp, CLisp and ULisp for examples


specificities

	LispKernel is implemented as a pure Smalltalk extension: Lisp code can be written as plain Smalltalk arrays, such as

	#(defmacro addToList (x y) `(list ,x ,@y))  ""printIt"" 

	the conversion into Lisp data is straightforward: see the very simple code in Array>>#asCons which converts the array into a tree of cons cells. example:

	#(defun add (x y) (list x y)) asCons     ""exploretIt""

	this approach has many advantages. for example:
	- we can chase the senders of a symbol: try [defun] (alt-n)
	- we can use the debugger to debug Lisp code
	- we can easily implement powerful control structures (see catch/throw) 
	- we can integrate Lisp and Smalltalk. see SLisp


caveat

	since we are bound to Smalltalk syntax, our Lisp can not have exactly the same syntax as usual Lisps:

	- the syntactic shortcut for quotation is $' instead of a plain '
that is:
		(cdr $'(1 2 3))
instead of:
		(cdr '(1 2 3))

	- strings are 'quoted like this' instead of ""like that""

	- comments are ""double quoted"", the character ; has no special meaning

	- the character # is generally ignored
for example
	(+ 1 #2) or (#+ #1 2) or even #(#+ #1 #2) are the same as (+ 1 2)
	# may at time seem like it is equivalent to nil, but it isn't...

	- reserved words true and false are not parsed as symbols in arrays; use #true and #false instead. 

	 - more generally, all legal Lisp symbols which are not parsed correctly should be explicited; for example do:
	ELisp new top: #(let ((#'//my--var//' 10)) (+ #'//my--var//' 5))
instead of
	ELisp new top: #(let ((//my--var// 10)) (+ //my--var// 5))

	note that some minimal rewriting is performed when reading code at top-level in order to support the most common cases.
for example you can do:
	ELisp new top: #(let ((my-composed-var 10)) (+ my-composed-var 5))


interpreting textual code

	when the Lisp code to be evaluated is written in a string (as it happens in the GUI for example) the process described above does not happen: instead we use the regular read function from Lisp (see its implementation in LKReader). 
	thus there is no restriction to the usual Lisp syntax; code files can be loaded directly.


inspiration

	many LispKernel design ideas are inspired by Emacs Lisp. 
	most notably, all variables have dynamic scoping (subclasses may change that: see StaticLisp which has lexical scoping and special variables very much like Common Lisp)	


extending LispKernel: adding primitives

	you can define a new function or special form by adding an instance-side method to the LispKernel subclass you are working on (it is not recommended to hack on LispKernel itself).

	it should be a method of one argument, a ConsCell. this single argument is the list of arguments for the implemented lisp function or special form. special forms are given a list of non evaluated arguments, while ordinary functions are given a list of already evaluated arguments.

	it is very important that methods for functions live in a '...LISP-functions...' category, while methods for special forms are categorized under '...LISP-special forms...' (where ... can be anything).

	after adding the method, either eval (update-primitives) in any running Lisp interpreter or evaluate the Smalltalk code 'LispKernel updatePrimitives'. this will make all necessary internal registering for the new function or macro to be immediately available to all interpreters.

	if the method name is like #brandNewPrimitive: then the name for its corresponding Lisp function will be 'brand-new-primitive', although 'brandNewPrimitive:' will also be accepted. 

	more rewriting is performed in class side method #aliasForPrimitive, see there for details. for example #thisTOthatStar: would create a primitive named 'this-to-that*' in ELisp and 'this->that*' in ULisp.


extending LispKernel: adding Lisp libraries

	on the class-side of your Lisp you can add a method of no argument returning an array of Lisp code, say #myLib. 
	
	it can be loaded interactively by evaluating (load-library 'my-lib), or it can be automatically loaded at startup by adding #'my-lib' to the array returned by the instance-side method #defaultLibraries of your Lisp.


"
Class {
	#name : #LispKernel,
	#superclass : #Object,
	#instVars : [
		'environment',
		'monitor',
		'upperLisp',
		'upperHead',
		'ignoreCase',
		'evalSemaphore',
		'constantVariables',
		'upperTail',
		'outputPort',
		'inputPort',
		'topmostLisp',
		'currentDirectory',
		'inTail',
		'enableTailCallOptimization'
	],
	#classInstVars : [
		'Primitives',
		'SpecialForms',
		'Sugar',
		'CachedPrimitives'
	],
	#category : #LispKit
}

{ #category : #'private-subclasses may implement' }
LispKernel class >> aliasForPrimitive: aSymbol [

	"return the lispish symbol associated to the function or macro defined by primitive method aSymbol"

	| alias ups |

	alias := aSymbol allButLast.
	alias := alias copyReplaceAll: 'LISP' with: ''.
	(aSymbol endsWith: 'Star:')
		ifTrue: [alias := (alias allButLast: 4), '*'].	
	alias := alias copyReplaceAll: 'ONE' with: '-1'.
	alias := alias copyReplaceAll: 'TO' with: '-to-'.
	(ups := alias select: [:c | c isUppercase])	ifNotEmpty: 
	[
		alias := (ups size = 1 and: [alias last == $P])
			ifTrue: [alias asLowercase] 
			ifFalse: [alias linkAtCaps]
	].

	^ alias asSymbol
	
]

{ #category : #private }
LispKernel class >> allCategories [

	^ (Array streamContents: [:cstr | 
						self withAllSuperclasses do: [:class | 
							cstr nextPutAll: class organization categories]]) asSet.

]

{ #category : #private }
LispKernel class >> cachedPrimitive [

	^ CachedPrimitives
]

{ #category : #'private-subclasses may implement' }
LispKernel class >> characterPrintString: aCharacter [

	^ aCharacter printStringForLisp: nil
]

{ #category : #private }
LispKernel class >> compilePrimitiveLists [

	"to be evaluated whenever new primitives are implemented"

	CachedPrimitives := IdentityDictionary new.

	SpecialForms := Array streamContents: [:sfstr |
		Primitives := Array streamContents: [:pstr |	
		self specialFormSelectors do: [:sel | 
			sfstr nextPut: sel.
			pstr nextPut: sel.
			CachedPrimitives at: sel put: (LKPrimitive selector: sel for: self)].
		self primitiveFunctionSelectors do: [:sel | 
			pstr nextPut: sel.
			CachedPrimitives at: sel put: (LKPrimitive selector: sel for: self)]]].

	self definePrimitiveAliases

]

{ #category : #'private-subclasses may implement' }
LispKernel class >> complexString: aComplex base: base [

	"printed representation for aComplex"

	^ '#C(', (aComplex real printStringBase: base), ' ', 
		(aComplex imaginary printStringBase: base), ')'
		
]

{ #category : #'private-subclasses may implement' }
LispKernel class >> defaultLibraries [

	"which libraries should be loaded at start up"

	^ #(glue)
]

{ #category : #private }
LispKernel class >> definePrimitiveAliases [

	| aliases |
	
	"does the same job as the instance-side #definePrimitiveAliases, only for all instances of the receiver"

	aliases := self primitives select: [:prim | prim last == $:] 
		thenCollect: [:prim  | 
			(self aliasForPrimitive: prim) -> (LKPrimitive selector: prim for: self)].
	
	(self allInstances select: [:lisp | lisp upperLisp isNil])
		do: [:lisp | [lisp installPrimitiveAliases: aliases] on: Error do: [nil]]

]

{ #category : #util }
LispKernel class >> display: aString underLabel: bString [

	StringHolder new acceptContents: aString; openLabel: bString
]

{ #category : #'private-subclasses may implement' }
LispKernel class >> escapeSequences [

	"subclasses can define their own escape sequences"

	^ {
		'\n' -> String lf. 
		'\r' -> String cr .            
		'\t' -> String tab.   
		}

]

{ #category : #public }
LispKernel class >> evaluate: anObject [

	^ self new evaluate: anObject
]

{ #category : #booleans }
LispKernel class >> falseValue [

	^ nil
]

{ #category : #booleans }
LispKernel class >> falseValuePrintString [

	^ 'nil'
]

{ #category : #libraries }
LispKernel class >> glue [

	"helpers for writing compatible code among dialects"

	^ 
	#(progn

		(defun yes* () #t)
		(defun no* () nil)

	)
]

{ #category : #GUI }
LispKernel class >> guiLabel [

	^ self name

]

{ #category : #private }
LispKernel class >> initialize [

	"LispKernel initialize"

	Sugar := Dictionary
				with: $' -> #quote
				with: #` -> #quasiquote
				with: #, -> #unquote
				with: #,@ -> #'unquote-splicing'.

	Sugar add: #'#`' -> #function:.

	self compilePrimitiveLists


	
]

{ #category : #util }
LispKernel class >> lispError: aString [

	^ LispError new signal: aString
]

{ #category : #booleans }
LispKernel class >> nullPrintString [

	^ 'nil'
]

{ #category : #public }
LispKernel class >> openNew [

	^ self new loadDefaultLibraries openGui
]

{ #category : #booleans }
LispKernel class >> preserveFalse [

	^ false
]

{ #category : #booleans }
LispKernel class >> preserveNil [

	^ true
]

{ #category : #booleans }
LispKernel class >> preserveTrue [

	^ false
]

{ #category : #private }
LispKernel class >> primitiveFunctionSelectors [

"
	all selectors in categories with names including 'LISP-functions'
"

	^ Array streamContents: [:str |
			(self allCategories select: [:cat | 
					cat includesSubString: 'LISP-functions'])
				do: [:cat | str nextPutAll: (self allMethodsInCategory: cat)]]


]

{ #category : #private }
LispKernel class >> primitives [

	^ Primitives
]

{ #category : #'array code rewriter' }
LispKernel class >> recRewrite2: anObject [

	"second pass of recRewrite"

	| car cdr |

	anObject ifNil: [^ nil].

	anObject isArray ifTrue: [^ (self recRewrite2: anObject asConsList) topForms].
	anObject isConsCell ifFalse: [^ anObject].

	car := anObject car.
	cdr := anObject cdr.

	anObject setcar: (self recRewrite2: car).
	anObject setcdr: (self recRewrite2: cdr).

	car isSymbol ifFalse: [^ anObject ].

	"see #rewriteString:"
	(car beginsWith: 'asciiValue') ifFalse: [^ anObject ].

	anObject setcar: (Character codePoint: (car last: 2) asNumber) asSymbol.

	^ anObject 

	
]

{ #category : #'array code rewriter' }
LispKernel class >> recRewrite: anObject [

	| car cdr sym bsym s |

	anObject ifNil: [^ nil].

	anObject isArray ifTrue: [^ (self recRewrite: anObject asConsList) topForms].
	anObject isConsCell ifFalse: [^ anObject].

	"separating a stuck backquote from its following symbol"
	(anObject car isSymbol
		and: [anObject car first == $`]
		and: [anObject car size > 1]
		and: [anObject car second ~~ $`])
	ifTrue: [ | ncdr |
		ncdr := ConsCell car: anObject car allButFirst asSymbol cdr: anObject cdr.
		anObject setcar: $'. "will be rewritten as (quote ...) later on"
		anObject setcdr: ncdr].

	"turning a quasiquote into a plain quote whenever possible"
	(anObject car == #` 
		and: [(anObject cadr isSymbol 
					and: [(#($` $,) identityIncludes: anObject cadr first) not])
			or: [anObject cadr isConsCell
					and: [anObject cadr topForms noneSatisfy: [:o | 
								o isConsCell 
									or: [o isSymbol 
											and: [(o first == $,) 
												or: [o beginsWith: 'unquote']]]]]]])
		ifTrue: [anObject setcar: $'].

	"dotted pair notation" 
	(anObject cdr isConsCell
		and: [anObject cadr == #'.']) ifTrue:	
	[		
		anObject cddr car == #,
		ifTrue: [ "very special case: [. , -> ,@] 
					for example`(a b . ,c) becomes `(a b ,@c)"
			anObject setcdr: (#',@' inCons lastCdr: anObject cddr cdr)]
		ifFalse: [
			self recRewrite: anObject cdr cdr. 
			anObject setcdr: anObject cdr cadr]
	].  

	car := anObject  car.
	cdr := anObject cdr.

	anObject setcar: (self recRewrite: car).
	anObject setcdr: (self recRewrite: cdr).

	(car isSymbol or: [car isCharacter]) ifFalse: [^ anObject ].

	(self sugarKeys identityIncludes: car)
		ifTrue: [anObject setcar: 
					(ConsCell car: (self sugar at: car)
							cdr: (ConsCell car: anObject cadr cdr: nil)).
				anObject setcdr: cdr cdr].

	anObject cdr isConsCell ifFalse: [^ anObject].

	sym := anObject car.

	(sym == #& and: [(bsym := anObject cadr) isSymbol])
		ifTrue:
		[
			anObject setcar: (sym, bsym) asSymbol.
			anObject setcdr: anObject cdr cdr
		].

	s := anObject cadr.
	(#(! ? *) identityIncludes: s)
		ifTrue: 
		[
			anObject setcar: (sym, s) asSymbol.
			anObject setcdr: anObject cdr cdr
		].

	((s == #- or: [s == #/]) and: [(bsym := anObject cdr cadr) isSymbol])
		ifTrue: 
		[
			anObject setcar: (sym, s, bsym) asSymbol.
			anObject setcdr: anObject cdr cdr cdr
		].

	^ anObject 

	
]

{ #category : #'string format conversion' }
LispKernel class >> representString: aString [

	"transcode aString from Smalltalk format into this lisp format"

	| str |

	str := aString.
	str := str copyReplaceAll: '\' with: '\\'.
	str := str copyReplaceAll: '"' with: '\"' .

	self escapeSequences do: [:assoc |
		str := str copyReplaceAll: assoc value with: assoc key].            

	^ str
	
]

{ #category : #'array code rewriter' }
LispKernel class >> rewrite: anObject [

	"mostly useful when anObject has been freshly created by sending #asCons to an hand-writen Array of lisp code

	this rewriting procedure handles syntactic sugar such as dotted pair notation, the direct usage of ,@ or ` within an Array, or using compound symbols such as this-one, plus more...

	without rewriting, the lisp-like Array
		#(setq an-example `(1 + ,some-var)) 
	would need to be written
		#(setq #'an-example'  (quasiquote (1 + (unquote #'some-var'))))

	see by yourself by inspecting or printing the following: 

	#(setq an-example `(1 + ,some-var)) asCons
	LispKernel rewrite: #(setq an-example `(1 + ,some-var)) asCons
	#(setq #'an-example'  (quasiquote (1 + (unquote #'some-var')))) asCons
"

	| datacode |

	(datacode := anObject) isConsCell ifTrue:
	[	
		self useSquareBrackets ifTrue: [self rewriteSquareBlocks: datacode].
		self useCurlyBrackets ifTrue: [self rewriteCurlyBlocks: datacode].
	 ].
	datacode := self recRewrite: datacode.
	datacode := self recRewrite2: datacode. 
	^ datacode 

	
]

{ #category : #'array code rewriter' }
LispKernel class >> rewriteCurlyBlocks: aConsCell [

	"aConsCell wrapCurlyBlocksWith: ..."


	
]

{ #category : #'array code rewriter' }
LispKernel class >> rewriteSquareBlocks: aConsCell [

	"aConsCell wrapBlocksWith: ... "
]

{ #category : #private }
LispKernel class >> specialFormSelectors [

"
	all selectors in categories with names including 'LISP-special forms'
"

	^ Array streamContents: [:str |
			(self allCategories select: [:cat | 
					cat includesSubString: 'LISP-special forms'])
				do: [:cat | str nextPutAll: (self allMethodsInCategory: cat)]]

]

{ #category : #private }
LispKernel class >> specialForms [

	^ SpecialForms
]

{ #category : #'string format conversion' }
LispKernel class >> stringRepresentedBy: aString [

	"transcode aString from this lisp format (i.e. with specific escape sequences) into Smalltalk format"

	| str |

	str := aString.
	(str includes: $\) ifFalse: [^ str].

	str := str copyReplaceAll: '\\' with: '<-<double-slash-here>->'. 
	str := str copyReplaceAll: '#\' with: '<-<#-slash-here>->'. 
	str := str copyReplaceAll: '\"' with: '"'. 
	self escapeSequences do: [:assoc |
		str := str copyReplaceAll: assoc key with: assoc value].    

	str := str copyReplaceAll: '<-<#-slash-here>->' with: '#\'.
	^ str copyReplaceAll: '<-<double-slash-here>->' with: '\'.

]

{ #category : #'array code rewriter' }
LispKernel class >> sugar [

	^ Sugar
]

{ #category : #'array code rewriter' }
LispKernel class >> sugarKeys [

	^ #(#, #',@' $' #` #'#`')
]

{ #category : #booleans }
LispKernel class >> test: aBoolean [

	^ aBoolean ifTrue: [self trueValue] ifFalse: [self falseValue]
]

{ #category : #public }
LispKernel class >> top: anObject [

	^ self new top: anObject
]

{ #category : #booleans }
LispKernel class >> trueValue [

	^ #t
]

{ #category : #booleans }
LispKernel class >> trueValuePrintString [

	^ 't'
]

{ #category : #private }
LispKernel class >> updatePrimitives [

"Perform the integration of newly defined primitives into the LispKernel hierarchy system, clean up if necessary
This has on-the-fly effect to all lisp interpreter instances"

	LispKernel withAllSubclasses do: [:lispclass | 
		lispclass compilePrimitiveLists].
]

{ #category : #'array code rewriter' }
LispKernel class >> useCurlyBrackets [

	^ false
]

{ #category : #'array code rewriter' }
LispKernel class >> useSquareBrackets [

	^ false
]

{ #category : #'private-subclasses may implement' }
LispKernel class >> vectorClosingChar [

	^ $)
]

{ #category : #'private-subclasses may implement' }
LispKernel class >> vectorOpeningString [

	^ '#('
]

{ #category : #'LISP-functions' }
LispKernel >> about: aConsCell [

"(about SYMBOL)
Describe the function definition and value of SYMBOL."

	| v sym |

	(sym := aConsCell car) isSymbol ifFalse: [self lispError: 'not a symbol'].

	v := self symbolValue: sym ifNone: [nil].

	self output: ('Value: #', sym, (v ifNil: [' is unbound'] ifNotNil: [' is bound to
	', (v printStringForLisp: self)]), '
Function: ', (self documentation: aConsCell)).

	^ self trueValue
]

{ #category : #GUI }
LispKernel >> addItemsToREPLMenu: aMenu [
]

{ #category : #'LISP-functions' }
LispKernel >> apply: aConsCell [

"(apply FUNCTION &rest ARGS)
Call FUNCTION with the remaining args, using the last arg as list of args.
Return the value FUNCTION returns.
For example, (apply $'+ 1 2 $'(3 4)) returns 10."

	| form |

	form := aConsCell car inCons.
	
	aConsCell cdr cellsDo: [:ac |
		ac cdr 
			ifNil: [ac car ifNotNil: [form lastCdr: (ac car collect: [:arg | 
								ConsCell car: #quote: cdr: (ConsCell car: arg)])]]
			ifNotNil: [form addLast: (ConsCell car: #quote: cdr: (ConsCell car: ac car))]].

	^ self evalTailObject: form 
]

{ #category : #'LISP-special forms' }
LispKernel >> bench: aConsCell [

"(bench FORM)
Evaluate FORM repeatedly for 5 seconds, return the average number of times it was run per second"

	^ [self evalNewTailObject: aConsCell car] gcbench asNumber
]

{ #category : #GUI }
LispKernel >> bindingOf: aString [

	^ environment symbolValueBinding: aString asSymbol
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> boundSymbols: ignored [

"(bound-symbols)
Return a list of all symbols bound to a value"

	^ environment allBoundSymbols asCons

]

{ #category : #'LISP-functions-predicates' }
LispKernel >> boundp: aConsCell [

"(boundp SYMBOL)
Return t if SYMBOL's value is not void."	

	self symbolValue: aConsCell car ifNone: [^ self falseValue].
	^ self trueValue

]

{ #category : #GUI }
LispKernel >> buildMenu: aMenu [

	aMenu defaultTarget: self.
	
	aMenu 
		add: 'explore environment' target: environment selector: #explore;
		add: 'explore interpreter' target: self selector: #explore;
		addLine;
		add: 'spawn gui' target: self selector: #openGui.

	upperLisp ifNotNil: 
		[aMenu add: 'go up' target: upperLisp selector: #openGui].

	^ aMenu
	

]

{ #category : #'LISP-functions' }
LispKernel >> car: aConsCell [

"(car LIST)
Return the car (also called the head) of LIST.  If LIST is nil, return nil."

	(aConsCell car isNil
		or:[aConsCell car isConsCell]) 
		ifFalse: [self lispError: 'not a cons'].

	^ aConsCell car car 

	
]

{ #category : #'LISP-special forms' }
LispKernel >> catch: aConsCell [

"(catch TAG &rest BODY)
Eval BODY allowing nonlocal exits using `throw'.
TAG is evalled to get the tag to use; it must not be nil.
Then the BODY is executed.
Within BODY, (throw TAG) with same TAG exits BODY and exits this `catch'.
If no throw happens, `catch' returns the value of the last BODY form.
If a throw happens, it specifies the value to return from `catch'."

	| val |

	aConsCell ifNil: [^ nil].

	[ (aConsCell cdr ifNil: [^ nil]) do: [:form | val := self evalObject: form]]
		on: LKThrowNotification
		do: [:spec |
				(spec tag = (self evalObject: aConsCell car))
					ifTrue: [val := spec value]
					ifFalse: [spec signal]].

	^ val

	
]

{ #category : #'LISP-functions' }
LispKernel >> cdr: aConsCell [

"(cdr LIST)
Return the cdr (also called the tail) of LIST.  If LIST is nil, return nil."

	^ aConsCell car cdr 

	
]

{ #category : #'private - subclasses may implement' }
LispKernel >> checkSymbol: aSymbol [

	"aSymbol bindings are about to be changed.
	if there is anything to check up, do it here and return the actual symbol to be used" 

	aSymbol isSymbol 
		ifFalse: [self lispError: 'symbol expected, got ', aSymbol asString].

	(constantVariables pointsTo: aSymbol)
		ifTrue: [self lispError: aSymbol, ' is a constant, can''t be bound'].

	^ aSymbol
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> clear: ignored [

"(clear)
clear the standard output, if supported"

	self standardOutput clear.
	^ self trueValue

]

{ #category : #'private - subclasses may implement' }
LispKernel >> constantBindings [

	"constant bindings. those cannot be changed, see #checkSymbol:"

	^ Dictionary 
		with: #t -> self trueValue
		with: #nil -> nil
		
]

{ #category : #'private - interpreter' }
LispKernel >> constantVariables [

	^ constantVariables
]

{ #category : #'private - interpreter' }
LispKernel >> constantVariables: anArray [

	constantVariables := anArray
	
	
]

{ #category : #'LISP-functions' }
LispKernel >> copy: aConsCell [

"(copy OBJECT)
Returns a copy of OBJECT, by sending #copy"

	^ aConsCell car copy
]

{ #category : #'private - utils' }
LispKernel >> currentDirectory [

	^ currentDirectory ifNil: [currentDirectory := FileDirectory default]
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> currentDirectory: ignored [

"(current-directory)
Used by 'load' to resolve relative file names"

	^ self currentDirectory pathName, FileDirectory slash


]

{ #category : #'LISP-functions-debugging' }
LispKernel >> currentEnvironment: aConsCell [

"(current-environment)
Return the current environment frame"

	^ environment

]

{ #category : #GUI }
LispKernel >> debug [

	"useful when invoked from the Smaltalk debugger
	opens a GUI for the appropriate sub-lisp with contextual information"

	self class display: 

		(Text streamContents: [:str | | n upf |
			str nextPutAll: ';; interpreter contexts'; cr;
				nextPutAll: ';; (click -N- to jump to Nth context)'; cr.
			upf := self upperForms.
			n := 0.

			upf size > 50 
				ifTrue: [n := upf size - 50. upf := upf first: 50].
			upf reverseDo: [:form |
					| nlisp |
					nlisp := upf size - n - 1.
					str withAttribute: (PluggableTextAttribute evalBlock: 
						[((self nthUpperLisp: nlisp) ifNil: [self]) openGui] 							fixTemps)
						do: [str nextPutAll: '-', n asString, '-'; tab].
					n := n + 1.
					str nextPutAll: (form printStringForLisp: self); cr]]) 

	underLabel: (self upperForm printStringForLisp: self)
	
]

{ #category : #'LISP-functions-debugging' }
LispKernel >> debug: aConsCell [

"(debug)
Halt the evaluation, open a Smalltalk debugger plus a Lisp GUI living in the appropriate environment"

	self debug.
	Debugger
		openContext: thisContext
		label: '(debug)'
		contents: (self upperForm printStringForLisp: self)
]

{ #category : #'private - subclasses may implement' }
LispKernel >> defaultBindings [

	"return a Dictionary defining all variables that should be present when the interpreter starts"

	| db |

	db := IdentityDictionary new.
	db add: #'*standard-output*' -> self standardOutputPort.
	db add: #'*standard-input*' -> self standardInputPort.
	db add: #'*print-circle*' -> nil.
	db add: #'*print-length*' -> nil.
	db add: #'*print-level*' -> nil.
	db add: #'*features*' -> nil.
	db add: #'*u-index*' -> 0.

	^ db

]

{ #category : #'LISP-special forms' }
LispKernel >> defconstant: aConsCell [

"(defconstant: SYMBOL VALUE)
Set VALUE for SYMBOL, then make it a constant"

	| sym |
	
	sym := self checkSymbol: aConsCell car.

	self topmostLisp symbolValuesAdd: 
					sym -> (self evalObject: aConsCell cadr).

	(constantVariables pointsTo: sym) 
		ifFalse: [constantVariables := constantVariables, {sym}].

	^ sym
]

{ #category : #'private - initialization' }
LispKernel >> defineDefaultBindings [

	constantVariables := Array streamContents: [:str |
		str nextPutAll: constantVariables.
	self constantBindings associationsDo: [:assoc | 
		environment addSymbolValue: assoc.
		str nextPut: assoc key]].

	self defaultBindings associationsDo: [:assoc | 
		environment addSymbolValue: assoc.]

]

{ #category : #'private - initialization' }
LispKernel >> definePrimitiveAliases [
	
	"defines functions for primitives with lispish names, so that we can do for example
					(defun myCons (x y) (cons x y))
	instead of
					(defun: myCons (x y) (cons: x y))

	in #installPrimitiveAliases: care is taken not to override the possibly already existing definition of the alias symbol, so that the overall effect of sending this message to a running interpreter is simply to register newly created primitives and have them available on-the-fly"

	self installPrimitiveAliases: 
		(self class primitives select: [:prim | prim last == $:] 
			thenCollect: [:prim  | 
				(self class aliasForPrimitive: prim) -> (LKPrimitive selector: prim for: self class)])

]

{ #category : #'LISP-special forms' }
LispKernel >> defmacro: aConsCell [

"(defmacro NAME ARGLIST &rest BODY...)
Set the function definition of NAME as (macro lambda ARGLIST &rest BODY).
When the macro is called, as in (NAME &rest ARGS), the function (lambda ARGLIST &rest BODY) is applied to the list ARGS as it appears in the expression, and the result should be a form to be evaluated instead of the original.
If the first form in BODY is a string, it is considered as the macro documentation"

	| macro |
	macro := self lambdaForm: #macro withArgsAndBody: aConsCell cdr.
	self topmostLisp lispEnvironment addSymbolFunction: aConsCell car -> macro.
	^ macro
]

{ #category : #'LISP-special forms' }
LispKernel >> defun: aConsCell [

"(defun NAME ARGLIST &rest BODY)
Set the function definition of NAME as (lambda ARGLIST &rest BODY).
If the first form in BODY is a string, it is considered as the function documentation"

	| lambda |
	lambda := self lambdaForm: #lambda withArgsAndBody: aConsCell cdr.
	self topmostLisp lispEnvironment addSymbolFunction: aConsCell car -> lambda.
	^ aConsCell car
]

{ #category : #'private - interpreter' }
LispKernel >> depth [

	^ upperLisp ifNil: [0] ifNotNil: [upperLisp depth + 1]
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> documentation: aConsCell [

"(documentation FUNCTION)
Return the documentation string of FUNCTION."

	| func doc |

	func := self symbolFunction: aConsCell car 
		ifNone: [^ ((aConsCell car printStringForLisp: self), ' is not a function') asSymbol].

	func isProcedure ifTrue: 
	[
		doc := func lambdaForm nth: 2.

		"SScheme special:
		SLIB 'macros-that-work moves the doc string within a begin form, so fetch it there:"
		(doc isConsCell 	
			and: [doc car == #begin]
			and: [doc cadr isString])
		ifTrue: [doc := doc cadr].

		doc isString ifTrue: 
		[ 
			| args |
			args := (args := func lambdaForm nth: 1)
						 ifNotNil: [args formatForDocumentationString].
			doc := (aConsCell lastCdr: args) asString, String cr, doc
		]
		ifFalse: [^ #undocumented]
	].

	func isLKPrimitive ifTrue: [func := func selector].

	func isSymbol ifTrue: [
		doc := (self class whichClassIncludesSelector: func) 
			firstPrecodeCommentFor: func.
		doc ifNil: [^ #undocumented].
		doc := '(', aConsCell car, ' ', (doc copyAfter: $ )].

	doc ifNil: [^ #undocumented].
	^ doc
]

{ #category : #'LISP-special forms' }
LispKernel >> durationToRun: aConsCell [

"(duration-to-run FORM)
Evaluate FORM and return all long it took to do so."

	^ [self evalNewTailObject: aConsCell car] durationToRun
]

{ #category : #'LISP-functions' }
LispKernel >> elt: aConsCell [

"(elt SEQUENCE N)
Return element of SEQUENCE at index N.
SEQUENCE can be a list or a vector (first index is 0)"

	| o |

	(o := aConsCell car) isConsCell
		ifTrue: [^ o nth: aConsCell cadr].

	o isCollection ifTrue: [^ o at: aConsCell cadr + 1].

	self lispError: 'not a sequence'

	
]

{ #category : #'private - interpreter' }
LispKernel >> enableTailCallOptimization [

	^ enableTailCallOptimization
]

{ #category : #'private - interpreter' }
LispKernel >> enableTailCallOptimization: aBoolean [

	enableTailCallOptimization := aBoolean
]

{ #category : #'entry points' }
LispKernel >> enterInterpreterContextAndEval: anObject [

	| val |

	"IMPORTANT: 

	all entry points to the Lisp interpreter must call this method, which simply wraps an #eval: call. 

	this method should never be invoked by lisp primitives, since it is always considered as the topmost context of a Lisp interpreter. 

	the correct behavior of continuations depends on these rules being followed. see LKContinuation>>#getTopSenderFrom:
	
	the correct behavior of tail call optimization also depends on this. see #inTail: senders
	"

	(anObject isConsCell 
		and: [#(progn: progn begin) pointsTo: anObject car]
		"http://lists.racket-lang.org/users/archive/2010-August/041139.html")
	ifFalse: [

		self monitor ifNotNil: [self monitor goTopLevel].

		^ self evalSemaphore critical: [
				self inTail: self enableTailCallOptimization.
				self evalTailObject: anObject]
	].		
	
	(anObject cdr ifNil: [^ nil]) 
		do: [:ea | val := self enterInterpreterContextAndEval: ea].
	^ val



]

{ #category : #'LISP-functions' }
LispKernel >> error: aConsCell [

"(error STRING ...)
Raise a LispError with text STRING"

	self lispError: (String streamContents: [:str |
		str nextPutAll: aConsCell car.
		aConsCell cdr ifNotNil:
			[aConsCell cdr do: [:ea | str cr. ea printOn: str forLisp: self]]])


]

{ #category : #'private - utils' }
LispKernel >> errorUndefinedFunction: aSymbol [

	^ self lispError: 'no function bound to symbol ', aSymbol
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> eval: aConsCell [

"(eval FORM [ENVIRONMENT])
Evaluate FORM in the specified ENVIRONMENT (which defaults to the interaction top level), return its value"

	^ self eval: aConsCell car 
		inEnvironment: (aConsCell cadr ifNil: [self topmostLisp lispEnvironment])

	

]

{ #category : #'private - interpreter' }
LispKernel >> eval: anObject inEnvironment: aLKEnvironment [

	^ (self copy
		lispEnvironment: aLKEnvironment;
		upperLisp: self;
		upperTail: nil;
		upperHead: nil) evalObject: anObject multipleValue: true
]

{ #category : #'private - interpreter' }
LispKernel >> evalIrregularProcedure: aWouldBeProcedure withArguments: aConsCell [

	"subclasses may consider any object as a procedure and handle its evaluation here"

	self lispError: 'Invalid function: ', aWouldBeProcedure asString
]

{ #category : #'private - interpreter' }
LispKernel >> evalList: aConsCell [ 

	^ (aConsCell ifNil: [^ nil]) collect: [:v | self evalObject: v]
]

{ #category : #'private - interpreter' }
LispKernel >> evalNewTailObject: anObject [

	"Force an independent, sublevel tail call optimizing loop for anObject,
that is do not use the possibly existing TailCallWrapper in this interpreter but create a new, nested, one.

	This is useful in very specific cases when we want to eval a tail call with optimization for debugging or profiling purposes. Sending #evalTailObject would just return a TailCallWrapper. If we want to observe the overall proces we need to start it again from scratch. 
	... see all senders."

	self inTail: self enableTailCallOptimization.
	^ self evalTailObject: anObject
]

{ #category : #'private - interpreter' }
LispKernel >> evalObject: anObject [

	^ self evalObject: anObject multipleValue: false
]

{ #category : #'private - interpreter' }
LispKernel >> evalObject: anObject multipleValue: mvflag [

	| val cache |

	self monitor ifNotNil:	
		[self monitor trace: anObject in: self].

	cache := self inTail.
	self inTail: false.
	val := anObject valueForLisp: self .
	self inTail: cache.

	self monitor ifNotNil:	
		[self monitor traceResult: val for: anObject in: self].

	(val isLKValues and: [mvflag not]) 
		ifTrue: [val := val asOneLispValue].

	^ val


]

{ #category : #'private - interpreter' }
LispKernel >> evalSemaphore [

	^ evalSemaphore ifNil: [Semaphore forMutualExclusion]
]

{ #category : #'entry points' }
LispKernel >> evalString: aString [

	"textual entry point to the Lisp interpreter for a single expression. 

	aString should contain well-formed lisp code. if it contains multiple expressions, only the first one will be evaluated and its value returned.

	because it is an entry point to the interpreter context, #evalCodeString: should never be sent form within a Lisp program; it should not be used by any primitive. use #read: and #eval instead.

	see #enterInterpreterContextAndEval: for the rationale"

	^ self enterInterpreterContextAndEval: 
		(self reader read: (ReadStream on: aString)) 


]

{ #category : #GUI }
LispKernel >> evalString: aString notifying: requestor [

	^ self evalString: aString
]

{ #category : #'private - interpreter' }
LispKernel >> evalTailObject: form [

	| func |

	((self inTail == false) or: [form isConsCell not]) 
		ifTrue: [^ self evalObject: form multipleValue: true].
	
	"the code below implements tail call optimization: 
	we return immediately any procedure invocation as a TailCallWrapper"
	
	func := self lookUpFunction: form car.
	(self isProcedure: func) ifFalse:
		[^ self evalIrregularProcedure: func withArguments: form cdr].
		
	self inTail == true "initialization of the optimizing loop"
		ifTrue: [^ TailCallWrapper startOnProcedure: func args: form cdr lisp: self].
								
	^ TailCallWrapper new procedure: func; args: form cdr; lisp: self
	"... will be caught by the loop, see TailCallWrapper>>#evaluate"

]

{ #category : #'entry points' }
LispKernel >> evalText: aString [

	"textual entry point to the Lisp interpreter. 

	aString should contain well-formed lisp code. it can be a full program with multiple expressions: they will be evaluated sequentially at top-level, with the value of the last one returned

	because it is an entry point to the interpreter context, #evalText: should never be sent from within a Lisp program; it should not be used by any primitive. use #read: and #eval instead.

	see #enterInterpreterContextAndEval: for the rationale"

	| stream val cons |

	stream := ReadStream on: aString.
	cons := (LKIOPort input: stream) inCons.
	[stream atEnd] whileFalse: 
		[	| expr |
			expr := self read: cons.
			expr == #'<eof>' ifTrue: [^ val].
			val := self enterInterpreterContextAndEval: expr
		].

	^ val


]

{ #category : #GUI }
LispKernel >> evalText: aString from: aPluggableTextMorph [

	self evalText: aString.
	aPluggableTextMorph hasUnacceptedEdits: false.
]

{ #category : #'private - interpreter' }
LispKernel >> evalToValues: anObject [

	| val |
	val := self evalObject: anObject multipleValue: true.
	val isLKValues ifFalse: [^ LKValues with: val].		
	^ val

]

{ #category : #'entry points' }
LispKernel >> evaluate: anObject [

	"entry point to the Lisp interpreter. 

	anObject can be any acceptable data for Lisp. it is evaluated as is, without being converted nor transformed.

	because it is an entry point to the interpreter context, #evaluate: should never be sent from within a Lisp program; it should not be used by any primitive. use #evalObject: instead.

	see #enterInterpreterContextAndEval: for the rationale"

	^ self enterInterpreterContextAndEval: anObject


]

{ #category : #'LISP-functions-debugging' }
LispKernel >> explore: aConsCell [

"(explore OBJECT)
Open an Explorer on OBJECT, return OBJECT"

	aConsCell car explore.
	^ aConsCell car.

]

{ #category : #'private - interpreter' }
LispKernel >> falseValue [

	^ self class falseValue
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> fboundSymbols: ignored [

"(fbound-symbols)
Return a list of all symbols bound to a function"

	^ environment allFboundSymbols asConsList

]

{ #category : #'LISP-functions-predicates' }
LispKernel >> fboundp: aConsCell [

"(fboundp SYMBOL)
Return t if SYMBOL's function is not void."	

	self symbolFunction: aConsCell car ifNone: [^ self falseValue].
	^ self trueValue

]

{ #category : #'private - variables' }
LispKernel >> features [

	^ self symbolValue: #'*features*'	ifNone: [nil]
]

{ #category : #'LISP-special forms' }
LispKernel >> flet: aConsCell [

"(flet VARLIST &rest BODY)
Make temporary function definitions.
VARLIST is of form ((FUNC ARGLIST BODY...) ...)
This is an analogue of `let' that operates on the function cell of FUNC
rather than its value cell.  The forms in BODY are evaluated with the specified function definitions in place, then the definitions are undone 
(the FUNCs go back to their previous definitions, or lack thereof)."

	| sublisp |

	sublisp := self subLisp: #flet form: aConsCell body: aConsCell cdr. 

	aConsCell first ifNotNil:
	[
		(aConsCell first collect: [:form | 
			sublisp checkSymbol: form first. 
			form first -> (self lambdaForm: #lambda withArgsAndBody: form cdr)])
		do: [:v | sublisp lispEnvironment addSymbolFunction: v]
	].

	(aConsCell cdr ifNil: [^ nil]) 
		doWithCdr: [:c :cdr | 
			cdr ifNil: [^ sublisp evalTailObject: c].
			sublisp evalObject: c]
]

{ #category : #'LISP-functions' }
LispKernel >> fmakunbound: aConsCell [

"(fmakunbound SYMBOL)
Make SYMBOL's function be void."

	| s |
	s := self checkSymbol: aConsCell car.
	(environment symbolFunctionsDictionaryFor: s) removeKey: s ifAbsent: [].
	^ s

	
]

{ #category : #GUI }
LispKernel >> focusOnREPL: aLKREPLMorph [

	self standardOutputPort breakDependents; addDependent: aLKREPLMorph

]

{ #category : #GUI }
LispKernel >> focusedREPL [

	self standardOutputPort dependents ifEmpty: [^ nil].
	^ self standardOutputPort dependents first


]

{ #category : #'LISP-functions' }
LispKernel >> funcall: aConsCell [

"(funcall FUNCTION &rest ARGUMENTS)
Call FUNCTION as a function, passing remaining ARGUMENTS to it.
Return the value that function returns.
For example, (funcall $'cons $'x $'y) returns (x . y).
FUNCTION must not be a macro nor a special form."

	| form |

	form := ConsCell car: aConsCell car.
	aConsCell cdr ifNotNil:
	[
		form lastCdr: (aConsCell cdr collect: [:arg | 
						ConsCell car: #quote: cdr: (ConsCell car: arg)])
	].

	^ self evalObject: form multipleValue: true
]

{ #category : #'LISP-special forms' }
LispKernel >> function: aConsCell [

"(function FN)
Return the functional interpretation of FN"

	"FN is symbol: simple redirection"
	aConsCell car isSymbol ifTrue: [^ self symbolFunction: aConsCell].

	"else FN is a lambda form. we don't check though.."

	"since #lambda: does the closure, we don't have to do anything here"		
	^ self evalObject: aConsCell car
	
]

{ #category : #'LISP-special forms' }
LispKernel >> gcbench: aConsCell [

"(gcbench FORM)
Perform a full garbage collect, then evaluate FORM repeatedly for 5 seconds, return the average number of times it was run per second. "

	Smalltalk garbageCollect.
	Smalltalk garbageCollect.
	^ [self evalNewTailObject: aConsCell car] bench asNumber
]

{ #category : #'property lists' }
LispKernel >> get: aSymbol symbol: bSymbol [

	| plist |

	plist := self symbolPlists at: bSymbol ifAbsent: [^ nil].

	[plist notNil] whileTrue:
	[
		plist car == aSymbol ifTrue: [^ plist cadr].
		plist := plist cddr
	].

	^ nil
]

{ #category : #'private - initialization' }
LispKernel >> getNewEnvironment [

	self lispEnvironment: LK2Environment new.


]

{ #category : #GUI }
LispKernel >> gui [

	| window color |

	window := (SystemWindow labelled: self guiLabel).
	self addDependent: window.

	color := self guiColor.
	window setProperty: #paneColor toValue: color.

	window addMorph: (
		 LKPluggableTextMorph 
			on: self text: nil accept: #evalText:from: readSelection: nil
		menu: #buildMenu:)
		frame: (0@0 corner: 1@0.5).

	window addMorph: (	LispKitREPLMorph on: self)
		frame: (0@0.5 corner: 1@1).

	^ window

]

{ #category : #GUI }
LispKernel >> guiColor [

	^ Color orange
	
]

{ #category : #GUI }
LispKernel >> guiLabel [

	^ self class guiLabel

]

{ #category : #'LISP-functions-debugging' }
LispKernel >> halt: aConsCell [

"(halt)
Halt the evaluation and open a Smalltalk debugger"

	^ self halt
]

{ #category : #'private - initialization' }
LispKernel >> ignoreCase [

	ignoreCase := true
]

{ #category : #'private - initialization' }
LispKernel >> ignoresCase [

	^ ignoreCase
]

{ #category : #'private - interpreter' }
LispKernel >> inTail [

	"return the tail call optimization algorithm status:

		if true, the interpreter (the receiver) is evaluating in a tail location and ready to start the optimizing loop
		if false, it is not in a tail location
		if a TailCallWrapper instance, this is the optimizing loop itself

	note that it is enough to send #inTail:false at top level for turning off tail call optimization altogether.

	see method #evalTailOject: for usage"

	^ inTail 
]

{ #category : #'private - interpreter' }
LispKernel >> inTail: aBooleanOrATailCallWrapper [

	inTail := aBooleanOrATailCallWrapper
]

{ #category : #'private - initialization' }
LispKernel >> initialize [

	topmostLisp := self.

	ignoreCase := false.
	enableTailCallOptimization := true.

	self getNewEnvironment.
	constantVariables := #().
	self defineDefaultBindings.
	self definePrimitiveAliases.



]

{ #category : #'private - variables' }
LispKernel >> inputStream [

	^ self standardInput stream
]

{ #category : #'private - initialization' }
LispKernel >> installPrimitiveAliases: bindings [

	| aliases |

	aliases := bindings collect: [:b | b copy].

	"clean up previous definitions"
	environment allFboundSymbols do: [:f |  | p |
		(((p := environment symbolFunction: f ) isLKPrimitive)
			and: [(self class primitives includes: p selector) not])
		ifTrue: [environment removeSymbolFunction: f]].

	"create new definitions"
	aliases do: [:alias | 
		(environment symbolFunction: alias key  
					ifNone: [environment addSymbolFunction: alias]) isSymbol 
		ifTrue: [environment addSymbolFunction: alias]].



]

{ #category : #'private - interpreter' }
LispKernel >> interactivelyFeedInputStream [

	| str |

	str := FillInTheBlank request: 'input'.
	self standardInput stream nextPutAll: str.
	self standardInput stream skip: str size negated
]

{ #category : #'private - interpreter' }
LispKernel >> isLexical [

	^ false
]

{ #category : #'private - interpreter' }
LispKernel >> isProcedure: anObject [

	^ anObject isLKPrimitive 
			or: [anObject isProcedure]	
			or: [anObject isCompiledProcedure]

]

{ #category : #'LISP-functions-predicates' }
LispKernel >> keywordP: aConsCell [

"(keywordp SYMBOL)
Return t if SYMBOL is a keyword"	

	^ self class test: (aConsCell car isSymbol and: [aConsCell car first == $:]) 

]

{ #category : #'LISP-special forms' }
LispKernel >> lambda: aConsCell [

"(lambda ARGS &rest BODY)
Return a lambda expression.
A call of the form (lambda ARGS &rest BODY) is self-quoting: the result of evaluating the lambda expression is the expression itself.  
A lambda expression has the semantic of a function"

	^ self lambdaForm: #lambda withArgsAndBody: aConsCell

]

{ #category : #'private - subclasses may implement' }
LispKernel >> lambdaForm: aSymbol withArgsAndBody: aConsCell [

	"build and return the actual form representing the lambda form 
(lambdatype (args) ... body ...)
	where lambdatype is aSymbol, either #lambda or #macro
	(args) is aConsCell car
	... (body) ... is aConsCell cdr"

	"this implementation does nothing special"
	^ ConsCell car: aSymbol cdr: aConsCell 

]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> lambdaMessage: aConsCell [

"(lambda-message SELECTOR RECEIVER &rest ARGUMENTS)
Return a LambdaMessageSend
RECEIVER lambda: SELECTOR withArguments: ARGUMENTS"

	^ aConsCell second 
		lambda: aConsCell first
		withArguments: (aConsCell nthCell: 2) topForms

]

{ #category : #'LISP-special forms' }
LispKernel >> let: aConsCell [

"(let VARLIST &rest BODY)
Bind variables according to VARLIST then eval BODY.
The value of the last form in BODY is returned.
Each element of VARLIST is a symbol (which is bound to nil) or a list (SYMBOL VALUEFORM) (which binds SYMBOL to the value of VALUEFORM).
All the VALUEFORMs are evaluated before any symbol is bound."

	| sublisp assocs |

	aConsCell first ifNotNil:
	[
		assocs := (aConsCell first collect: [:form | 
			form isSymbol
				ifTrue: [form -> nil]
				ifFalse: [form first -> (self evalObject: (form nth: 1))]])
	].
		
	sublisp := self subLisp: #let form: aConsCell body: aConsCell cdr 
				bindings: assocs.

	^ sublisp progn: aConsCell cdr
]

{ #category : #'LISP-special forms' }
LispKernel >> letStar: aConsCell [

"(let* VARLIST &rest BODY)
Bind variables according to VARLIST then eval BODY.
The value of the last form in BODY is returned.
Each element of VARLIST is a symbol (which is bound to nil) or a list (SYMBOL VALUEFORM) (which binds SYMBOL to the value of VALUEFORM).
Each VALUEFORM can refer to the symbols already bound by this VARLIST."

	| bindings body |

	aConsCell car ifNil: [^ self let: aConsCell].
	bindings := aConsCell car topForms.

	body := aConsCell cdr ifNil: [^ nil].
	bindings reverseDo: [:b |
		body := {{#let . {b}} asCons append: body} asCons].

	^ self let: body cdar

]

{ #category : #'private - initialization' }
LispKernel >> lispEnvironment [

	^ environment 
]

{ #category : #'private - initialization' }
LispKernel >> lispEnvironment: someBindings [

	environment := someBindings
]

{ #category : #'private - utils' }
LispKernel >> lispError: aString [

	(Preferences lispKitDebugOnError 
		and: [self topLevelLisp ~~ self]) ifTrue: [self debug].

	^ LispError new signal: aString


]

{ #category : #'LISP-functions' }
LispKernel >> list: aConsCell [

"(list &rest OBJECTS)
Return a newly created list with OBJECTS as elements.
Any number of arguments, even zero, is allowed."

	^ aConsCell 
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> load: aConsCell [

"(load FILENAME [TOP])
Reads and evaluates in sequence each expression in the file specified by FILENAME (a string). 
Returns the value of the last expression.
If TOP is true, resolve a relative filename with respect to FileDirectory default, else with respect to (current-directory). In the latter case, (current-directory) is temporarily set to that file directory during the evaluation.
If the specified file does not exists, and its name does not have any extension, a default extension ('.lisp' or '.scm') is appended."

	| fileStream fname str val env currentDirectoryCache top |

	env := self topmostLisp lispEnvironment.

	fname := self systemPath: aConsCell.
	top := aConsCell cadr == self trueValue.

	fname := (top ifTrue: [FileDirectory default]
						ifFalse: [self currentDirectory]) fullNameFor: fname.

	((FileDirectory default fileExists: fname) not
		and: [((fname subStrings: FileDirectory slash) last includes: $.) not])
			ifTrue: [fname := fname, self sourceFileExtension].

	fileStream := StandardFileStream readOnlyFileNamed: fname.

	currentDirectoryCache := self currentDirectory.
	top ifFalse: [self setCurrentDirectory: (FileDirectory forFileName: fname)].

	[
		str := (LKIOPort input: fileStream) inCons.

		[fileStream atEnd]
			whileFalse:
			[	| exp |
				exp := self read: str.
				exp == LKIOPort eof
					ifFalse: [val := self eval: exp inEnvironment: env]
			].
	]
	ensure: 
	[
		fileStream close.
		self setCurrentDirectory: currentDirectoryCache
	].

	^ val


]

{ #category : #'private - initialization' }
LispKernel >> loadDefaultLibraries [

	self class defaultLibraries do: [:lib | self top: {#loadLibrary: . lib inQuotedCons}]

]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> loadLibrary: aConsCell [

"(load-library SYMBOL)
Evaluate the lisp code returned by this lisp class-side SYMBOL method"

	^ self rewriteAndEval: 
		(self class perform: aConsCell car capAtLinks asSymbol).
	
]

{ #category : #'private - subclasses may implement' }
LispKernel >> lookUpFunction: anObject [

	"anObject was found in the functional position of a function invocation, that is as the car of a cons cell to be evaluated.
	return the actual function to be used" 

	anObject isProcedure ifTrue: [^ anObject].
	^ self symbolFunction: anObject ifNone: [anObject]  
]

{ #category : #'LISP-special forms' }
LispKernel >> macro: aConsCell [

"(macro ARGS &rest BODY)
Return a nlambda expression.
A call of the form (macro ARGS &rest BODY) is self-quoting: the result of evaluating the nlambda expression is the expression itself.  
A nlambda expression has the semantic of a special form, or macro"

	^ self lambdaForm: #macro withArgsAndBody: aConsCell
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> macroexpand: aConsCell [ 

"(macroexpand MACRO)

Return result of expanding macros at top level of FORM.
If FORM is not a macro call, it is returned unchanged.
Otherwise, the macro is expanded and the expansion is considered
in place of FORM.  When a non-macro-call results, it is returned"

	| func bindings |

	aConsCell car isConsCell ifFalse: [^ aConsCell car].

	func := self symbolFunction: aConsCell car car ifNone: [^ aConsCell car].
	func isProcedure ifFalse: [^ aConsCell car].
	func lambdaForm car = #macro ifFalse: [^ aConsCell car].
	func := func lambdaForm.

	bindings := ((func lambdaFormBindingsWith: aConsCell cdar) 
					collect: [:a | 
						a key inCons setcdr: a value inQuotedCons inCons]) 
				asCons.

	^ self macroexpand: (self let: (bindings inCons append: (func nthcdr: 2))) inCons
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> macroexpandONE: aConsCell [ 

"(macroexpand-1 MACRO)

Return result of expanding macros at top level of FORM.
If FORM is not a macro call, it is returned unchanged.
Otherwise, the macro is expanded and the expansion is returned"

	| func bindings |

	aConsCell car isConsCell ifFalse: [^ aConsCell car].

	func := self symbolFunction: aConsCell car car ifNone: [^ aConsCell car].
	func isProcedure ifFalse: [^ aConsCell car].
	func lambdaForm car = #macro ifFalse: [^ aConsCell car].
	func := func lambdaForm.

	bindings := ((func lambdaFormBindingsWith: aConsCell cdar) 
					collect: [:a | 
						a key inCons setcdr: a value inQuotedCons inCons]) 
				asCons.

	^ self let: (bindings inCons append: (func nthcdr: 2))
]

{ #category : #'LISP-special forms' }
LispKernel >> macrolet: aConsCell [

"(macrolet VARLIST &rest BODY)
Make temporary macro definitions.
This is like `flet', but for macros instead of functions."

	| sublisp |

	sublisp := self subLisp: #macrolet form: aConsCell body: aConsCell cdr. 

	aConsCell first ifNotNil:
	[
		(aConsCell first collect: [:form | 
			sublisp checkSymbol: form first. 
			form first -> (self lambdaForm: #macro withArgsAndBody: form cdr)])
		do: [:v | sublisp lispEnvironment addSymbolFunction: v]
	].

	(aConsCell cdr ifNil: [^ nil]) 
		doWithCdr: [:c :cdr | 
			cdr ifNil: [^ sublisp evalTailObject: c].
			sublisp evalObject: c]
]

{ #category : #'LISP-functions' }
LispKernel >> makeVector: aConsCell [

"(make-vector LENGTH INIT)
Return a newly created vector of length LENGTH, with each element being INIT."

	^ Array new: aConsCell car withAll: aConsCell cadr
]

{ #category : #'LISP-functions' }
LispKernel >> makunbound: aConsCell [

"(makunbound SYMBOL)
Make SYMBOL's value be void."

	| s |
	s := self checkSymbol: aConsCell car.
	(self symbolValuesDictionaryFor: s) removeKey: s ifAbsent: [].
	^ s

	
]

{ #category : #'private - interpreter' }
LispKernel >> monitor [

	^ monitor
]

{ #category : #'private - interpreter' }
LispKernel >> monitor: aLKMonitor [

	monitor := aLKMonitor
]

{ #category : #'LISP-functions-monitoring' }
LispKernel >> monitorAll: ignored [

"(monitor-all)
Trace all evaluated forms"

	self monitor: LKTracer new.
	^ self monitor
]

{ #category : #'LISP-functions-monitoring' }
LispKernel >> monitorFunctions: aConsCell [

"(monitor-functions &rest ARGS)
Trace all calls to ARGS"

	self monitor: (LKFunctionsTracer new functions: aConsCell arrayForm).
	^ self monitor
]

{ #category : #'LISP-functions-monitoring' }
LispKernel >> monitorHalt: aConsCell [

"(monitor-halt &rest PREDS)
Halt right before evaluating a call to any of PREDS (which are symbols)"

	self monitor: (LKHalt new functions: aConsCell arrayForm).
	^ self monitor
]

{ #category : #'LISP-functions-monitoring' }
LispKernel >> monitorOff: ignored [

"(monitor-off])
Stop all monitoring activities"

	self monitor: nil.
	^ self monitor
]

{ #category : #'LISP-functions-monitoring' }
LispKernel >> monitorSymbols: aConsCell [

"(monitor-symbols &rest SYMBOLS)
Trace all references to ARGS"

	self monitor: (LKSymbolsTracer new symbols: aConsCell arrayForm).
	^ self monitor
]

{ #category : #'LISP-special forms' }
LispKernel >> multipleValueBind: aConsCell [

"(multiple-value-bind VARS FORM &rest BODY)
Bind VARS (a  list of symbols) according to the values of FORM,
then eval BODY.
The value of the last form in BODY is returned"

	| sublisp values i val |

	sublisp := self subLisp: #'multiple-value-bind' 
		form: aConsCell body: aConsCell cddr. 

	values := self evalToValues: aConsCell cadr.
	i := 0.
	aConsCell first do: [:sym | 
			sublisp checkSymbol: sym. 
			i := i + 1.
			sublisp symbolValuesAdd: (sym -> (values at: i ifAbsent: [nil]))].

	((aConsCell nthCell: 2) ifNil: [^ nil]) do: [:c | val := sublisp evalObject: c].
	^ val
]

{ #category : #'LISP-special forms' }
LispKernel >> multipleValueCall: aConsCell [

	""

	| argstr |
	
	argstr := WriteStream on: #().

	argstr nextPut: (self evalObject: aConsCell car).
	aConsCell cdr do: [:form |
		argstr nextPutAll: (self evalToValues: form)].

	^ self evalObject: argstr contents asCons
]

{ #category : #'LISP-special forms' }
LispKernel >> multipleValueList: aConsCell [

	"(multiple-value-list FORM)
Evaluate FORM and create a list of the multiple values it returns."
	
	^ (self evalToValues: aConsCell car) asCons
]

{ #category : #'LISP-special forms' }
LispKernel >> multipleValueSetq: aConsCell [

"(multiple-value-setq VARS FORM)
VARS must be a list of variables. FORM is evaluated, and the variables are set (not bound) to the values returned by FORM. 
If there are more variables than values returned, extra values of nil are assigned to the remaining variables. 
If there are more values than variables, the excess values are simply discarded.
multiple-value-setq always returns a single value, which is the first value returned by form, or nil if form produces zero values."

	| dict values i |
	
	values := self evalToValues: aConsCell cadr.
	i := 0.
	aConsCell car do: [:sym |
		self checkSymbol: sym.
		dict := self symbolValuesDictionaryFor: sym.
		i := i + 1.
		dict add: sym -> (values at: i ifAbsent: [nil])].
	
	^ values at: 1 ifAbsent: [nil]
]

{ #category : #'private - subclasses may implement' }
LispKernel >> nonPrimitiveSymbolFunction: aSymbol ifNone: aBlock [

	^ environment symbolFunction: aSymbol ifNone: aBlock
	


]

{ #category : #'private - interpreter' }
LispKernel >> nthUpperLisp: aNumber [

	aNumber = 1 ifTrue: [^ upperLisp].

	^ (upperLisp ifNil: [^ nil]) nthUpperLisp: aNumber - 1  
]

{ #category : #'LISP-special forms' }
LispKernel >> nthValue: aConsCell [

	"(nth-value N FORM)
Evaluate N and then FORM, returning as its only value the Nth value yielded by FORM, or nil if N is greater than or equal to the number of values returned by form. (The first returned value is numbered 0)"
	
	^ (self evalToValues: aConsCell cadr) at: (aConsCell car + 1) ifAbsent: [nil]
]

{ #category : #GUI }
LispKernel >> openGui [

	self gui openInWorld.
]

{ #category : #'private - utils' }
LispKernel >> output: aString [

	| port |

	(port := self standardOutput) stream nextPutAll: aString.
	port endEntry.

]

{ #category : #GUI }
LispKernel >> outputStream [
	"used by the REPL"

	^ self standardOutputPort stream
]

{ #category : #'LISP-functions-predicates' }
LispKernel >> primitiveP: aConsCell [

"(primitive-p SYMBOL)
If SYMBOL globally names a primitive, then a non-nil value is returned; otherwise nil is returned"	

	| sf sel |

	sf := self symbolFunction: aConsCell car ifNone: [^ self falseValue].
	sf isLKPrimitive ifTrue: [sel := sf selector].
	sf isSymbol ifTrue: [sel := sf].
	sel ifNil: [^ self falseValue].

	^ self class test: (self class primitives pointsTo: sel) 
	

]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> primitives: aConsCell [

"(primitives)
Return a list of all functions and special forms implemented as primitives."

	^ (self class primitives sort collect: [:p |
			p last == $: ifFalse: [p]
				ifTrue: [self class aliasForPrimitive: p]]) asConsList
	
]

{ #category : #'private - variables' }
LispKernel >> printCircle [

	^ self symbolValue: #'*print-circle*' ifNone: [nil]
]

{ #category : #'private - variables' }
LispKernel >> printLength [

	^ self symbolValue: #'*print-length*' ifNone: [nil]
]

{ #category : #'private - variables' }
LispKernel >> printLevel [

	^ self symbolValue: #'*print-level*' ifNone: [nil]
]

{ #category : #'private - symbols' }
LispKernel >> printSymbol: aSymbol on: aStream [

	aStream nextPutAll: aSymbol
]

{ #category : #'LISP-special forms' }
LispKernel >> profile: aConsCell [

"(profile FORM)
Evaluate FORM with a TimeProfileBrowser spying."

	^ TimeProfileBrowser spyOn: [self evalNewTailObject: aConsCell car] 
]

{ #category : #'LISP-special forms' }
LispKernel >> progn: aConsCell [

"(progn &rest BODY)
Eval BODY forms sequentially and return value of last one."

	| v |

	aConsCell ifNil: [^ nil].
	aConsCell doWithCdr: [:form :cdr | 
		cdr ifNil: [v := self evalTailObject: form]
			ifNotNil: [self evalObject: form]].
	
	^ v
	
]

{ #category : #GUI }
LispKernel >> prompt [
	
	| d |

	^ ((d := self depth) isZero ifTrue: ['top'] ifFalse: ['-',d asString,'-']), '>'
]

{ #category : #'property lists' }
LispKernel >> put: aSymbol symbol: bSymbol value: anObject [

	| plist prop |

	plist := (self remprop: aSymbol symbol: bSymbol).
	prop := {aSymbol . anObject} asConsList.	

	plist ifNotNil: [plist append: prop]
		ifNil: [self symbolPlists add: (bSymbol -> prop)].

	^ anObject
]

{ #category : #'LISP-special forms' }
LispKernel >> quasiquote: aConsCell [

"(quasiquote TEMPLATE)
The whole TEMPLATE acts as if it was quoted except for certain
places where expressions are evaluated and inserted or spliced in.

For example: if b is bound to (1 2 3)		
`(a b c) => (a b c)		
`(a ,b c) => (a (1 2 3) c)	
`(a ,@b c) => (a 1 2 3 c)	

Nested quasiquotes are permitted."

	(aConsCell car ifNil: [^ nil]) first == #unquote 
			ifTrue: [^ (self quasiquoteForm: aConsCell depth: 0) car].

	aConsCell car first == #'unquote-splicing'
			ifTrue: [self lispError: 'invalid context for unquote-splicing'].

	^ self quasiquoteForm: aConsCell car depth: 0


]

{ #category : #'private - interpreter' }
LispKernel >> quasiquoteForm: aForm depth: depth [

	| cons |

	aForm isArray ifTrue: 
		[^ (self quasiquoteForm: aForm asConsList depth: depth) topForms].
	aForm isConsCell ifFalse: [^ aForm].

	cons := ConsCell new.

	(aForm doWithCdr: [:form :cdr|
		(form == #unquote
			and: [(cdr == aForm cdr) not] 
			and: [cdr cdr isNil]
			and: [depth = 0])
		ifTrue: [cons append: (self evalObject: cdr car). ^ cons cdr]
		ifFalse: 
		[
			((form isConsCell
					and: [form first == #unquote 
							or: [form first == #'unquote-splicing']])
				ifTrue: 
				[	
					depth = 0 ifTrue:
					[
						form first == #unquote 
							ifTrue: [cons addLast: (self evalObject: form second)]
							ifFalse: [cons append2: (self evalObject: form second)]
					]
					ifFalse:
					[cons addLast: (self quasiquoteForm: form depth: depth - 1)]
				]
				ifFalse: 
				[
					(form isConsCell and: [form first == #quasiquote])
					ifTrue: [cons addLast: 
								(self quasiquoteForm: form depth: depth + 1)]
					ifFalse: [cons addLast: 
								(self quasiquoteForm: form depth: depth)]
				]).
			(cdr notNil and: [cdr isConsCell not]) ifTrue: [cons append: cdr]
		]]) .

	^ cons cdr


]

{ #category : #'LISP-special forms' }
LispKernel >> quote: aConsCell [

"(quote ARG)
Return ARG without evaluating it."

	^ aConsCell car
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> read: aConsCell [

"(read &optional PORT)
Read a Lisp expression from PORT, return it as a Lisp object.
PORT can be a string
If it is nil, user is interactively prompted for a string"

	| port stdin reader | 

	stdin := self standardInput.
	(port := aConsCell car) ifNil: [port := stdin].
	reader := self reader.

	port isString ifTrue: [^ reader read: (ReadStream on: port)].

	(port == stdin 
		and: [(reader foundToken: port stream) not]) "weird logic,to be corrected.."
	ifTrue: [
			self focusedREPL
				ifNil: [self interactivelyFeedInputStream]        "no GUI"
				ifNotNil: ["we have a GUI, just wait for input"
					"first make sure there is no pending output:"
					self standardOutput endEntry; force. 
					"now wait"
					[port atEnd] whileTrue: [World doOneCycle.  Processor yield]]].

	^ reader read: port stream


]

{ #category : #'private - interpreter' }
LispKernel >> reader [

	^ LKReader for: self
]

{ #category : #'property lists' }
LispKernel >> remprop: aSymbol symbol: bSymbol [

	| plist |

	plist := self symbolPlists at: bSymbol ifAbsent: [^ nil].

	plist car == aSymbol 
		ifTrue: [self symbolPlists add: (bSymbol -> plist cddr). ^ plist cddr]
		ifFalse:
		[
			plist := plist cdr.
			[plist cdr notNil] whileTrue:
			[
				plist cadr == aSymbol 
					ifTrue: [plist setcdr: plist cddr cdr. 
								^ self symbolPlists at: bSymbol].
				plist := plist cddr
			].
		].
	
	^ self symbolPlists at: bSymbol
]

{ #category : #'private - utils' }
LispKernel >> rewriteAndEval: anObject [

	"lisp primitives should use this methods instead of #top: which is always considered as the topmost context of a Lisp interpreter."

	^ self eval: (self class rewrite: anObject asCons) inCons.

]

{ #category : #hacks }
LispKernel >> selectionInterval [
	
	"required by Parser>>#temporariesIn: "

	^ 1 to: 1
]

{ #category : #'LISP-special forms-Smalltalk' }
LispKernel >> send1: aConsCell [

"	
(send1 SELECTOR RECEIVER  &rest ARGUMENTS)
Special form: send SELECTOR (a symbol) to RECEIVER with ARGUMENTS
if RECEIVER is a symbol matching the name of a Squeak class, use this class

examples:
	(send1 now Time )
	(send1 + 1 1)
 	(send1 copyFrom:to: #(1 2 3 4 5)  3 5)
"
	^ self send: (ConsCell car: aConsCell cadr 
					cdr: (ConsCell car: aConsCell car cdr: aConsCell cddr))
]

{ #category : #'LISP-special forms-Smalltalk' }
LispKernel >> send: aConsCell [

"	
(send RECEIVER SELECTOR &rest ARGUMENTS)
Special form: send SELECTOR (a symbol) to RECEIVER with ARGUMENTS
if RECEIVER is a symbol matching the name of a Squeak class, use this class

examples:
	(send Time now)
	(send 1 + 1)
 	(send #(1 2 3 4 5) copyFrom:to: 3 5)
"

	| rsym rec args |

	rsym := aConsCell car.	
	(rsym isSymbol	
		and: [rsym first isUppercase])
	ifTrue: [rec := Smalltalk at: rsym ifAbsent: [nil]].
		
	rec ifNil: [rec := self evalObject: rsym].

	args := aConsCell cdr cdr.
	args ifNil: [
		[^ rec perform: aConsCell cadr]
		on: Error do: [:e | e signal: e messageText, ' in ', aConsCell asString]].

	[
		^ rec
			perform: aConsCell cadr
			withArguments: (args topForms collect: [:arg | self evalObject: arg])
	] 
	on: Error do: [:e | e signal: e messageText, ' in ', aConsCell asString]
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> sendCascade: aConsCell [

"(send-cascade SELECTORS RECEIVER)
SELECTORS is a list of symbols SELECTOR-N or list (SELECTOR-N [ARGSN])
this function evaluate in turn the Smalltalk expressions
RECEIVER perform: SELECTOR1 withArguments: ARGS1
RECEIVER perform: SELECTOR2 ... 
and return the last value we get
"
	
	| val receiver |

	receiver := aConsCell second.

	aConsCell first do: [:spec | 
		| sel args |
		sel := spec isSymbol ifTrue: [spec] ifFalse: [spec car].
		args := spec isSymbol ifTrue: [#()] ifFalse: [spec cdr topForms].
		val := receiver perform: sel withArguments: args].

	^ val
]

{ #category : #'LISP-special forms-Smalltalk' }
LispKernel >> sendD: aConsCell [

"	
(send! RECEIVER SELECTOR &rest MESSAGES)
Special form: send in turn all MESSAGES to RECEIVER
if RECEIVER is a symbol matching the name of a Squeak class, use this class.
each MESSAGE is a list (SELECTOR &rest ARGUMENTS) where SELECTOR must be a symbol, which will not be evaluated.
Returns a list of results .

examples:
	(send! 2 (+ 1) (- 1) (* 2))
	(send! Smalltalk (osVersion) (vmVersion))
"
	| rsym rec |

	rsym := aConsCell car.	
	(rsym isSymbol	
		and: [rsym first isUppercase])
	ifTrue: [rec := Smalltalk at: rsym ifAbsent: [nil]].
		
	rec ifNil: [rec := self evalObject: rsym].

	^ aConsCell cdr collect: [:message |
	[
		rec perform: message car
		withArguments: (message cdr topForms 
								collect: [:arg | self evalObject: arg])
	] 
	on: Error do: [:e | e signal: e messageText, ' in ', message asString]]	


]

{ #category : #'LISP-special forms-Smalltalk' }
LispKernel >> sendForValues: aConsCell [

"	
(send-for-values RECEIVER SELECTOR &rest ARGUMENTS)
Special form: send SELECTOR (a symbol) to RECEIVER with ARGUMENTS
if RECEIVER is a symbol matching the name of a Squeak class, use this class
If the result is a Collection, return its elements as multiple values

example:
	(send-for-values #(1 2 3 4 5) copyFrom:to: 3 5)"

	| val  |

	val := self send: aConsCell.
	val isCollection ifFalse: [^ val].

	^ val as: LKValues
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> sendMessage: aConsCell [

"(send-message SELECTOR RECEIVER &rest ARGUMENTS)
Evaluate the Smalltalk expression
RECEIVER perform: SELECTOR withArguments: ARGUMENTS"

	^ aConsCell second perform: aConsCell first
		withArguments: (aConsCell nthCell: 2) topForms
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> sendSelectors: aConsCell [

"(send-selectors SELECTORS RECEIVER)
SELECTORS is a list of symbols SELECTOR-N or list (SELECTOR-N [ARGSN])
this function evaluate the Smalltalk expression
(RECEIVER perform: SELECTOR1 withArguments: ARGS1) perform: SELECTOR2 ... "
	
	| receiver |

	receiver := aConsCell second.
	aConsCell first do: [:spec | 
		| sel args |
		sel := spec isSymbol ifTrue: [spec] ifFalse: [spec car].
		args := spec isSymbol ifTrue: [#()] ifFalse: [spec cdr topForms].
		receiver := receiver perform: sel withArguments: args].

	^ receiver
]

{ #category : #'LISP-special forms-Smalltalk' }
LispKernel >> sendStar: aConsCell [

"	
(send* RECEIVER &rest MESSAGES)
Special form: pipe all MESSAGES to RECEIVER.
if RECEIVER is a symbol matching the name of a Squeak class, use this class.
each MESSAGE is a symbol SELECTOR or a list (SELECTOR &rest ARGUMENTS) 
where SELECTOR must be a symbol, which will not be evaluated.
Returns the results of the last call .

examples:
	(send* 2 (+ 1) (- 1) (* 2))
"
	| rsym rec |

	rsym := aConsCell car.	
	(rsym isSymbol	
		and: [rsym first isUppercase])
	ifTrue: [rec := Smalltalk at: rsym ifAbsent: [nil]].
		
	rec ifNil: [rec := self evalObject: rsym].
	
	aConsCell cdr do: [:message |
	[
		rec := message isSymbol ifTrue: [rec perform: message]
			ifFalse: [rec perform: message car
				withArguments: (message cdr topForms collect: [:arg | self evalObject: arg])]
	] 
	on: Error do: [:e | e signal: e messageText, ' in ', message asString]].
.
	^ rec


]

{ #category : #'LISP-special forms' }
LispKernel >> set: aConsCell [

"(set SYMBOL NEWVAL)
Set SYMBOL's value to NEWVAL, and return NEWVAL."

	| dict symb val |
	symb := self checkSymbol: (self evalObject: aConsCell car).
	dict := self symbolValuesDictionaryFor: symb.
	dict add: symb -> (val := (self evalObject: aConsCell cadr)).	
	^ val
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> setCurrentDirectory: aFileDirectory [

	currentDirectory := aFileDirectory


]

{ #category : #'LISP-functions' }
LispKernel >> setplist: aConsCell [

"(setplist SYMBOL PLIST)
Set SYMBOL's property list to PLIST. Return PLIST."

	aConsCell car isSymbol ifFalse: [self lispError: 'not a symbol'].
	self symbolPlists add: aConsCell car -> aConsCell cadr.
	^ aConsCell cadr
]

{ #category : #'LISP-special forms' }
LispKernel >> setq: aConsCell [

"(setq SYM VAL SYM VAL ...)
Set each SYM to the value of its VAL.
The symbols SYM are variables; they are literal (not evaluated).
The values VAL are expressions; they are evaluated.
Thus, (setq x (1+ y)) sets `x' to the value of `(1+ y)'.
The second VAL is not computed until after the first SYM is set, and so on;
each VAL can use the new value of variables set earlier in the `setq'.
The return value of the `setq' form is the value of the last VAL."

	| dict val form |
	
	form := aConsCell.
	[form notNil] whileTrue:
	[
		self checkSymbol: form car.
		dict := self symbolValuesDictionaryFor: form car.

		dict add: form car -> (val := (self evalObject: form cadr)).
		form := form cdr cdr
	].
	
	^ val
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> smalltalk: aConsCell [
	
"(smalltalk STRING)
Evaluate STRING as Smalltalk code."

	aConsCell car isString ifFalse: [self lispError: 'string argument expected'].

	"the invocation below needs methods #selectionInterval and #text to work properly; Parser should be fixed I guess."
	^ Compiler
		evaluate: aConsCell car
		for: self notifying: self logged: false.
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> smalltalkClass: aConsCell [
	
"(smalltalk-class SYMBOL)
Returns the Smalltalk class SYMBOL"

	aConsCell car isSymbol ifFalse: [^ self falseValue].

	^ Smalltalk at: aConsCell car ifAbsent: [self falseValue]
]

{ #category : #'private - subclasses may implement' }
LispKernel >> sourceFileExtension [

	"used for autocompletion of filenames without extensions, see #load:"

	^ '.lisp'
]

{ #category : #'LISP-functions-predicates' }
LispKernel >> specialFormP: aConsCell [

"(special-form-p SYMBOL)
If SYMBOL globally names a special form, then a non-nil value is returned; otherwise nil is returned"	

	| sf sel |

	sf := self symbolFunction: aConsCell car ifNone: [^ self falseValue].
	sf isLKPrimitive ifTrue: [^ self class test: sf isLKPrimitiveSpecial].
	sf isSymbol ifTrue: [sel := sf].
	sel ifNil: [^ self falseValue].

	^ self class test: (self class specialForms pointsTo: sel) 
	
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> specialForms: aConsCell [

"(special-forms)
Return a list of all special forms implemented as primitives."

	^ ((self class specialForms sort collect: [:p |
			p last == $: ifFalse: [p]
				ifTrue: [self class aliasForPrimitive: p]])
		select: [:p | (self primitiveP: p inCons) == self trueValue]) asConsList
	
]

{ #category : #'private - variables' }
LispKernel >> standardInput [

	^ self symbolValue: #'*standard-input*' ifNone: [nil]
]

{ #category : #'private - variables' }
LispKernel >> standardInput: aLKIOPortOrAString [

	"dangerous method. the value of inputPort should always be synchronized with the Lisp value *standard-input*, and should almost never be a String

	still, this is useful at times..."

	inputPort := aLKIOPortOrAString
]

{ #category : #'private - subclasses may implement' }
LispKernel >> standardInputPort [
	"the default port for input, used by read functions"

	upperLisp ifNotNil: [^upperLisp standardInputPort	"safer"].
	^inputPort ifNil: [inputPort := LKIOPort forInput]
]

{ #category : #'private - variables' }
LispKernel >> standardOutput [

	^ self symbolValue: #'*standard-output*'	ifNone: [nil]
]

{ #category : #'private - subclasses may implement' }
LispKernel >> standardOutputPort [
	"the default port for output, used by print functions"

	upperLisp ifNotNil: [^upperLisp standardOutputPort	"safer"].
	^outputPort ifNil: [outputPort := LKIOPort forOutput]
]

{ #category : #'private - subclasses may implement' }
LispKernel >> subCompiler [

	^ self copy lispEnvironment: environment newChild
]

{ #category : #'private - subclasses may implement' }
LispKernel >> subLisp [

	^ self subLisp: #tmp form: nil body: nil environment: environment newChild

]

{ #category : #'private - subclasses may implement' }
LispKernel >> subLisp: aSymbol form: aForm body: aConsCell [

	^ self subLisp: aSymbol form: aForm body: aConsCell environment: environment newChild

]

{ #category : #'private - subclasses may implement' }
LispKernel >> subLisp: aSymbol form: aForm body: aConsCell bindings: anArray [

	| sublisp |

	sublisp := self subLisp: aSymbol form: aForm body: aConsCell.
	
	(anArray ifNil: [^ sublisp]) 
		do: [:assoc | 
				sublisp checkSymbol: assoc key.
				sublisp symbolValuesAdd: assoc].

	^ sublisp

	

]

{ #category : #'private - subclasses may implement' }
LispKernel >> subLisp: aSymbol form: aForm body: aConsCell environment: aLKEnvironment [

	"local scope is implemented by creating a temporary copy of the whole interpreter where local bindings will be made. this method is the place for defining how exactly the copy should be made.

	the 'body' argument is used by CLisp for handling of declarations. see how it overrides this method"


	self monitor ifNotNil: [self monitor subLisp: aForm from: self].

	^ self copy
		lispEnvironment: aLKEnvironment;
		upperLisp: self;
		upperHead: aSymbol;
		upperTail: aForm
]

{ #category : #'private - interpreter' }
LispKernel >> subLispForTailWithEnvironment: env [

	^ self lispEnvironment: env
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> symbolFunction: aConsCell [

"(symbol-function SYMBOL)
Return SYMBOL's function definition.  Raise an error if there is none."

	^ self symbolFunction: aConsCell car
				ifNone: [self errorUndefinedFunction: aConsCell car].

]

{ #category : #'private - subclasses may implement' }
LispKernel >> symbolFunction: aSymbol ifNone: aBlock [

	"look-up for the function bound to aConscell car (which should be a symbol). if none found, evaluate aBlock"

	^ self class cachedPrimitive bindingFor: aSymbol ifNone: 
		[self nonPrimitiveSymbolFunction: aSymbol ifNone: aBlock]
	


]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> symbolName: aConsCell [

"(symbol-name SYMBOL)
Return SYMBOL's name, a string."

	aConsCell car isSymbol ifFalse: [self lispError: 'not a symbol'].
	^ aConsCell car asString
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> symbolPlist: aConsCell [

"(symbol-plist SYMBOL)
Return SYMBOL's property list."

	aConsCell car isSymbol ifFalse: [self lispError: 'not a symbol'].
	^ self symbolPlists at: aConsCell car ifAbsent: [nil]
]

{ #category : #'private - symbols' }
LispKernel >> symbolPlists [

	^ environment symbolPlists
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> symbolValue: aConsCell [

"(symbol-value SYMBOL)
Return SYMBOL's value.  Raise an error if there is none."

	^ self symbolValue: aConsCell car
		ifNone: [self lispError: 'no value for symbol ', aConsCell car asString]

]

{ #category : #'private - subclasses may implement' }
LispKernel >> symbolValue: aSymbol ifNone: aBlock [

	":keywords evaluate to themselves"
	aSymbol first == $: ifTrue: [^ aSymbol].

	 ^ environment symbolValue: aSymbol ifNone: aBlock

	
	
]

{ #category : #'private - subclasses may implement' }
LispKernel >> symbolValuesAdd: anAssociation [

	environment addSymbolValue: anAssociation .
	self monitor ifNotNil: 
		[self monitor symbolsValuesAdded: anAssociation in: self]
]

{ #category : #'private - subclasses may implement' }
LispKernel >> symbolValuesDictionaryFor: aSymbol [

	^ environment symbolValuesDictionaryFor: aSymbol
]

{ #category : #'LISP-special forms' }
LispKernel >> tally: aConsCell [

"(tally FORM)
Evaluate FORM with a MessageTally spying."

	^ MessageTally spyOn: [self evalNewTailObject: aConsCell car] 
]

{ #category : #'private - utils' }
LispKernel >> test: aBoolean [

	^ self class test: aBoolean
]

{ #category : #hacks }
LispKernel >> text [
	
	"required by Parser>>#removeUnusedTemps"

	^ ' ' asText
]

{ #category : #'LISP-functions-Smalltalk' }
LispKernel >> thisLisp: ignored [

"(this-lisp)
Returns the Lisp interpreter itself"

	^ self
]

{ #category : #'LISP-special forms' }
LispKernel >> throw: aConsCell [

"(throw TAG VALUE)
Throw to the catch for TAG and return VALUE from it.
Both TAG and VALUE are evaluated."

	aConsCell ifNil: [^ #()].

	((LKThrowNotification new)
		tag: (self evalObject: aConsCell first);
		value: (self evalObject: aConsCell second)) signal
	

	
]

{ #category : #'LISP-special forms' }
LispKernel >> time: aConsCell [

"(time EXPRESSION [PRINT])
times the evaluation of EXPRESSION
if PRINT is true, prints timing information to the current output port. 
returns two values: the result of EXPRESSION and the elapsed time in milliseconds."

	| dur val gcStats str port pflag |

	pflag := aConsCell cadr == self trueValue.

	gcStats := SmalltalkImage current getVMParameters.
	dur := [val := self evalNewTailObject: aConsCell car] durationToRun.
	SmalltalkImage current getVMParameters keysAndValuesDo:
		[:idx :gcVal| 
			(#(7 8 9 10) pointsTo: idx) ifTrue: [gcStats at: idx put: (gcVal - (gcStats at: idx))]].

	pflag ifTrue:
	[
		str := (port := self standardOutput) stream.
	
		str nextPutAll: 'time: '.
		dur printOn: str.
		str cr; nextPutAll: 'full gc: '.
		(gcStats at: 7) printOn: str.
		str nextPutAll: ' time: '.
		(gcStats at: 8) printOn: str.
		str cr; nextPutAll: 'incr. gc: '.
		(gcStats at: 9) printOn: str.
		str nextPutAll: ' time: '.
		(gcStats at: 10) printOn: str.
		str cr.

		port endEntry
	].

	^ LKValues with: val with: dur asMilliSeconds

]

{ #category : #'entry points' }
LispKernel >> top: anObject [

	"entry point to the Lisp interpreter for the evaluation of Arrays as Lisp code. 

	anObject can be anything; the message #asCons converts it in a suitable data structure for Lisp.
	notably, if it is an Array it will be converted into a ConsCell (with an exception for vectors, see Array>>asCons). 
	the #rewrite: call allows syntactic sugar such as ` and ,@ in Arrays.

	because it is an entry point to the interpreter context, #top: should never be sent from within a Lisp program; it should not be used by any primitive. use #rewriteAndEval: instead.

	see #enterInterpreterContextAndEval: for the rationale"

	^ self enterInterpreterContextAndEval: (self class rewrite: anObject asCons).

]

{ #category : #'private - utils' }
LispKernel >> topLevelLisp [

	"should be invoked by functions primitives only. answer the lisp instance at top level, which is either the receiver or a member of the #upperLisp chain"

	^ self topLevelLispFor: thisContext

]

{ #category : #'private - utils' }
LispKernel >> topLevelLispFor: aContext [

	"private - anciliary method for #topLevelLisp"

	(aContext receiver class
		selectorAtMethod: aContext method 
		setClass: [:c | ])
	== #top: 
	ifTrue: [^ aContext receiver].

	^ self topLevelLispFor: aContext sender

]

{ #category : #'private - interpreter' }
LispKernel >> topmostLisp [

	^ topmostLisp
]

{ #category : #'private - interpreter' }
LispKernel >> trueValue [

	^ self class trueValue
]

{ #category : #'LISP-special forms' }
LispKernel >> unquote: aConsCell [

"(unquote ANYTHING)
This form as such evaluates to itself. It should only be used within a quasiquote expression; usually the syntactic sugar ',' is preferred."

	^ ConsCell car: #unquote cdr: aConsCell


]

{ #category : #'LISP-special forms' }
LispKernel >> unquoteSplicing: aConsCell [

"(unquote-splicing ANYTHING)
This form as such evaluates to itself. It should only be used within a quasiquote expression; usually the syntactic sugar ',@' is preferred."

	^ ConsCell car: #'unquote-splicing' cdr: aConsCell


]

{ #category : #'LISP-special forms' }
LispKernel >> unwindProtect: aConsCell [

"(unwind-protect BODYFORM &rest UNWINDFORMS)
Do BODYFORM, protecting with UNWINDFORMS.
If BODYFORM completes normally, its value is returned after executing the UNWINDFORMS.
If BODYFORM exits nonlocally, the UNWINDFORMS are executed anyway."

	| val |

	aConsCell ifNil: [^ #()].

	[val := self evalObject: aConsCell first multipleValue: true]
		on: Exception do: [].

	(aConsCell cdr ifNil: [^ val]) 
		do: [:form | self evalObject: form].

	^ val

	
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> updatePrimitives: ignored [

"(update-primitives)
Perform the integration of newly defined primitives into the LispKernel hierarchy system, clean up if necessary
This has on-the-fly effect to all lisp interpreter instances"

	LispKernel updatePrimitives.
	^ self trueValue
]

{ #category : #'private - utils' }
LispKernel >> upperForm [
	^upperHead inCons append: upperTail
]

{ #category : #'private - utils' }
LispKernel >> upperForms [

	upperLisp ifNil: [^ {self upperForm}].

	^ {self upperForm}, upperLisp upperForms
]

{ #category : #'LISP-functions-debugging' }
LispKernel >> upperForms: ignored [

	^ self upperForms asConsList
]

{ #category : #'private - utils' }
LispKernel >> upperHead [

	^ upperHead
]

{ #category : #'private - utils' }
LispKernel >> upperHead: aSymbol [

	upperHead := aSymbol
]

{ #category : #'private - interpreter' }
LispKernel >> upperLisp [

	^ upperLisp 
]

{ #category : #'private - interpreter' }
LispKernel >> upperLisp: aLisp [

	upperLisp := aLisp
]

{ #category : #'private - utils' }
LispKernel >> upperTail [
	^upperTail
]

{ #category : #'private - utils' }
LispKernel >> upperTail: aConsCell [ 
	upperTail := aConsCell
]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> values: aConsCell [

	^ LKValues withAll: aConsCell topForms


]

{ #category : #'LISP-functions-interpreter' }
LispKernel >> valuesList: aConsCell [

	^ LKValues withAll: aConsCell car topForms


]

{ #category : #'LISP-functions' }
LispKernel >> vconcat: aConsCell [

"(vconcat &rest VECTORS)
Concatenate all the arguments.
The result is a vector whose elements are the elements of all VECTORS."

	^ Array streamContents: [:str |
	 	aConsCell do: [:v | str nextPutAll: v]]
]

{ #category : #'LISP-functions' }
LispKernel >> vector: aConsCell [

"(vector &rest OBJECTS)
Return a newly created vector with specified arguments as elements.
Any number of arguments, even zero arguments, are allowed."
	
	aConsCell ifNil: [^ #()].
	^ Array streamContents: [:str | aConsCell do: [:o | str nextPut: o]]

]

{ #category : #'LISP-functions-predicates' }
LispKernel >> vectorP: aConsCell [

"(vectorp OBJECT)
Return #t if OBJECT is a vector."

	^ self class test: aConsCell car isArray
]
