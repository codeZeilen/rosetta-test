"
This is a minimal Scheme implementation based on Peter Norvig's lispy.py
"
Class {
	#name : #RosettaScheme,
	#superclass : #Object,
	#instVars : [
		'topEnvironment',
		'macroTable',
		'logging'
	],
	#category : #'RosettaS-Interpreter'
}

{ #category : #'LISP-functions-rosetta' }
RosettaScheme >> = aConsCell [

	^ aConsCell first = aConsCell second
]

{ #category : #'macro expansion' }
RosettaScheme >> applyMacroOn: exprs topLevel: isTopLevel [

	| macroResult |
	macroResult := (macroTable at: exprs first) value: exprs allButFirst.
	^ self expand: macroResult topLevel: isTopLevel
]

{ #category : #'private-evaluating' }
RosettaScheme >> asTruthy: anObject [

	anObject = false ifTrue: [^ false].
	^ true
]

{ #category : #'LISP-special forms' }
RosettaScheme >> begin: aConsCell [

"(begin BODY)
Eval BODY sequentially; return the value from last evaluation"

	| val cell |
	cell := aConsCell.
	[val := self evalObject: cell car.
	cell := cell cdr.]
		doWhileTrue: [cell notNil].
	^ val
]

{ #category : #'private-debugging' }
RosettaScheme >> enableLogging [

	logging := true.
]

{ #category : #evaluating }
RosettaScheme >> evalExprs: element in: env [

	| x localEnv |
	x := element.	
	localEnv := env.
	
	[
	logging ifTrue: [Transcript showln: 'evaluating: ' , x printAsTree].
 	true 
		caseOf: {
			[x isSymbol] -> [ "symbol lookup"
				^ localEnv at: x].
			[(self isList: x) not] -> [  "literal"
				^ x].
			[#quote = x first] -> [ 
				^ x second].
			[#if = x first] -> [
				x := (self evalExprs: x second in: localEnv) isRosettaTrue "Scheme treats all values as #t except for #f and '()"
					ifTrue: [x third]
					ifFalse: [x fourth]].
			[#cond = x first] -> [  
				x allButFirst 
					detect: [:case | | test |
						test := case first.
						test = #else or: [self evalExprs: test in: localEnv]]
					ifFound: [:case |
						x := case second]
					ifNone: [^ nil]].
			[#'set!' = x first] -> [ 
				(localEnv findEnvFor: x second) 
					at: x second
					put: (self evalExprs: x third in: localEnv).
				^ nil].
			[#define = x first] -> [ 
				localEnv at: x second put: (self evalExprs: x third in: localEnv).
				^ nil].
			[#begin = x first] -> [ 
				x allButFirst allButLast do: [:beginElement |
					self evalExprs: beginElement in: localEnv].
				x := x last].
			[#lambda = x first] -> [ 
				^ RosettaSchemeLambda new
					params: x second;
					body: x third;
					env: localEnv;
					interpreter: self;
					yourself]}
		otherwise: [ | evaluatedElements executableElement |
			"no special form"
			evaluatedElements := x collect: [:exp | self evalExprs: exp in: localEnv].
			executableElement := evaluatedElements first.
			true caseOf: {
					[executableElement isRosettaSchemeProcedure] -> [
						x := executableElement body.
						localEnv := RosettaSchemeEnv new
							setBindingsFor: executableElement params to: evaluatedElements allButFirst;
							parent: executableElement env;
							yourself].
					[executableElement isRosettaSchemePrimitive] -> [
						^ executableElement value: evaluatedElements allButFirst]}
				otherwise: [
					self error: 'Invalid expression: ' , x printString]].
	] repeat.
]

{ #category : #evaluating }
RosettaScheme >> evalString: aString [

	^ self evalString: aString in: self topEnvironment
]

{ #category : #evaluating }
RosettaScheme >> evalString: aString in: anEnvironment [

	| exprs |
	exprs := self parseAndExpand: aString.
	^ self evalExprs: exprs in: anEnvironment
]

{ #category : #'macro expansion' }
RosettaScheme >> expand: exprs [

	^ self expand: exprs topLevel: false
]

{ #category : #'macro expansion' }
RosettaScheme >> expand: exprs topLevel: isTopLevel [

	self expr: exprs shouldFulfill: (exprs isCollection not or: [exprs isString or: [exprs size > 0]]). "Either a non-empty list, or something else"
	true 
		caseOf: {
			[(self isList: exprs) not] -> ["literal"
				^ exprs].
			[#include = exprs first] -> [
				self expr: exprs shouldFulfill: exprs size > 1.
				^ self expandInclude: exprs].
			[#quote = exprs first] -> [
				self expr: exprs shouldFulfill: exprs size = 2.
				^ exprs].
			[#if = exprs first] -> [
				^ self expandIf: exprs].
			[#'set!' = exprs first] -> [
				^ self expandSet: exprs].
			[#define = exprs first or: [#'define-macro' = exprs first]] -> [
				^ self expandDefineAndMacro: exprs topLevel: isTopLevel].
			[#begin = exprs first] -> [
				^ exprs size = 1 
					ifTrue: [nil]		
					ifFalse: [exprs collect: [:expr | self expand: expr topLevel: isTopLevel]]].
			[#lambda = exprs first] -> [
				^ self expandLambda: exprs].
			[#quasiquote = exprs first] -> [
				^ self expandQuasiquoteContent: exprs second].
			[exprs first isSymbol and: [macroTable includesKey: exprs first]] -> [
				^ self applyMacroOn: exprs topLevel: isTopLevel]}
		otherwise: ["recurse"
			^ exprs collect: [:expr | self expand: expr]]


	
]

{ #category : #'macro expansion' }
RosettaScheme >> expandDefineAndMacro: exprs topLevel: isTopLevel [
	"Covers define and define-macro"

	| body define variable |
	self expr: exprs shouldFulfill: exprs size >= 3.
	define := exprs first.
	variable := exprs second.
	body := exprs allButFirst: 2.
	
	((self isList: variable) and: [variable notEmpty]) 
		ifTrue: [ | functionName parameters | "define a function"
			functionName := variable first.
			parameters := variable allButFirst.
			^ self expand: {define . functionName . {#lambda . parameters}, body}]
		ifFalse: ["define a value"
			self expr: exprs shouldFulfill: exprs size = 3.
			self expr: exprs shouldFulfill: variable isSymbol message: 'define should receive a symbol as the variable name'.
			body := self expand: exprs third.
			#'define-macro' = define ifTrue: [ | macroProcedure |
				self expr: exprs shouldFulfill: isTopLevel message: 'macros can only be defined at top-level'.
				macroProcedure  := self evalExprs: body in: topEnvironment.
				self expr: exprs shouldFulfill: macroProcedure isRosettaSchemeProcedure message: 'macros needs to be a procedure'.
				macroTable at: variable put: macroProcedure. 
				^ nil].
			^ {define . variable . body}]
	
	
]

{ #category : #'macro expansion' }
RosettaScheme >> expandIf: exprs [

	| resultExprs |
	resultExprs := exprs.
	"Expand short form: (if t c) -> (if t c nil)"
	exprs size = 3 ifTrue: [
		resultExprs := resultExprs , {nil}].
	self expr: resultExprs shouldFulfill: resultExprs size = 4.
	^ resultExprs collect: [:expr | self expand: expr]
]

{ #category : #'macro expansion' }
RosettaScheme >> expandInclude: exprs [

	| result |
	result := #(begin) asOrderedCollection.
	exprs copyWithoutFirst do: [:fileName |
		FileStream 
			fileNamed: ThisOSProcess thisOSProcess getCwd,  FileDirectory slash , fileName 
			do: [:fs |
				result add: (self parseAndExpand: fs contents)]].
	^ result
	
]

{ #category : #'macro expansion' }
RosettaScheme >> expandLambda: exprs [

	| parameters body finalBody |
	self expr: exprs shouldFulfill: exprs size >= 3.
	parameters := exprs second.
	body := exprs allButFirst: 2.
	self 
		expr: exprs 
		shouldFulfill: (parameters isSymbol or: [parameters isCollection and: [parameters allSatisfy: [:p | p isSymbol]]])
		message: 'lambda parameters need to be symbols'.
	finalBody := body size = 1 
		ifTrue: [body first]
		ifFalse: [#(begin) , body].
	^ {#lambda . parameters . self expand: finalBody}
]

{ #category : #'macro expansion' }
RosettaScheme >> expandQuasiquoteContent: exprs [

	(self isPair: exprs) not ifTrue: [
		"optimize/simplify quasiquote of literal"
		^ {#quote . exprs}].
	
	self 
		expr: #(quasiquote) , exprs
		shouldFulfill: exprs first ~= #'unquote-splicing'
		message: 'Can not splice in first position'.
		
	#unquote = exprs first ifTrue: [
		"optimize direct unquote after quasiquote"
		self expr: #(quasiquote) , exprs shouldFulfill: exprs size = 2.
		^ exprs second].
	
	((self isPair: exprs first) and: [exprs first first = #'unquote-splicing']) 
		ifTrue: [ | unquotesplicing |
			self expr: exprs shouldFulfill: exprs first size = 2.
			unquotesplicing := exprs first.
			^ #(append) , {unquotesplicing second . "recurse" self expandQuasiquoteContent: exprs allButFirst}]
		ifFalse: [
			"Nothing to do here, recurse on both elements"
			^ #(cons) , {self expandQuasiquoteContent: exprs first . self expandQuasiquoteContent: exprs allButFirst}].
	
	
	

]

{ #category : #'macro expansion' }
RosettaScheme >> expandSet: exprs [

	self expr: exprs shouldFulfill: exprs size = 3.
	self expr: exprs shouldFulfill: exprs second isSymbol message: 'set! should receive a symbol as the variable name'.
	^ {exprs first . exprs second . self expand: exprs third}
]

{ #category : #'macro expansion' }
RosettaScheme >> expr: exprs shouldFulfill: aBoolean [

	self 
		expr: exprs
		shouldFulfill: aBoolean
		message: ''
]

{ #category : #'macro expansion' }
RosettaScheme >> expr: exprs shouldFulfill: aBoolean message: aMessage [

	aBoolean ifFalse: [
		RosettaSyntaxError signal: aMessage , ' in ', exprs printString].
]

{ #category : #'initialize-release' }
RosettaScheme >> initialMacroTable [

	^ IdentityDictionary newFrom: {
		#let -> [:args | self macroLet: args]}.
]

{ #category : #'initialize-release' }
RosettaScheme >> initialize [

	super initialize.
	macroTable := self initialMacroTable.
	logging := false.
]

{ #category : #'private-testing' }
RosettaScheme >> isList: anObject [

	^ anObject isCollection and: [anObject isString not]
]

{ #category : #'private-testing' }
RosettaScheme >> isPair: anObject [

	^ anObject isCollection and: [anObject isString not] and: [anObject notEmpty]
]

{ #category : #'LISP-functions-rosetta' }
RosettaScheme >> listSetD: aConsCell [

	| list |
	list := aConsCell first cells.
	(list at: aConsCell second) car: aConsCell third.
	
]

{ #category : #macros }
RosettaScheme >> macroLet: args [

	"args = list(args)
	    x = cons(_let, args)
	    require(x, len(args)>1)
	    bindings, body = args[0], args[1:]
	    require(x, all(isa(b, list) and len(b)==2 and isa(b[0], Symbol)
	                   for b in bindings), 'illegal binding list')
	    vars, vals = zip(*bindings)
	    return [[_lambda, list(vars)]+list(map(expand, body))] + list(map(expand, vals))"
	
	| bindings body vals vars |
	self expr: #(let), args shouldFulfill: args size > 1.
	bindings := args first.
	body := self expand: args allButFirst.
	
	self 
		expr: #(let), args
		shouldFulfill: (bindings allSatisfy: [:binding | binding size = 2 and: [binding first isSymbol]])
		message: 'illegal binding list'.
	vars := bindings collect: #first.
	vals := bindings collect: #second.
	vals := self expand: vals.
	
	^ {({#lambda . vars} , body)} , vals
]

{ #category : #'LISP-functions-rosetta' }
RosettaScheme >> nullP: args [

	^ args first isNil or: [args isCollection and: [args isEmpty]]
]

{ #category : #evaluating }
RosettaScheme >> parseAndExpand: aString [

	| exprs |
	exprs := ((ULispReader for: ULisp new) readString: aString) arrayForm.
	^ self expand: exprs topLevel: true.
]

{ #category : #evaluating }
RosettaScheme >> rosettaLibrarySource [

	^ ((FileDirectory on: ThisOSProcess thisOSProcess getCwd) / #rosetta) 
		readOnlyFileNamed: 'rosetta.scm' 
		do: [:rosettaFile | rosettaFile contents]
]

{ #category : #evaluating }
RosettaScheme >> standardLibrarySource [

	^ ((FileDirectory on: ThisOSProcess thisOSProcess getCwd) / #'rosetta-test') 
		readOnlyFileNamed: 'stdlib.scm' 
		do: [:rosettaFile | rosettaFile contents]
]

{ #category : #evaluating }
RosettaScheme >> topEnvironment [

	^ topEnvironment ifNil: [
		topEnvironment := RosettaSchemeEnv new
			bindings: {
				#+ -> [:args | args first + args second].
				#- -> [:args | args first - args second].
				#'string-append' -> [:args | (args collect: #asString) fold: #,].
				#append -> [:args | args fold: #,].
				#* -> [:args | args first * args second].
				#/ -> [:args | args first / args second].
				#modulo -> [:args | args first \\ args second].
				#= -> [:args | args first = args second].
				#'eq?' -> [:args | args first == args second].
				#'eqv?' -> [:args | args first == args second].				
				#'equal?' -> [:args | 
					args first isString
						ifTrue: [args first class = args second class 
									and: [args first = args second]]
						ifFalse: [args first = args second]].
				#> -> [:args | args first > args second].
				#< -> [:args | args first < args second].
				#<= -> [:args | args first <= args second].
				#sqrt -> [:args | args first sqrt].
				#inexact -> [:args | args first asFloat].
				#length -> [:args | args first size].
				#car -> [:args | args first first].
				#cdr -> [:args | args first size > 1 ifTrue: [args first allButFirst] ifFalse: [Array empty]].
				#list -> [:args | args].
				#'null?' -> [:args | args first isNil or: [args first isCollection and: [args first isEmpty]]].
				#cons -> [:args | {args first} , args second "TODO: this is not right"].
				#not -> [:args | (self asTruthy: args first) not].
				#apply -> [:args | args first value: args second].
				#'list-ref' -> [:args | args first at: args second + 1].
				#'list-set!' -> [:args | args first at: args second + 1 put: args third].
				#'make-hash-table' -> [:args | Dictionary new].
				#'hash-table?' -> [:args | args first isDictionary].
				#'hash-table-set!' -> [:args | args first at: args second put: args third. nil].
				#'hash-table-ref-prim' -> [:args | args first at: args second].
				#'hash-table-delete!' -> [:args | args first removeKey: args second ifAbsent: []. nil].
				#'hash-table-keys' -> [:args | args first keys].
				#'hash-table-values' -> [:args | args first values].
				#raise -> [:args | args first canSearchForSignalerContext ifFalse: [args first signal] ifTrue: [args first pass]].
				#error -> [:args | Error new messageText: args first; yourself].
				#'list?' -> [:args | args first isCollection and: [args first isString not]].
				#'string-upcase' -> [:args | args first asUppercase].
				#'string-trim' -> [:args | args first withBlanksTrimmed].
				#'string-split' -> [:args | args first findTokens: args second].
				#'string-replace' -> [:args | args third copyReplaceAll: args first with: args second].
				#'string-downcase' -> [:args | args first asLowercase].
				#'with-exception-handler' -> [:args | [args second value: {}] on: Exception do: [:e | args first value: {e}]].
				#display -> [:args | Transcript showln: args first]};
			yourself.
 
		"Loading basic definitions"
		self evalString: self standardLibrarySource in: topEnvironment.
 
		"Override some basic definitions for performance reasons" 
		topEnvironment
			at: #map put: [:args | args second collect: [:e | args first value: {e}]];
			at: #'for-each' put: [:args | args second do: [:e | args first value: {e}]];
			at: #filter put: [:args | args second select: [:e | args first value: {e}]];
			at: #'empty?' put: [:args | args first isEmpty].
		topEnvironment]
]
