"
see comments in LispKernel


"
Class {
	#name : #LispKitInfo,
	#superclass : #PackageInfo,
	#category : #LispKit
}

{ #category : #'as yet unclassified' }
LispKitInfo class >> initialize [

	Preferences 
		addPreference: #lispKitDebugOnError
		categories: #(lisp) 
		default: false 
		balloonHelp: 'when true, a GUI appears upon any lisp interpreter error'.

]

{ #category : #ulisp }
LispKitInfo >> SCMFiles [

	^ {}
]

{ #category : #'as yet unclassified' }
LispKitInfo >> additionalFiles [

	^ {'ulisp.zip' . 'ProportionalSplitterMorph fix.1.cs'}
]

{ #category : #ulisp }
LispKitInfo >> commonMusicFiles [

	^	(self filesInULispDirectory: 'cm'),
		(self filesInULispDirectory: 'cm\\src')
]

{ #category : #'as yet unclassified' }
LispKitInfo >> fileOutOnStream: aStream [

	"we use this place as a hook for building the /ulisp archive"

	super fileOutOnStream: aStream.
	self makeUlispArchive
]

{ #category : #ulisp }
LispKitInfo >> filesInULispDirectory: dir [

	^ ((FileDirectory default directoryNamed: 'ulisp') directoryNamed: dir) 
			fileNames 
			collect: [:fn | 'ulisp', FileDirectory slash, dir, FileDirectory slash, fn]
]

{ #category : #ulisp }
LispKitInfo >> gabrielFiles [

	^ self filesInULispDirectory: 'gabriel-scheme'
]

{ #category : #ulisp }
LispKitInfo >> jacalFiles [

	^ self filesInULispDirectory: 'jacal'
]

{ #category : #ulisp }
LispKitInfo >> kanrenFiles [

	^ (self filesInULispDirectory: 'minikanren'),
		(self filesInULispDirectory: 'kanren\benchmarks'),
		(self filesInULispDirectory: 'kanren\docs'),
		(self filesInULispDirectory: 'kanren\examples'),
		(self filesInULispDirectory: 'kanren\lib'),
		(self filesInULispDirectory: 'kanren\ulisp')
]

{ #category : #ulisp }
LispKitInfo >> lkosFiles [

	^ self filesInULispDirectory: 'lkos'
]

{ #category : #ulisp }
LispKitInfo >> makeUlispArchive [

	| zip |

	zip :=  ZipArchive new.

	( self slibFiles, 
		{'ulisp\loop.scm' . 'ulisp\mbe.lsp' . 'ulisp\scm\pi.scm'},
		self pregexpFiles, 
		self SCMFiles, 
		self schelogFiles, 
		self schelogExampleFiles,
		self testFiles,
		self olegFiles,
		self tinyclosFiles,
		self jacalFiles,
		self kanrenFiles,
		self meroonetFiles,
		self lkosFiles,
		self commonMusicFiles,
		self gabrielFiles
	) 
	do: [:f | zip addFile: f].

	zip writeToFileNamed: 'ulisp.zip'
]

{ #category : #ulisp }
LispKitInfo >> meroonetFiles [

	^ self filesInULispDirectory: 'meroonet'
]

{ #category : #ulisp }
LispKitInfo >> olegFiles [

	^ self filesInULispDirectory: 'oleg'
]

{ #category : #'as yet unclassified' }
LispKitInfo >> postscriptText [

	^
'
	(SystemVersion current majorMinorVersion >= ''Squeak4.1'')
		ifTrue: [
			self fileInMemberNamed: ''ProportionalSplitterMorph fix.1.cs''
		].

	(ZipArchive new readFrom: ''ulisp.zip'') extractAllTo: FileDirectory default.
	
	LispKernel updatePrimitives.
'


]

{ #category : #ulisp }
LispKitInfo >> pregexpFiles [

	^ self filesInULispDirectory: 'pregexp'

]

{ #category : #'as yet unclassified' }
LispKitInfo >> prerequisitePackages [
	"These are the names of packages that get loaded before the main change set"
	^#('People-spfa-utils-3.8' 'People-spfa-fixes-common' 'Continuation' 'REPLMorph' 'ConsCell') 
]

{ #category : #'as yet unclassified' }
LispKitInfo >> readmeText [
	"Text shown to the user after load"
	
	^ 'LispKit: a kit for building one''s own custom Lisp implementation 

LispKit provides:

1) an extensible minimal Lisp-2 interpreter (the kernel) with
	- dynamic scoping (like Emacs Lisp)
	- all fundamental special forms: let, setq, and, or, if, defun, defmacro ...
	- more than 100 basic functions: list, car, funcall, null ...
	- catch/throw, unwind-protect
	- a GUI:
			LispKernel openNew     "doIt"
			ELisp openNew 		"doIt ..this one is more usable"

2) a draft for a Common Lisp like dialect
			CLisp openNew 		"doIt"		
							
3) ULisp, a full-fledged Scheme implementation	
			ULisp openNew 		"doIt"
					
4) SScheme, a much slower ULisp with support for R5RS hygienic macros						
			SScheme openNew     "doIt"
	
5) an ULisp version featuring a CLOS-like object system (adapted from STKlos)
			LKOSULisp openNew  "doIt" 

6) turtles :)
	... see LKTurtlePlayGround class comment for details


LispKernel usage:

	subclasses of LispKernel can implement their own dialect of Lisp, by adding new functions and special forms and/or by overriding methods.
	see SLisp, CLisp  and ULisp for examples:
	- SLisp integrates Smalltalk into LispKernel
	- CLisp is a static Lisp-2 with special variables like Common Lisp
	- ULisp is a comprehensive Scheme implementation


implementation peculiarities

	LispKernel is a pure Smalltalk extension. There is no parser (only the "read" lisp function) nor compiler; the interpreter is the ''eval'' lisp function itself (see LispKernel>>#eval:)

	Lisp code can be written as plain Smalltalk arrays, such as

	#(defmacro addToList (x y) `(+ ,x ,@y))  "printIt" 

	the conversion into Lisp data is straightforward: see the very simple code in Array>>#asCons which converts the array into a tree of cons cells. example:

	#(defun add (x y) (+ x y)) asCons     "exploretIt"

	this approach has many advantages. for example:
	- we can chase the senders of a symbol: try [defun] (alt-n)
	- we can use the debugger to debug Lisp code
	- we can easily implement powerful control structure (see catch/throw) 
	- we can integrate Lisp and Smalltalk (see SLisp or ELisp class>>turtleGraphics)

... see LispKernel and its subclasses class comments for more documentation
		'
]

{ #category : #ulisp }
LispKitInfo >> schelogExampleFiles [

	^ (((FileDirectory default directoryNamed: 'ulisp') directoryNamed: 'schelog') 
			directoryNamed: 'examples') 
			fileNames 
			collect: [:fn | 'ulisp', FileDirectory slash, 'schelog', FileDirectory slash,  'examples', FileDirectory slash, fn]

]

{ #category : #ulisp }
LispKitInfo >> schelogFiles [

	^ self filesInULispDirectory: 'schelog'
]

{ #category : #ulisp }
LispKitInfo >> slibFiles [

	^ ((FileDirectory default directoryNamed: 'ulisp') directoryNamed: 'slib') 
			fileNames 
			select: [:n | n endsWith: '.scm'] 
			thenCollect: [:fn | 'ulisp', FileDirectory slash, 'slib', FileDirectory slash, fn]
]

{ #category : #ulisp }
LispKitInfo >> testFiles [

	^ self filesInULispDirectory: 'tests'
]

{ #category : #ulisp }
LispKitInfo >> tinyclosFiles [

	^ self filesInULispDirectory: 'tiny-clos'
]
