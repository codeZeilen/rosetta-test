"
a Lisp-2 dialect with lexical scoping plus special (dynamic) variables following the rules of Common Lisp 

see the SUnit coverage in CLispTest
"
Class {
	#name : #CLisp,
	#superclass : #StaticLisp,
	#instVars : [
		'dynamicSymbolValues',
		'specialVariables'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #libraries }
CLisp class >> defaultLibraries [

	^ #(glue #'provide-library' plist compilers #'small-macros' common #'arguments-lists' loop #'turtle-graphics')
]

{ #category : #private }
CLisp class >> initialize [

	super initialize
]

{ #category : #GUI }
CLisp >> buildMenu: aMenu [

	aMenu defaultTarget: self.
	
	aMenu 
		add: 'see dynamic symbol values' target: dynamicSymbolValues selector: #explore ;
		add: 'explore lexical environment' target: environment selector: #explore;
		add: 'explore interpreter' target: self selector: #explore;
		addLine;
		add: 'spawn gui' target: self selector: #openGui.

	upperLisp ifNotNil: 
		[aMenu add: 'go up' target: upperLisp selector: #openGui].

	^ aMenu
	

]

{ #category : #'private - declarations' }
CLisp >> checkDeclarations: bForm [

	bForm ifNil: [^ self].

	bForm do: [:sform |
		(sform isString or: [sform isConsCell and: [sform car == #declare]])
			ifFalse: [^ self].
		sform isString ifFalse: [sform cdr do: [:spec | self declaration: spec]]].		

]

{ #category : #'private - declarations' }
CLisp >> declaration: specForm [

	"only 'special' is supported"

	specForm car == #special ifFalse: [^ self].

	specForm cdr do: [:var |
		"if var does not have a dynamic value at this point, 
		then give it one from its lexical binding (if any)"
		((self hasDynamicValue: var) not 
			and: [(environment symbolValueBinding: var) notNil])  
		ifTrue:	
		[self dynamicSymbolValues add: var -> (self symbolValue: var ifNone: [])].
		"then register var as special for this form"
		specialVariables add: var]
]

{ #category : #'LISP-special forms' }
CLisp >> declare: ignored [

"(declare SPECS)
A declare form is known as a declaration. Declarations may occur only at the beginning of the bodies of certain special forms; that is, a declaration may occur only as a statement of such a special form, and all statements preceding it (if any) must also be declare forms (or possibly documentation strings, in some cases). Declarations may occur in lambda-expressions and in the forms listed here.

define-setf-method              labels 
defmacro                        let 
defsetf                         let* 
deftype                         locally 
defun                           macrolet 
do                              multiple-value-bind 
do*                             prog 
do-all-symbols                  prog* 
do-external-symbols             with-input-from-string 
do-symbols                      with-open-file 
dolist                          with-open-stream 
dotimes                         with-output-to-string 
flet
"

	^ self falseValue
]

{ #category : #initialization }
CLisp >> defineDefaultBindings [

	constantVariables := Array streamContents: [:str |
		str nextPutAll: constantVariables.

	self constantBindings associationsDo: [:assoc | 
		dynamicSymbolValues add: assoc.
		str nextPut: assoc key]].

	self defaultBindings associationsDo: [:assoc | 
		dynamicSymbolValues add: assoc]



]

{ #category : #'LISP-special forms' }
CLisp >> defvar: aConsCell [

"(defvar SYMBOL [INITVALUE])
Declare SYMBOL as a special variable, dynamically scoped.
Set value for SYMBOL to INITVALUE, only if SYMBOL has no value"

	| toplisp symbol |

	toplisp := self topmostLisp.
	symbol := self checkSymbol: aConsCell car.
	toplisp specialVariables add: symbol.

	aConsCell cdr ifNil: [^ symbol].

	(toplisp dynamicSymbolValues includesKey: symbol)
		ifFalse: 
		[	| binding |
			"if a setq was done at top-level before the defvar (which is supposed to be illegal but is actually accepted by most Common Lisp implementations), then we already have a binding in the topmost symbolValues. 
in this case we must move it into the top-level dynamicSymbolValues"
			(toplisp lispEnvironment bindsSymbol: symbol)
				ifTrue: [binding := toplisp lispEnvironment symbolValueBinding: symbol.
							toplisp lispEnvironment removeSymbolValue: symbol]
				ifFalse: [binding := symbol -> (self evalObject: aConsCell cadr)].
			toplisp dynamicSymbolValues add: binding
		].

	^ symbol
]

{ #category : #'private - special variables' }
CLisp >> dynamicSymbolValue: aSymbol ifNone: aBlock [

	^ dynamicSymbolValues at: aSymbol 
		ifAbsent: [(self upperLisp ifNil: [^ aBlock value])
						dynamicSymbolValue: aSymbol ifNone: aBlock]
	
	
]

{ #category : #'private - special variables' }
CLisp >> dynamicSymbolValues [

	^ dynamicSymbolValues
]

{ #category : #'private - special variables' }
CLisp >> dynamicSymbolValues: aDictionary [

	dynamicSymbolValues := aDictionary
]

{ #category : #'private - special variables' }
CLisp >> dynamicSymbolValuesDictionaryFor: aSymbol [

	(dynamicSymbolValues keys includes: aSymbol)
		ifFalse: [
			(self specialVariables includes: aSymbol)	
				ifTrue: [^ dynamicSymbolValues].
			upperLisp 
				ifNil: [^ nil]
				ifNotNil: [^ upperLisp dynamicSymbolValuesDictionaryFor: aSymbol]].

	^ dynamicSymbolValues
]

{ #category : #GUI }
CLisp >> guiColor [

	^ Color green darker darker blacker
]

{ #category : #'private - special variables' }
CLisp >> hasDynamicValue: aSymbol [

	"tells if a value is dynamically bound to aSymbol."

	 self dynamicSymbolValues at: aSymbol 
		ifAbsent: [^ (upperLisp ifNil: [^ false]) hasDynamicValue: aSymbol].
	
	^ true
						
	
]

{ #category : #'private - special variables' }
CLisp >> hasGlobalDynamicValue: aSymbol [

	"at top-level, having aSymbol in specialVariables means it is globally dynamic"

	^ self topmostLisp specialVariables includes: aSymbol

						
	
]

{ #category : #initialization }
CLisp >> initialize [

	dynamicSymbolValues := IdentityDictionary new.
	specialVariables := IdentitySet new.
	super initialize.

]

{ #category : #'LISP-special forms' }
CLisp >> locally: aConsCell [

	^ (self subLisp: #locally: form: aConsCell body: aConsCell environment: environment) progn: aConsCell

]

{ #category : #'LISP-functions-interpreter' }
CLisp >> makunbound: aConsCell [

"(makunbound SYMBOL)
Make SYMBOL's value be void."

	| s |
	s := self checkSymbol: aConsCell car.
	(self symbolValuesDictionaryFor: s) removeKey: s ifAbsent: [].
	(self symbolValuesDictionaryFor: s) removeKey: s ifAbsent: [].
	^ s

]

{ #category : #'private - special variables' }
CLisp >> specialVariables [

	^ specialVariables 
]

{ #category : #'private - special variables' }
CLisp >> specialVariables: anIdentitySet [

	specialVariables := anIdentitySet
	
]

{ #category : #'private - override' }
CLisp >> subLisp: aSymbol form: aForm body: aConsCell environment: anLKEnvironment [

	|sublisp |
	
	sublisp := super subLisp: aSymbol form: aForm body: aConsCell environment: anLKEnvironment.
	sublisp 
		dynamicSymbolValues: IdentityDictionary new;
		specialVariables: IdentitySet new;
		checkDeclarations: aConsCell.
	^ sublisp
	
]

{ #category : #'LISP-functions-interpreter' }
CLisp >> symbolValue: aConsCell [

"(symbol-value SYMBOL)
Return SYMBOL's value.  Raise an error if there is none.
SYMBOL must be a special variable"

	"Note: this is confusing since it is not the same semantics as #symbolValue:ifNone:
	the reason for this is that this is a public lisp function and we are giving it the semantics defined by Common Lisp
	OTOH #symbolValue:ifNone: is private and its name correctly reflects the actual implementation"

	^ self dynamicSymbolValue: aConsCell car
		ifNone: [self lispError: 'no dynamic value for symbol ', aConsCell car asString]

]

{ #category : #'private - override' }
CLisp >> symbolValue: aSymbol ifNone: aBlock [

	(specialVariables includes: aSymbol)
		ifTrue: [^ self dynamicSymbolValue: aSymbol
					ifNone: [self lispError: 'no dynamic value for symbol ', aSymbol]].

	 ^ super symbolValue: aSymbol ifNone: 
			[self dynamicSymbolValue: aSymbol ifNone: aBlock]

	
]

{ #category : #'private - override' }
CLisp >> symbolValuesAdd: anAssociation [

	((specialVariables includes: anAssociation key) 
		or: [self hasGlobalDynamicValue: anAssociation key])
	ifFalse: [^ super symbolValuesAdd: anAssociation].

	self dynamicSymbolValues add: anAssociation .
	self monitor ifNotNil: 
		[self monitor symbolsValuesAdded: anAssociation in: self]
]

{ #category : #'private - override' }
CLisp >> symbolValuesDictionaryFor: aSymbol [

	^ (self dynamicSymbolValuesDictionaryFor: aSymbol)
		ifNil: [super symbolValuesDictionaryFor: aSymbol] 
]
