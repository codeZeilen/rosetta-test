"
ULisp augmented with the LispKit Object System (LKOS), a port of STklos.

Initially developed for enabling Common Music, which is installed as a library: 
	LKOSULisp openNew 	 ""doIt""
	(load-library 'cm)           ""evaluate at prompt""


For now LKOSULisp has to be a specific dialect because LKOS requires keywords, that is autoevaluating symbols (which names begin with a $:)

Later on I plan to enable keywords in ULisp itself, so that this class will be removed from LispKit.
"
Class {
	#name : #LKOSULisp,
	#superclass : #ULisp,
	#category : #'LispKit-LKOS'
}

{ #category : #libraries }
LKOSULisp class >> cm [

"
	Common Music 2.10
	 http://www.sourceforge.net/projects/commonmusic
"

	^#(in-library cm

"temporary hack"
(define (set-file-position port pos set?)
(let ((stream (send port stream)))
  (if (not (zero? pos))
    (if set?
		(send stream position: pos)
  	 (send stream position: (+ (send stream position) pos)) ))
   (send stream position)))

"temporary hack"
(define (shell . rest))


			(load (system-path  'ulisp/cm/ulisp-cm'))

"faster functions"
(defmacro new (class #'&rest' args)
	(let* ((type (symbol-value (#'string->symbol' (string-append '<' class '>'))))
			 (inits (expand-inits type args true false))) 
	`(make ,type ,@inits))) 
)

]

{ #category : #libraries }
LKOSULisp class >> defaultLibraries [

	^ super defaultLibraries, {#lkos}
]

{ #category : #private }
LKOSULisp class >> initialize [

	super initialize
]

{ #category : #functions }
LKOSULisp class >> keyGet: aProperty plist: aConsCell tail: bConsCell [

	| plist prop |

	plist := aConsCell.
	prop := aProperty.
	
	[plist isNil] whileFalse:
	[
		plist car = prop ifTrue: [^ plist cadr].
		plist := plist cddr.
	].

	bConsCell isConsCell ifFalse: [self lispError: 'property not found'].
	^ bConsCell car
]

{ #category : #libraries }
LKOSULisp class >> lkos [

"
	The LispKit Object System,
	closely modelled from STKlos (version 0.82) by Erick Gallesio
	http://stklos.net
	... which is itself a variation of Tiny CLOS by Gregor Kickzales 

	This is an efficient and powerful object system based on CLOS providing
	- Multiple Inheritance,
	- Generic Functions,
	- Multi-methods
	- an efficient MOP (Meta Object Protocol)

	see class LKOSInstance
"

	^#(in-library lkos

			(load  (system-path 'ulisp/lkos/lkos'))

			"required for virtual accessors to work both ways:"
			(eval (read '(begin
				(define-generic setter)
				(define-method setter ((gf <generic>)) gf))')))
]

{ #category : #functions }
LKOSULisp class >> symbolKeyGet: aProperty plist: aConsCell default: aValue [

	| plist |

	plist := aConsCell.
	
	[plist isNil] whileFalse:
	[
		plist car == aProperty ifTrue: [^ plist cadr].
		plist := plist cddr.
	].

	^ aValue
]

{ #category : #'LISP-functions' }
LKOSULisp >> keyGet: aConsCell [

	^ self class keyGet: aConsCell cadr
		plist: aConsCell car
		tail: aConsCell cddr
]

{ #category : #'LISP-functions' }
LKOSULisp >> nextMethod: ignored [

"
(next-method)
"
	| nextMethod args |

	nextMethod := self symbolValue: #'lkos-next-method' 
						ifNone: [self lispError: 'no next-method !'].

	args := self symbolValue: #'lkos-next-method-arguments' 
						ifNone: [self lispError: 'no next-method arguments !'].

	^ nextMethod applyTo: args inLisp: self asMacro: true
			
			
]

{ #category : #'private - subclasses may implement' }
LKOSULisp >> symbolValue: aSymbol ifNone: aBlock [

	":keywords evaluate to themselves"
	aSymbol first == $: ifTrue: [^ aSymbol].

	 ^ environment symbolValue: aSymbol ifNone: aBlock

	
]
