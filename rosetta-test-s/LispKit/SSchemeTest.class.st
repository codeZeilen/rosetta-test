Class {
	#name : #SSchemeTest,
	#superclass : #ULispWithLibTest,
	#category : #'LispKit-Dialects-Tests'
}

{ #category : #'as yet unclassified' }
SSchemeTest class >> shouldInheritSelectors [

	^ false
]

{ #category : #'as yet unclassified' }
SSchemeTest >> setUp [

	lisp := SScheme new loadDefaultLibraries
]

{ #category : #'as yet unclassified' }
SSchemeTest >> testKanren [

	lisp top: #(load-library $'kanren).
	self assert: (lisp top: 
		#(load (system-path 'ulisp/kanren/ulisp/zebra-test.scm')))
]

{ #category : #'as yet unclassified' }
SSchemeTest >> testMiniKanren [

	lisp top: #(load-library $'mini-kanren).

	self assert: (lisp top: #(run 2 (x)
    (conde
      ((== $'extra x) succeed)
      ((== $'virgin x) fail)
      ((== $'olive x) succeed)
      ((== $'oil x) succeed)))) = #(extra olive) asCons.

	self assert: (lisp top: #(#'run*' (q)
    (exists (x)
      (== x q)
      (== true x)))) = #(true) asCons.

	self assert: (lisp top: #(#'run*' (q)
    (exists (x)
      (== (eq? x q) q)))) = #(false) asCons.

	self assert: (lisp top: #(#'run*' (r)
    (exists (x y)
      (conde
        ((== $'split x) (== $'pea y))
        ((== $'navy x) (== $'bean y)))
      (== (cons x (cons y $'())) r)))) = #((split pea) (navy bean)) asCons
]

{ #category : #'as yet unclassified' }
SSchemeTest >> testOleg [

	lisp top: #(load-library $'oleg).

	lisp standardInput: ''. "breaks the upcoming REPL"
	lisp top: #(lambda-calculator).

	lisp top: #(define env (make-env)).

	lisp top: #
    (define (exec-stmt stmt)
      (cond
        ((not (pair? stmt)) (term-eval env stmt))
        ((eq? $'X (car stmt))
          (assert (pair? (cdr stmt)))
          (cond
            ((assq (cadr stmt) X-Commands) =>
              (lambda (command)
                (apply (cdr command) (cons env (cddr stmt)))))
            (else
              (cerr 'invalid command: ' (cadr stmt) nl)
              $'())))
        (else (term-eval env stmt)))).

	lisp top: #(exec-stmt 
				`(X include ,(system-path 'ulisp/oleg/lambda-arithm-basic.scm'))).

	self assert: (lisp top: #(exec-stmt $'(X expand-shortcuts #'%c3')))
		= #(L f (L x (f (f (f x))))) asCons.
   

]

{ #category : #'from ULispWithLibTest' }
SSchemeTest >> testR4RS [

	super testR4RS
]

{ #category : #'from ULispWithLibTest' }
SSchemeTest >> testR5RSPitfalls [

	lisp top: #(load (system-path 'ulisp/tests/r5rs_pitfall.scm')).

	self assert: (lisp top: #'r5rs-pitfalls-errors') isZero

]

{ #category : #'from ULispWithLibTest' }
SSchemeTest >> testSchelog [

	super testSchelog
]
