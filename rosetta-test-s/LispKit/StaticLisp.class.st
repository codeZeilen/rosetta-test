"
a Lisp-2 dialect with lexical scoping and closures


"
Class {
	#name : #StaticLisp,
	#superclass : #ELisp,
	#category : #'LispKit-Dialects'
}

{ #category : #private }
StaticLisp class >> defaultLibraries [

	^ #(glue #'provide-library' plist compilers #'small-macros' common "#'arguments-lists' loop")
]

{ #category : #private }
StaticLisp class >> initialize [

	super initialize
]

{ #category : #'LISP-special forms' }
StaticLisp >> defmacro: aConsCell [

"(defmacro NAME ARGLIST &rest BODY...)
Set the function definition of NAME as (macro lambda ARGLIST &rest BODY).
When the macro is called, as in (NAME &rest ARGS), the function (lambda ARGLIST &rest BODY) is applied to the list ARGS as it appears in the expression, and the result should be a form to be evaluated instead of the original.
If the first form in BODY is a string, it is considered as the macro documentation"

	| macro |

	macro := self makeClosureFor: aConsCell cdr as: #macro.

	self topmostLisp lispEnvironment addSymbolFunction: 
		aConsCell car -> macro.

	^ macro
]

{ #category : #'LISP-special forms' }
StaticLisp >> defun: aConsCell [

"(defun NAME ARGLIST &rest BODY)
Set the function definition of NAME as (lambda ARGLIST &rest BODY).
If the first form in BODY is a string, it is considered as the function documentation"

	| lambda |

	lambda := self makeClosureFor: aConsCell cdr as: #lambda.

	self topmostLisp lispEnvironment addSymbolFunction: 
		aConsCell car -> lambda.

	^ aConsCell car
]

{ #category : #GUI }
StaticLisp >> guiColor [

	^ Color green darker darker blacker
]

{ #category : #'LISP-functions' }
StaticLisp >> inspectProcedure: aConsCell [

"(inspect-procedure PROCEDURE [NO-GUI])
Open an interpreter GUI those environment is a child of PROCEDURE closure
(except if the optional argument NO-GUI is #f)
Returns PROCEDURE lambda form"

	aConsCell car isLispClosure ifFalse: [self lispError: 'expecting a closure'].

	(aConsCell cadr == self falseValue)
		ifFalse: [aConsCell car lispEnvironment inspectWith: self class].

	^ aConsCell car lambdaForm
]

{ #category : #'private - closures' }
StaticLisp >> isLexical [

	^ true
]

{ #category : #'LISP-special forms' }
StaticLisp >> lambda: aConsCell [

"(lambda ARGS &rest BODY)
Return a lambda expression.
A call of the form (lambda ARGS &rest BODY) is self-quoting: the result of evaluating the lambda expression is the expression itself.  
A lambda expression has the semantic of a function"

	^ self makeClosureFor: aConsCell as: #lambda

]

{ #category : #'LISP-special forms' }
StaticLisp >> macro: aConsCell [

"(macro ARGS &rest BODY)
Return a nlambda expression.
A call of the form (macro ARGS &rest BODY) is self-quoting: the result of evaluating the nlambda expression is the expression itself.  
A nlambda expression has the semantic of a special form, or macro"

	^ self makeClosureFor: aConsCell as: #macro


]

{ #category : #'private - closures' }
StaticLisp >> makeClosureFor: aConsCell [ 

	| clo |

	clo := LKClosure new.
	clo form: aConsCell.
	clo lispEnvironment: environment.

	^ clo

]

{ #category : #'private - closures' }
StaticLisp >> makeClosureFor: aConsCell as: aSymbol [

	^ self makeClosureFor: 
		(self lambdaForm: aSymbol withArgsAndBody: aConsCell)

]
