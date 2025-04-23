Class {
	#name : #LKOSULispTest,
	#superclass : #ULispTest,
	#category : #'LispKit-LKOS-Tests'
}

{ #category : #'as yet unclassified' }
LKOSULispTest class >> shouldInheritSelectors [

	^ false
]

{ #category : #'as yet unclassified' }
LKOSULispTest >> setUp [

	lisp := LKOSULisp new loadDefaultLibraries.

]

{ #category : #'as yet unclassified' }
LKOSULispTest >> testCommonMusic [

	<timeout: 300> "overkill but, hey" 

	| cs |

	lisp top: #(load-library $'cm).

	cs := lisp top: #(#'find-object' 'chromatic-scale').
	self assert: cs isLKOSInstance.
	self assert: cs iSlots first = 'chromatic-scale'.
	self assert: (cs accessors collect: [:a | a first]) 
		= #(name octave lowest divisions into #'keynum-offset' steps table defoct #'octave-offset') asCons.
]

{ #category : #'as yet unclassified' }
LKOSULispTest >> testDefineGeneric [

	lisp evalString:
'(begin

 	(require ''format)

	(define-generic log)

	(define-method log ((s <string>) . l) 
		(apply format  (current-error-port) s l)
		(newline (current-error-port)))

	 (log "Hello, ~a" "world"))'.

	self assert: ((lisp top: #(log 5)) closeTo: 1.6094379124341)
]

{ #category : #'as yet unclassified' }
LKOSULispTest >> testDefineMethod [

	lisp evalString:
'(begin
	(define-generic M)
	(define-method M ((a <integer>) b) ''integer)
	(define-method M ((a <real>)    b) ''real)
	(define-method M (a b)             ''top))'.

	self assert: (lisp top: #(M 2 3)) = #integer.
	self assert: (lisp top: #(M 2 'yo')) = #integer.
	self assert: (lisp top: #(M 2.5 3)) = #real.
	self assert: (lisp top: #(M true false)) = #top.

	self should: [lisp top: #(M 2 3 4)] raise: Error.


	lisp evalString:
'(begin
	(define-method M ((a <integer>) (b <number>))  ''integer-number)
	(define-method M ((a <integer>) (b <real>)) ''integer-real)
	(define-method M ((a <integer>) (b <integer>))  ''integer-integer)
	(define-method M (a (b <number>))  ''top-number)
	(define-method M (a b c)    ''three-parameters))'.

	self assert: (lisp top: #(M 1 2)) = #'integer-integer'.
	self assert: (lisp top: #(M 1 1.0)) = #'integer-real'.
	self assert: (lisp top: #(M $'a 1.0)) = #'top-number'.
	self assert: (lisp top: #(M 1 2 3)) = #'three-parameters'.
]

{ #category : #'as yet unclassified' }
LKOSULispTest >> testNextMethod [

	lisp evalString:
'(begin

	(define-method Test((a <integer>))  
   		(cons ''integer (next-method)))

	(define-method Test((a <number>)) 
   		(cons ''number  (next-method)))

	(define-method Test(a)   
  		 (list ''top)) )'.

	self assert: (lisp top: #(Test 1)) = #(integer number top) asCons.
	self assert: (lisp top: #(Test 0.25)) = #(number top) asCons.
	self assert: (lisp top: #(Test 'bof')) = #(top) asCons.

]

{ #category : #'as yet unclassified' }
LKOSULispTest >> testVirtualAccessor [

	lisp evalString:
'(begin
	(define-class <point> ()
  		((x :init-form 0 :accessor x-of :init-keyword :x)
   		(y :init-form 0 :accessor y-of :init-keyword :y)))

	(define-class <circle> (<point>)
 		 ((radius :init-form 0 :accessor radius :init-keyword :radius)
  		 (area :allocation :virtual :accessor area
			 :slot-ref (lambda (o)
		    				 (let ((r (radius o)))
		      				 (* 3.14 r r)))
	 		:slot-set! (lambda (o v)
		     				 (set! (radius o) (sqrt (/ v 3.14)))))))

	 (define c (make <circle> :radius 1)) )'.

	self assert: ((lisp evalString: '(area c)') closeTo: 3.14).

	lisp evalString: '(area c 10)'.

	self assert: ((lisp evalString: '(area c)') closeTo: 10).

]
