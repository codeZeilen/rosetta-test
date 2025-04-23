"
ULisp enhanced with pre-loaded SLIB libraries (see class-side #sscheme) 
and notably R5RS hygienic macros support

	SScheme openNew		""doIt""


Note that this is very, very slow !

On the other hand, NON HYGIENIC scheme macros are available in ULisp:
	(load-library 'pseudo-syntax-rules)
... these may at times replace a full-fledged macro system, and are 100 times faster...

"
Class {
	#name : #SScheme,
	#superclass : #ULisp,
	#instVars : [
		'macroEvalTemplate',
		'macroEvalSlot'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #libraries }
SScheme class >> about [

	self display: 
 
'This version of SScheme supports R4RS hygienic macros via SLIB''s ''macros-that-work. 


The following  libraries are available:


SLIB version 3b3, by Aubrey Jaffer
http://swiss.csail.mit.edu/~jaffer/SLIB.html 

...to see the currently loaded features, do
	(pretty-print (sort slib:features string<?)) 

...to load a new ''feature, do a corresponding
	(require ''feature)

...to see a list of all features, do
	(pretty-print (sort (mapcar car *catalog*) string<?))


Tiny-CLOS, a CLOS-like object system by Gregor Kiczales
http://community.schemewiki.org/?Tiny-CLOS
http://home.adelphi.edu/sbloch/class/archive/272/spring1997/tclos/tutorial.shtml

... load it via (load-library ''tiny-clos)


Schelog: Prolog-style logic programming in Scheme, by Dorai Sitaram
http://www.ccs.neu.edu/home/dorai/schelog/schelog.html

... load it via (load-library ''schelog)


Portable Regular Expressions for Scheme and Common Lisp, by Dorai Sitaram
http://www.ccs.neu.edu/~dorai/pregexp/pregexp.html

... load it via (load-library ''pregexp)


JACAL version 1c2, an interactive symbolic calculator by Aubrey Jaffer
http://www-swiss.ai.mit.edu/~jaffer/JACAL.html

... load it via (load-library ''jacal)


Kanren, a logic declarative system by Oleg and al.
http://kanren.sourceforge.net/

... load it via 
(load-library ''kanren)

miniKANREN is also here:
(load-library ''mini-kanren)

' underLabel: 'SScheme, the experimental Squeak Scheme'.

	^ nil
]

{ #category : #libraries }
SScheme class >> defaultLibraries [

	^ #(#'sscheme-intro')
]

{ #category : #libraries }
SScheme class >> help [

	self display:

'examples of useful functions:

introspection:

	(primitives)
	(special-forms)
	(bound-symbols)
	(fbound-symbols)

	(about ''display-source)

	(display-source ''display-source)


debugging:

	(explore (cons ''a ''b))

	(begin 
		(define counter #f)
		(let ((n 0))
			(set! counter (lambda () (set! n (+ 1 n)) (debug) n)))
		(let ((n 255))
			(list n (counter))))


' underLabel: 'SScheme help'.

	^ nil
]

{ #category : #private }
SScheme class >> initialize [

	super initialize
]

{ #category : #libraries }
SScheme class >> oleg [

	"highly experimental"

	^#(in-library oleg

	(load 'ulisp\\oleg\\myenv-ulisp.scm') "the Prelude"

	(define (test-oleg) 					"incredibly slow !"
		(load 'ulisp\\oleg\\assert.scm')
	 	(load 'ulisp\\oleg\\catch-error.scm')
		(load 'ulisp\\oleg\\srfi-13-local.scm')
	 	(load 'ulisp\\oleg\\util.scm')
	 	(load 'ulisp\\oleg\\env.scm')
		(load 'ulisp\\oleg\\vmyenv.scm'))

	(define (lambda-calculator)     
		(load 'ulisp\\oleg\\lambda-calc.scm'))
)


]

{ #category : #libraries }
SScheme class >> sscheme [

	^#(in-library sscheme

	(require `#'srfi-1') 
	(require `format)
	(require `array)
	(require `dynamic-wind)
"	(require `macro)" 					"fails..."
	(require `macros-that-work)
"	(require `syntactic-closures)"		"fails..."
"	(require `syntax-case)		"	"slow"
	(require `collect) 
	(require `hash-table)
 	(require `sort)
	(require `string-case)
	(require `coerce)
	(require `stdio)
	(require `pretty-print)

	(define (sscheme)
	'displays general information about this version of SScheme'
		(send SScheme about))

	(define (help)
	'displays some help for working with SScheme'
		(send SScheme help))

)


]

{ #category : #libraries }
SScheme class >> sschemeIntro [

	^#(in-library sscheme-intro

	(display 'welcome to SScheme, the experimental Squeak Scheme') (newline)
	(display '--------------------------------------------------')	
	(newline)
	(display 'type (sscheme) for details and legalese, (help) to get started')
	(newline)
	(display 'SLIB features: ')
	(display (sort #'slib:features' #'string<?'))
	(newline)
	(newline)
)


]

{ #category : #libraries }
SScheme class >> systemLibraries [

	^ super systemLibraries, super defaultLibraries, #(sscheme)

]

{ #category : #'private - interpreter' }
SScheme >> enterInterpreterContextAndEval: anObject [

	macroEvalTemplate ifNil:
		[^ super enterInterpreterContextAndEval: anObject].

	^ self evalSemaphore critical: [self macroEvalObject: anObject].
					

]

{ #category : #'private - interpreter' }
SScheme >> eval: anObject inEnvironment: aLKEnvironment [

	macroEvalTemplate ifNil:
		[^ super eval: anObject inEnvironment: aLKEnvironment].

	^ (self copy
		lispEnvironment: aLKEnvironment;
		upperLisp: self;
		upperTail: nil;
		upperHead: nil) macroEvalObject: anObject
]

{ #category : #GUI }
SScheme >> guiColor [

	^ (Color r: 0.6 g: 0.3 b: 0.6) lighter
]

{ #category : #'private - initialization' }
SScheme >> initializeMacroExpander [

	macroEvalTemplate := #macro:expand inCons addLast: #anObject inQuotedCons.
	macroEvalSlot := macroEvalTemplate cadr cdr

]

{ #category : #'private - initialization' }
SScheme >> loadDefaultLibraries [

	self loadLibraries: self class systemLibraries 
		label: self class asString, ': loading system libraries'.

	self initializeEnvironments.

	self loadLibraries: self class defaultLibraries 
		label: self class asString, ': loading default libraries'.

	self initializeMacroExpander.

]

{ #category : #'private - interpreter' }
SScheme >> macroEvalObject: anObject [

	anObject isConsCell ifFalse: 
		[^ self evalObject: anObject multipleValue: true].
	
	macroEvalSlot setcar: anObject.

	^ self evalObject: (self evalObject: macroEvalTemplate multipleValue: true) 
		multipleValue: true
	
					

]
