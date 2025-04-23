"
a dynamic Lisp-2 similar to Emacs Lisp

it is basically LispKernel enriched with primitives and libraries so that it is actually usable 
"
Class {
	#name : #ELisp,
	#superclass : #LispKernel,
	#instVars : [
		'uninternedSymbols'
	],
	#category : #'LispKit-Dialects'
}

{ #category : #libraries }
ELisp class >> argumentsLists [

"
code largely borrowed from GNU Emacs 21.1 cl.el and cl-macs.el files
author: Dave Gillepsie
copyright: Free Software Foundation
licence: GPL
"

	^ 
	#(in-library arguments-lists

(require-library `common)

(when (featurep `arguments-lists)
	"clear all else infinite loops await"
	(dolist (v #'*library:arguments-lists*')
		(makunbound v)
		(fmakunbound v)))

(defun cl-const-expr-p (x)
  (cond ((consp x)
	 (or (eq (car x) `quote)
	     (and (memq (car x) `(function function*))
		  (or (symbolp (nth 1 x))
		      (and (eq (car-safe (nth 1 x)) `lambda) `func)))))
	((symbolp x) (and (memq x `(nil t)) t))
	(t t)))

(defun cl-const-expr-val (x)
  (and (eq (cl-const-expr-p x) t) (if (consp x) (nth 1 x) x)))

(defun ldiff (list sublist)
  'Return a copy of LIST with the tail SUBLIST removed.'
  (let ((res nil))
    (while (and (consp list) (not (eq list sublist)))
      (push (pop list) res))
    (nreverse res)))

(defconstant lambda-list-keywords
  `(#'&optional' #'&rest' #'&key' #'&allow-other-keys' #'&aux' #'&whole' #'&body' #'&environment'))

(defvar cl-macro-environment nil)
(defvar bind-block) (defvar bind-defs) (defvar bind-enquote)
(defvar bind-inits) (defvar bind-lets) (defvar bind-forms)

(defun cl-transform-lambda (form bind-block)
  (let* ((args (car form)) (body (cdr form))
	 (bind-defs nil) (bind-enquote nil)
	 (bind-inits nil) (bind-lets nil) (bind-forms nil)
	 (header nil) (simple-args nil))
    (while (or (stringp (car body)) (eq (car-safe (car body)) `interactive))
      (push (pop body) header))
    (setq args (if (listp args) (copy-list args) (list `#'&rest' args)))
    (let ((p (last args))) (if (cdr p) (setcdr p (list `#'&rest' (cdr p)))))
    (if (setq bind-defs (cadr (memq `#'&cl-defs' args)))
	(setq args (delq `#'&cl-defs' (delq bind-defs args))
	      bind-defs (cadr bind-defs)))
    (if (setq bind-enquote (memq `#'&cl-quote' args))
	(setq args (delq `#'&cl-quote' args)))
    (if (memq `#'&whole' args) (error '&whole not currently implemented'))
    (let* ((p (memq `#'&environment' args)) (v (cadr p)))
      (if p (setq args (nconc (delq (car p) (delq v args))
			      (list `#'&aux' (list v `cl-macro-environment))))))
    (while (and args (symbolp (car args))
		(not (memq (car args) `(nil #'&rest' #'&body' #'&key' #'&aux')))
		(not (and (eq (car args) `#'&optional')
			  (or bind-defs (consp (cadr args))))))
      (push (pop args) simple-args))
    (or (eq bind-block `cl-none)
	(setq body (list (list* `block bind-block body))))
    (if (null args)
	(list* nil (nreverse simple-args) (nconc (nreverse header) body))
      (if (memq `#'&optional' simple-args) (push `#'&optional' args))
      (arglist-do args nil (- (length simple-args)
				 (if (memq `#'&optional' simple-args) 1 0)))
      (setq bind-lets (nreverse bind-lets))
      (list* (and bind-inits (list* `eval-when `(compile load eval)
				    (nreverse bind-inits)))
	     (nconc (nreverse simple-args)
		    (list `#'&rest' (car (pop bind-lets))))
	     (nconc (nreverse header)
		    (list (nconc (list `let* bind-lets)
				 (nreverse bind-forms) body)))))))

(defun arglist-do (args expr &optional num)
  (if (nlistp args)
      (if (or (memq args lambda-list-keywords) (not (symbolp args)))
	  (error (concat 'Invalid argument name: ' args))
	(push (list args expr) bind-lets))
    (setq args (copy-list args))
    (let ((p (last args))) (if (cdr p) (setcdr p (list `#'&rest' (cdr p)))))
    (let ((p (memq `#'&body' args))) (if p (setcar p `#'&rest')))
    (if (memq `#'&environment' args) (error '&environment used incorrectly'))
    (let ((save-args args)
	  (restarg (memq `#'&rest' args))
	  (safety 3) "(if (cl-compiling-file) cl-optimize-safety 3))"
	  (keys nil)
	  (laterarg nil) (exactarg nil) minarg)
      (or num (setq num 0))
      (if (listp (cadr restarg))
	  (setq restarg (gensym 'rest-'))
	(setq restarg (cadr restarg)))
      (push (list restarg expr) bind-lets)
      (if (eq (car args) `#'&whole')
	  (push (list (pop2 args) restarg) bind-lets))
      (let ((p args))
	(setq minarg restarg)
	(while (and p (not (memq (car p) lambda-list-keywords)))
	  (or (eq p args) (setq minarg (list `cdr minarg)))
	  (setq p (cdr p)))
	(if (memq (car p) `(nil #'&aux'))
	    (setq minarg (list `= (list `length restarg)
			       (length (ldiff args p)))
		  exactarg (not (eq args p)))))
      (while (and args (not (memq (car args) lambda-list-keywords)))
	(let ((poparg (list (if (or (cdr args) (not exactarg)) `pop `car)
			    restarg)))
	  (arglist-do
	   (pop args)
	   (if (or laterarg (= safety 0)) poparg
	     (list `if minarg poparg
		   (list `signal `(quote wrong-number-of-arguments)
			 (list `list (and (not (eq bind-block `cl-none))
					  (list `quote bind-block))
			       (list `length restarg)))))))
	(setq num (#'1+' num) laterarg t))
      (while (and (eq (car args) `#'&optional') (pop args))
	(while (and args (not (memq (car args) lambda-list-keywords)))
	  (let ((arg (pop args)))
	    (or (consp arg) (setq arg (list arg)))
	    (if (cddr arg) (arglist-do (nth 2 arg) (list `and restarg t)))
	    (let ((def (if (cdr arg) (nth 1 arg)
			 (or (car bind-defs)
			     (nth 1 (assq (car arg) bind-defs)))))
		  (poparg (list `pop restarg)))
	      (and def bind-enquote (setq def (list `quote def)))
	      (arglist-do (car arg)
			     (if def (list `if restarg poparg def) poparg))
	      (setq num (1+ num))))))
      (if (eq (car args) `#'&rest')
	  (let ((arg (pop2 args)))
	    (if (consp arg) (arglist-do arg restarg)))
	(or (eq (car args) `#'&key') (= safety 0) exactarg
	    (push (list `if restarg
			   (list `signal `(quote wrong-number-of-arguments)
				 (list `list
				       (and (not (eq bind-block `cl-none))
					    (list `quote bind-block))
				       (list `+ num (list `length restarg)))))
		     bind-forms)))
      (while (and (eq (car args) `#'&key') (pop args))
	(while (and args (not (memq (car args) lambda-list-keywords)))
	  (let ((arg (pop args)))
	    (or (consp arg) (setq arg (list arg)))
	    (let* ((karg (if (consp (car arg)) (caar arg)
			   (intern (concat ':' (car arg)))))
		   (varg (if (consp (car arg)) (cadar arg) (car arg)))
		   (def (if (cdr arg) (cadr arg)
			  (or (car bind-defs) (cadr (assq varg bind-defs)))))
		   (look (list `memq (list `quote karg) restarg)))
	      (and def bind-enquote (setq def (list `quote def)))
	      (if (cddr arg)
		  (let* ((temp (or (nth 2 arg) (gensym)))
			 (val (list `car (list `cdr temp))))
		    (arglist-do temp look)
		    (arglist-do varg
				   (list `if temp
					 (list `prog1 val (list `setq temp t))
					 def)))
		(arglist-do
		 varg
		 (list `car
		       (list `cdr
			     (if (null def)
				 look
			       (list `or look
				     (if (eq (cl-const-expr-p def) t)
					 (list
					  `quote
					  (list nil (cl-const-expr-val def)))
				       (list `list nil def))))))))
	      (push karg keys)))))
      (setq keys (nreverse keys))
      (or (and (eq (car args) `#'&allow-other-keys') (pop args))
	  (null keys) (= safety 0)
	  (let* ((var (gensym 'keys-'))
		 (allow `(:allow-other-keys))
		 (check (list
			 `while var
			 (list
			  `cond
			  (list (list `memq (list `car var)
				      (list `quote (append keys allow)))
				(list `setq var (list `cdr (list `cdr var))))
			  (list (list `car
				      (list `cdr
					    (list `memq (cons `quote allow)
						  restarg)))
				(list `setq var nil))
			  (list t
				(list
				 `error
				  'Bad keyword argument'
					 
				 (list `car var)))))))
	    (push (list `let (list (list var restarg)) check) bind-forms)))
      (while (and (eq (car args) `#'&aux') (pop args))
	(while (and args (not (memq (car args) lambda-list-keywords)))
	  (if (consp (car args))
	      (if (and bind-enquote (cadar args))
		  (arglist-do (caar args)
				 (list `quote (cadr (pop args))))
		(arglist-do (caar args) (cadr (pop args))))
	    (arglist-do (pop args) nil))))
      (if args (error 'Malformed argument list %s' save-args)))))

(defun cl-arglist-args (args)
  (if (nlistp args) (list args)
    (let ((res nil) (kind nil) arg)
      (while (consp args)
	(setq arg (pop args))
	(if (memq arg lambda-list-keywords) (setq kind arg)
	  (if (eq arg `#'&cl-defs') (pop args)
	    (and (consp arg) kind (setq arg (car arg)))
	    (and (consp arg) (cdr arg) (eq kind `#'&key') (setq arg (cadr arg)))
	    (setq res (nconc res (cl-arglist-args arg))))))
      (nconc res (and args (list args))))))

(defmacro deploy-arguments-list (lambda-type &rest args-n-body)
	(let ((new-form (cl-transform-lambda args-n-body `cl-none)))
		(setcar new-form lambda-type)
		(list `quote new-form)))
	)
]

{ #category : #benchmarks }
ELisp class >> bench [

	"ELisp bench"

	| lisp report allCode steps |

	lisp := self new loadDefaultLibraries.

	self setUpCode do: [:ea | lisp evalString: ea].
	allCode := self testCode.

	('Running ', self asString, ' benchmarks...')		
		displayProgressAt: Display center
		from: (steps := 0) to: (allCode size * 3) + 1
		during: 
	[:bar |
	
	report := String streamContents: [:str |

		str nextPutAll: 'initialisation => ';
	 		nextPutAll: [self new loadDefaultLibraries] gcbench; cr; cr.
		bar value: (steps := steps + 1).

		allCode do: [:code | | form val |
				str nextPutAll: code; cr; nextPutAll: ' => ';
	 				nextPutAll: [val := lisp evalString: code] gcbench; cr.
				bar value: (steps := steps + 1).
				str nextPutAll: '  ..reading ';
	 				nextPutAll: [form := lisp reader readString: code] gcbench;
				 	cr.		
				bar value: (steps := steps + 1).
				str nextPutAll: '  ..evaluating ';
	 				nextPutAll: [lisp evaluate: form] gcbench; cr;	
					nextPutAll: (val printStringForLisp: lisp); cr; cr.	
				bar value: (steps := steps + 1).
			].
	]].

	self display: report underLabel: self asString, ' benchmarks'
]

{ #category : #libraries }
ELisp class >> block [

	^ 
	#(in-library block


(defmacro block (name &rest body)
  'Define a lexically-scoped block named NAME.
NAME may be any symbol.  Code inside the BODY forms can call return-from
to jump prematurely out of the block.  This differs from catch and throw
in two respects:  First, the NAME is an unevaluated symbol rather than a
quoted symbol or other form; and second, NAME is lexically rather than
dynamically scoped:  Only references to it within BODY will work.  These
references may appear inside macro expansions, but not inside functions
called from BODY.'
  "(if (cl-safe-expr-p (cons $'progn body))" (cons `progn body)
    (list `identity
	  (list* `catch (list `quote (block-tag name))
		 body)))")"

(defmacro return (&optional result)
  'Return from the block named nil.
This is equivalent to (return-from nil RESULT).'
  (list `return-from nil result))

(defmacro return-from (name &optional result)
  'Return from the block named NAME.
This jump out to the innermost enclosing (block NAME ...) form,
returning RESULT from that form (or nil if RESULT is omitted).
This is compatible with Common Lisp, but note that defun and
defmacro do not create implicit blocks as they do in Common Lisp.'
  (let ((name2 (block-tag name)))
    (list `throw (list `quote name2) result)))

(defun block-tag (name)
  (intern (concat 'b-block-' name '-b')))


	)
]

{ #category : #libraries }
ELisp class >> common [

	^
#(in-library common

(let ((i 0))
	(dolist (rank 
				`(first second third fourth fifth sixth seventh eighth ninth tenth))
		(eval `(defun ,rank (list) 
					(nth ,i list)))
		(setq i (+ 1 i))))

(defun = (&rest args) (apply `nEqual: args))

(defun #'1+' (number) (+ 1 number))
(defun #'1-' (number) (- number 1))

(defun rplaca (&rest args) (apply `setcar args))
(defun rplacd (&rest args) (apply `setcdr args))

(defun nlistp (arg) (not (listp arg))) 

(defun butlast (x &optional n)
  'Returns a copy of LIST with the last N elements removed.'
  (if (and (not (null n)) (<= n 0)) x
    (nbutlast (copy-seq x) n)))

(defun nbutlast (x &optional n)
  'Modifies LIST to remove the last N elements.'
  (let ((m (length x)))
    (or (not (null n)) (setq n 1))
    (and (< n m)
	 (progn
	   (if (> n 0) (setcdr: (nthcdr (- (#'1-' m) n) x) nil))
	   x))))

(defmacro push (newelt listname)
  'Add NEWELT to the list stored in the symbol LISTNAME.
This is equivalent to (setq LISTNAME (cons NEWELT LISTNAME)).
LISTNAME must be a symbol.'
  (list `setq listname
	(list `cons newelt listname)))

(defmacro pop (listname)
  'Return the first element of LISTNAME''s value, and remove it from the list.
LISTNAME must be a symbol whose value is a list.
If the value is nil, pop returns nil but does not actually
change the list.'
  (list `prog1 (list `car listname)
	(list `setq listname (list `cdr listname))))

(defmacro pop2 (place)
  (list `prog1 (list `car (list `cdr place))
	(list `setq place (list `cdr (list `cdr place)))))

(defmacro when (cond &rest body)
  'If COND yields non-nil, do BODY, else return nil.'
  (list `if cond (cons `progn body)))

(defmacro unless (cond &rest body)
  'If COND yields nil, do BODY, else return nil.'
  (cons `if (cons cond (cons nil body))))


(defun list* (arg &rest rest) 
 'Return a new list with specified args as elements, cons''d to last arg.
Thus, (list* A B C D) is equivalent to (nconc (list A B C) D) or to
(cons A (cons B (cons C D))).'
 	(cond ((null rest) arg)
			((null (cdr rest)) (cons arg (car rest)))
			((yes*) (let* ((n (length rest))
	  				(copy (copy-seq rest))
	  				(last (nthcdr (- n 2) copy)))
	    			(setcdr last (car (cdr last)))
	    			(cons arg copy)))))

(defun remove (elt seq)
 'Return a copy of SEQ with all occurences of ELT removed.
SEQ must be a list, vector, or string.  The comparison is done with ''equal''.'  
(if (listp seq)
		(delete elt (copy-seq seq))
      (delete elt seq)))

(defun remq (elt list)
'Return a copy of LIST with all occurences of ELT removed.
The comparison is done with ''eq''.'
  (if (memq elt list)
      (delq elt (copy-seq list))
    list))


(defun subseq (seq start &optional end)
'Return the subsequence of SEQ from START to END.
If END is omitted, it defaults to the length of the sequence.
If START or END is negative, it counts from the end.'
  (if (stringp seq) (substring seq start end)
    (let (len)
      (and end (< end 0) (setq end (+ end (setq len (length seq)))))
      (if (< start 0) (setq start (+ start (or len (setq len (length seq))))))
      (cond ((listp seq)
	     (if (> start 0) (setq seq (nthcdr start seq)))
	     (if end
		 (let ((res ()))
		   (while (>= (setq end (#'1-' end)) start)
		     (push (pop seq) res))
		   (nreverse res))
	       (copy-seq seq)))
	    (t
	     (or end (setq end (or len (length seq))))
	     (let ((res (make-vector (max (- end start) 0) ()))
		   (i 0))
	       (while (< start end)
		 (aset res i (aref seq start))
		 (setq i (1+ i) start (1+ start)))
	       res))))))

(defselectors caaar (car car car) 'Return the car of the car of the car of X')
(defselectors caadr (cdr car car) 'Return the car of the car of the cdr of X')
(defselectors cadar (car cdr car) 'Return the car of the cdr of the car of X')
(defselectors caddr (cdr cdr car) 'Return the car of the cdr of the cdr of X')
(defselectors cdaar (car car cdr) 'Return the cdr of the car of the car of X')
(defselectors cdadr (cdr car cdr) 'Return the cdr of the car of the cdr of X')
(defselectors cddar (car cdr cdr) 'Return the cdr of the cdr of the car of X')
(defselectors cdddr (cdr cdr cdr) 'Return the cdr of the cdr of the cdr of X')

(defselectors caaaar (car car car car) 
	'Return the car of the car of the car of the car of X')
(defselectors caaadr (cdr car car car) 
	'Return the car of the car of the car of the cdr of X')
(defselectors caadar (car cdr car car) 
	'Return the car of the car of the cdr of the car of X')
(defselectors caaddr (cdr cdr car car) 
	'Return the car of the car of the cdr of the cdr of X')
(defselectors cadaar (car car cdr car) 
	'Return the car of the cdr of the car of the car of X')
(defselectors cadadr (cdr car cdr car) 
	'Return the car of the cdr of the car of the cdr of X')
(defselectors caddar (car cdr cdr car) 
	'Return the car of the cdr of the cdr of the car of X')
(defselectors cadddr (cdr cdr cdr car) 
	'Return the car of the cdr of the cdr of the cdr of X')
(defselectors cdaaar (car car car cdr) 
	'Return the cdr of the car of the car of the car of X')
(defselectors cdaadr (cdr car car cdr) 
	'Return the cdr of the car of the car of the cdr of X')
(defselectors cdadar (car cdr car cdr) 
	'Return the cdr of the car of the cdr of the car of X')
(defselectors cdaddr (cdr cdr car cdr) 
	'Return the cdr of the car of the cdr of the cdr of X')
(defselectors cddaar (car car cdr cdr) 
	'Return the cdr of the cdr of the car of the car of X')
(defselectors cddadr (cdr car cdr cdr) 
	'Return the cdr of the cdr of the car of the cdr of X')
(defselectors cdddar (car cdr cdr cdr) 
	'Return the cdr of the cdr of the cdr of the car of X')
(defselectors cddddr (cdr cdr cdr cdr) 
	'Return the cdr of the cdr of the cdr of the cdr of X')

"mapping Smalltalk selectors into functions:"

(defunary sqrt sqrt 'Return the square root of the argument')
(defunary sin sin)
(defunary tan tan)
(defunary cos cos)
(defunary asin arcSin)
(defunary acos arcCos)
(defunary exp exp 'Return the exponential of X as a floating point number')
(defunary log ln 'Return the natural logarithm of X')
(defunary abs abs 'Return the absolute value of X')

(defbinary expt raisedTo: 'Return X raised to Y')
(defbinary #'string=' =)

"extra"

(defunary procedure-source lispCode 
	'Return the source code for the argument (a procedure)
This can be a ConsCell, if the argument is a lambda form,
 or a String of Smalltalk code if it is a primitive')

(defun display-source (symbol) 
	'Display the source code for the procedure bound to SYMBOL
This can be either Lisp or Smalltalk code'
	(princ (procedure-source (symbol-function symbol))))

(defun disassemble (symbol)
	(procedure-source (symbol-function symbol)))
)
]

{ #category : #libraries }
ELisp class >> compilers [

	"compiler optimizations -- experimental"

	^ 
	#(in-library compilers

(put `let: `compiler `compile-let)
(put `letStar: `compiler `compile-let)
(put `if: `compiler `compile-if)
(put `do: `compiler `compile-do)
(put `quote: `compiler `compile-quote)
(put `progn: `compiler `compile-progn)
(put `sendMessage: `compiler `compile-message-send)

"context-free functions"

(put `+ `context-free (yes*))
(put `- `context-free (yes*))
(put `* `context-free (yes*))
(put `/ `context-free (yes*))

(mapcar (lambda (s) (put s `context-free (yes*)))
	`(#'1+' #'1-' car: cdr: > >= < <= sqrt sin cos tan atan exp log abs expt "LISPand: LISPor:" max: min:))

"unary messages"

(put `car: `unary-message `car)
(put `null: `unary-message `isNil)
(put `zeroP: `unary-message `isZero)

"binary messages"

(put `+ `binary-message `+)
(put `- `binary-message  `-)
(put `* `binary-message `*)
(put `/ `binary-message `/)

(mapcar (lambda (s) (put s `boolean-binary-message s))
	`(> >= < <=))

)
]

{ #category : #private }
ELisp class >> defaultLibraries [

	^ #(glue #'provide-library' plist compilers #'small-macros' common  #'arguments-lists' loop #'turtle-graphics')
]

{ #category : #libraries }
ELisp class >> graphics [

	^ #(in-library graphics

(defun point (x y)  (send Point x:y: x y))

(defmacro color (name) `(send Color ,name))	

	)
]

{ #category : #private }
ELisp class >> initialize [

	super initialize
]

{ #category : #libraries }
ELisp class >> loop [

	"the loop macro"

"
code borrowed from GNU Emacs 21.1 cl-macs.el file
author: Dave Gillepsie
copyright: Free Software Foundation
licence: GPL
"

	^ 
	#(in-library loop

(require-library `block)
(require-library `common)

(defmacro loop (&rest args)
  '(loop CLAUSE...): The Common Lisp loop macro.
Valid clauses are:
  for VAR from/upfrom/downfrom NUM to/upto/downto/above/below NUM by NUM,
  for VAR in LIST by FUNC, for VAR on LIST by FUNC, for VAR = INIT then EXPR,
  for VAR across ARRAY, repeat NUM, with VAR = INIT, while COND, until COND,
  always COND, never COND, thereis COND, collect EXPR into VAR,
  append EXPR into VAR, nconc EXPR into VAR, sum EXPR into VAR,
  count EXPR into VAR, maximize EXPR into VAR, minimize EXPR into VAR,
  if COND CLAUSE [and CLAUSE]... else CLAUSE [and CLAUSE...],
  unless COND CLAUSE [and CLAUSE]... else CLAUSE [and CLAUSE...],
  do EXPRS..., initially EXPRS..., finally EXPRS..., return EXPR,
  finally return EXPR, named NAME.'
  (if (not (memq t (mapcar `symbolp (delq nil (delq t (copy-list args))))))
      (list `block nil (list* `while t args))
    (let ((loop-name nil)	(loop-bindings nil)
	  (loop-body nil)	(loop-steps nil)
	  (loop-result nil)	(loop-result-explicit nil)
	  (loop-result-var nil) (loop-finish-flag nil)
	  (loop-accum-var nil)	(loop-accum-vars nil)
	  (loop-initially nil)	(loop-finally nil)
	  (loop-map-form nil)   (loop-first-flag nil)
	  (loop-destr-temps nil) (loop-symbol-macs nil))
      (setq args (append args `(cl-end-loop)))
      (while (not (eq (car args) `cl-end-loop)) (loop-parse-clause))
      (if loop-finish-flag
	  (push (list (list loop-finish-flag t)) loop-bindings))
      (if loop-first-flag
	  (progn (push (list (list loop-first-flag t)) loop-bindings)
		 (push (list `setq loop-first-flag nil) loop-steps)))
      (let* ((epilogue (nconc (nreverse loop-finally)
			      (list (or loop-result-explicit loop-result))))
	     (ands (cl-loop-build-ands (nreverse loop-body)))
	     (while-body (nconc (cadr ands) (nreverse loop-steps)))
	     (body (append
		    (nreverse loop-initially)
		    (list (if loop-map-form
			      (list `block `t-t-cl-finish-t-t
				    (subst
				     (if (eq (car ands) t) while-body
				       (cons (list `or (car ands)
						   `(return-from t-t-cl-finish-t-t
						      nil))
					     while-body))
				     `t-t-cl-map loop-map-form))
			    (list* `while (car ands) while-body)))
		    (if loop-finish-flag
			(if (equal epilogue `(nil)) (list loop-result-var)
			  (list (list `if loop-finish-flag
				      (cons `progn epilogue) loop-result-var)))
		      epilogue))))
	(if loop-result-var (push (list loop-result-var) loop-bindings))
	(while loop-bindings
	  (if (cdar loop-bindings)
	      (setq body (list (cl-loop-let (pop loop-bindings) body t)))
	    (let ((lets nil))
	      (while (and loop-bindings
			  (not (cdar loop-bindings)))
		(push (car (pop loop-bindings)) lets))
	      (setq body (list (cl-loop-let lets body nil))))))
	(if loop-symbol-macs
	    (setq body (list (list* `symbol-macrolet loop-symbol-macs body))))
	(list* `block loop-name body)))))

(defun loop-parse-clause () 
  (let ((word (pop args))
	(hash-types `(hash-key hash-keys hash-value hash-values))
	(key-types `(key-code key-codes key-seq key-seqs
		     key-binding key-bindings)))
    (cond

     ((null args)
      (error 'Malformed loop macro'))

     ((eq word `named)
      (setq loop-name (pop args)))

     ((eq word `initially)
      (if (memq (car args) `(do doing)) (pop args))
      (or (consp (car args)) (error 'Syntax error on initially clause'))
      (while (consp (car args))
	(push (pop args) loop-initially)))

     ((eq word `finally)
      (if (eq (car args) `return)
	  (setq loop-result-explicit (or (pop2 args) `(quote nil)))
	(if (memq (car args) `(do doing)) (pop args))
	(or (consp (car args)) (error 'Syntax error on finally clause'))
	(if (and (eq (caar args) `return) (null loop-name))
	    (setq loop-result-explicit (or (nth 1 (pop args)) `(quote nil)))
	  (while (consp (car args))
	    (push (pop args) loop-finally)))))

     ((memq word `(for as))
      (let ((loop-for-bindings nil) (loop-for-sets nil) (loop-for-steps nil)
	    (ands nil))
	(while
	    (let ((var (or (pop args) (gensym))))
	      (setq word (pop args))
	      (if (eq word `being) (setq word (pop args)))
	      (if (memq word `(the each)) (setq word (pop args)))
	      (cond

	       ((memq word `(from downfrom upfrom to downto upto
			     above below by))
		(push word args)
		(if (memq (car args) `(downto above))
		    (error 'Must specify from value for downward loop'))
		(let* ((down (or (eq (car args) `downfrom)
				 (memq (caddr args) `(downto above))))
		       (excl (or (memq (car args) `(above below))
				 (memq (caddr args) `(above below))))
		       (start (and (memq (car args) `(from upfrom downfrom))
				   (pop2 args)))
		       (end (and (memq (car args)
				       `(to upto downto above below))
				 (pop2 args)))
		       (step (and (eq (car args) `by) (pop2 args)))
		       (end-var (and (not (cl-const-expr-p end)) (gensym)))
		       (step-var (and (not (cl-const-expr-p step))
				      (gensym))))
		  (and step (numberp step) (<= step 0)
		       (error 'Loop by value is not positive: %s' step))
		  (push (list var (or start 0)) loop-for-bindings)
		  (if end-var (push (list end-var end) loop-for-bindings))
		  (if step-var (push (list step-var step)
					loop-for-bindings))
		  (if end
		      (push (list
				(if down (if excl `#'>' `#'>=') (if excl `< `#'<='))
				var (or end-var end)) loop-body))
		  (push (list var (list (if down `- `+) var
					   (or step-var step 1)))
			   loop-for-steps)))

	       ((memq word `(in in-ref on))
		(let* ((on (eq word `on))
		       (temp (if (and on (symbolp var)) var (gensym))))
		  (push (list temp (pop args)) loop-for-bindings)
		  (push (list `consp temp) loop-body)
		  (if (eq word `in-ref)
		      (push (list var (list `car temp)) loop-symbol-macs)
		    (or (eq temp var)
			(progn
			  (push (list var nil) loop-for-bindings)
			  (push (list var (if on temp (list `car temp)))
				   loop-for-sets))))
		  (push (list temp
				 (if (eq (car args) `by)
				     (let ((step (pop2 args)))
				       (if (and (memq (car-safe step)
						      `(quote function
							      function*))
						(symbolp (nth 1 step)))
					   (list (nth 1 step) temp)
					 (list `funcall step temp)))
				   (list `cdr temp)))
			   loop-for-steps)))

	       ((eq word `=)
		(let* ((start (pop args))
		       (then (if (eq (car args) `then) (pop2 args) start)))
		  (push (list var nil) loop-for-bindings)
		  (if (or ands (eq (car args) `and))
		      (progn
			(push (list var
				       (list `if
					     (or loop-first-flag
						 (setq loop-first-flag
						       (gensym)))
					     start var))
				 loop-for-sets)
			(push (list var then) loop-for-steps))
		    (push (list var
				   (if (eq start then) start
				     (list `if
					   (or loop-first-flag
					       (setq loop-first-flag (gensym)))
					   start then)))
			     loop-for-sets))))

	       ((memq word `(across across-ref))
		(let ((temp-vec (gensym)) (temp-idx (gensym)))
		  (push (list temp-vec (pop args)) loop-for-bindings)
		  (push (list temp-idx -1) loop-for-bindings)
		  (push (list `< (list `setq temp-idx (list `#'1+' temp-idx))
				 (list `length temp-vec)) loop-body)
		  (if (eq word `across-ref)
		      (push (list var (list `aref temp-vec temp-idx))
			       loop-symbol-macs)
		    (push (list var nil) loop-for-bindings)
		    (push (list var (list `aref temp-vec temp-idx))
			     loop-for-sets))))

	       ((memq word `(element elements))
		(let ((ref (or (memq (car args) `(in-ref of-ref))
			       (and (not (memq (car args) `(in of)))
				    (error 'Expected of '))))
		      (seq (pop2 args))
		      (temp-seq (gensym))
		      (temp-idx (if (eq (car args) `using)
				    (if (and (= (length (cadr args)) 2)
					     (eq (caadr args) `index))
					(cadr (pop2 args))
				      (error 'Bad using clause'))
				  (gensym))))
		  (push (list temp-seq seq) loop-for-bindings)
		  (push (list temp-idx 0) loop-for-bindings)
		  (if ref
		      (let ((temp-len (gensym)))
			(push (list temp-len (list `length temp-seq))
				 loop-for-bindings)
			(push (list var (list `elt temp-seq temp-idx))
				 loop-symbol-macs)
			(push (list `< temp-idx temp-len) loop-body))
		    (push (list var nil) loop-for-bindings)
		    (push (list `and temp-seq
				   (list `or (list `consp temp-seq)
					 (list `< temp-idx
					       (list `length temp-seq))))
			     loop-body)
		    (push (list var (list `if (list `consp temp-seq)
					     (list `pop temp-seq)
					     (list `aref temp-seq temp-idx)))
			     loop-for-sets))
		  (push (list temp-idx (list `#'1+' temp-idx))
			   loop-for-steps)))

	       ((memq word hash-types)
		(or (memq (car args) `(in of)) (error 'Expected of'))
		(let* ((table (pop2 args))
		       (other (if (eq (car args) `using)
				  (if (and (= (length (cadr args)) 2)
					   (memq (caadr args) hash-types)
					   (not (eq (caadr args) word)))
				      (cadr (pop2 args))
				    (error 'Bad using clause'))
				(gensym))))
		  (if (memq word `(hash-value hash-values))
		      (setq var (prog1 other (setq other var))))
		  (setq loop-map-form
			(list `maphash (list `function
					     (list* `lambda (list var other)
						    `t-t-cl-map)) table))))

	       (t
		(let ((handler (and (symbolp word)
				    (get word `cl-loop-for-handler))))
		  (if handler
		      (funcall handler var)
		    (error (concat 'Expected a for preposition, found ' word))))))
	      (eq (car args) `and))
	  (setq ands t)
	  (pop args))
	(if (and ands loop-for-bindings)
	    (push (nreverse loop-for-bindings) loop-bindings)
	  (setq loop-bindings (nconc (mapcar `list loop-for-bindings)
				     loop-bindings)))
	(if loop-for-sets
	    (push (list `progn
			   (cl-loop-let (nreverse loop-for-sets) `setq ands)
			   t) loop-body))
	(if loop-for-steps
	    (push (cons (if ands `psetq `setq)
			   (apply `append (nreverse loop-for-steps)))
		     loop-steps))))

     ((eq word `repeat)
      (let ((temp (gensym)))
	(push (list (list temp (pop args))) loop-bindings)
	(push (list `#'>=' (list `setq temp (list `#'1-' temp)) 0) loop-body)))

     ((memq word `(collect collecting))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum nil `nreverse)))
	(if (eq var loop-accum-var)
	    (push (list `progn (list `push what var) t) loop-body)
	  (push (list `progn
			 (list `setq var (list `nconc var (list `list what)))
			 t) loop-body))))

     ((memq word `(nconc nconcing append appending))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum nil `nreverse)))
	(push (list `progn
		       (list `setq var
			     (if (eq var loop-accum-var)
				 (list `nconc
				       (list (if (memq word `(nconc nconcing))
						 `nreverse `reverse)
					     what)
				       var)
			       (list (if (memq word `(nconc nconcing))
					 `nconc `append)
				     var what))) t) loop-body)))

     ((memq word `(concat concating))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum '')))
	(push (list `progn (list `callf `concat var what) t) loop-body)))

     ((memq word `(vconcat vconcating))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum [])))
	(push (list `progn (list `callf `vconcat var what) t) loop-body)))

     ((memq word `(sum summing))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum 0)))
	(push (list `progn (list `incf var what) t) loop-body)))

     ((memq word `(count counting))
      (let ((what (pop args))
	    (var (cl-loop-handle-accum 0)))
	(push (list `progn (list `if what (list `incf var)) t) loop-body)))

     ((memq word `(minimize minimizing maximize maximizing))
      (let* ((what (pop args))
	     (temp (if (cl-simple-expr-p what) what (gensym)))
	     (var (cl-loop-handle-accum nil))
	     (func (intern (substring (symbol-name word) 0 3)))
	     (set (list `setq var (list `if var (list func var temp) temp))))
	(push (list `progn (if (eq temp what) set
				(list `let (list (list temp what)) set))
		       t) loop-body)))

     ((eq word `with)
      (let ((bindings nil))
	(while (progn (push (list (pop args)
				     (and (eq (car args) `=) (pop2 args)))
			       bindings)
		      (eq (car args) `and))
	  (pop args))
	(push (nreverse bindings) loop-bindings)))

     ((eq word `while)
      (push (pop args) loop-body))

     ((eq word `until)
      (push (list `not (pop args)) loop-body))

     ((eq word `always)
      (or loop-finish-flag (setq loop-finish-flag (gensym)))
      (push (list `setq loop-finish-flag (pop args)) loop-body)
      (setq loop-result t))

     ((eq word `never)
      (or loop-finish-flag (setq loop-finish-flag (gensym)))
      (push (list `setq loop-finish-flag (list `not (pop args)))
	       loop-body)
      (setq loop-result t))

     ((eq word `thereis)
      (or loop-finish-flag (setq loop-finish-flag (gensym)))
      (or loop-result-var (setq loop-result-var (gensym)))
      (push (list `setq loop-finish-flag
		     (list `not (list `setq loop-result-var (pop args))))
	       loop-body))

     ((memq word `(if when unless))
      (let* ((cond (pop args))
	     (then (let ((loop-body nil))
		     (loop-parse-clause)
		     (cl-loop-build-ands (nreverse loop-body))))
	     (else (let ((loop-body nil))
		     (if (eq (car args) `else)
			 (progn (pop args) (loop-parse-clause)))
		     (cl-loop-build-ands (nreverse loop-body))))
	     (simple (and (eq (car then) t) (eq (car else) t))))
	(if (eq (car args) `end) (pop args))
	(if (eq word `unless) (setq then (prog1 else (setq else then))))
	(let ((form (cons (if simple (cons `progn (nth 1 then)) (nth 2 then))
			  (if simple (nth 1 else) (list (nth 2 else))))))
	  (if (cl-expr-contains form `it)
	      (let ((temp (gensym)))
		(push (list temp) loop-bindings)
		(setq form (list* `if (list `setq temp cond)
				  (subst temp `it form))))
	    (setq form (list* `if cond form)))
	  (push (if simple (list `progn form t) form) loop-body))))

     ((memq word `(do doing))
      (let ((body nil))
	(or (consp (car args)) (error 'Syntax error on do clause'))
	(while (consp (car args)) (push (pop args) body))
	(push (cons `progn (nreverse (cons t body))) loop-body)))

     ((eq word `return)
      (or loop-finish-flag (setq loop-finish-flag (gensym)))
      (or loop-result-var (setq loop-result-var (gensym)))
      (push (list `setq loop-result-var (pop args)
		     loop-finish-flag nil) loop-body))

     (t
      (let ((handler (and (symbolp word) (get word `cl-loop-handler))))
	(or handler (error (concat 'Expected a loop keyword, found ' word)))
	(funcall handler))))
    (if (eq (car args) `and)
	(progn (pop args) (loop-parse-clause)))))

(defun cl-loop-let (specs body par)   
  (let ((p specs) (temps nil) (new nil))
    (while (and p (or (symbolp (car-safe (car p))) (null (cadar p))))
      (setq p (cdr p)))
    (and par p
	 (progn
	   (setq par nil p specs)
	   (while p
	     (or (cl-const-expr-p (cadar p))
		 (let ((temp (gensym)))
		   (push (list temp (cadar p)) temps)
		   (setcar (cdar p) temp)))
	     (setq p (cdr p)))))
    (while specs
      (if (and (consp (car specs)) (listp (caar specs)))
	  (let* ((spec (caar specs)) (nspecs nil)
		 (expr (cadr (pop specs)))
		 (temp (cdr (or (assq spec loop-destr-temps)
				(car (push (cons spec (or (last spec 0)
							     (gensym)))
					      loop-destr-temps))))))
	    (push (list temp expr) new)
	    (while (consp spec)
	      (push (list (pop spec)
			     (and expr (list (if spec `pop `car) temp)))
		       nspecs))
	    (setq specs (nconc (nreverse nspecs) specs)))
	(push (pop specs) new)))
    (if (eq body `setq)
	(let ((set (cons (if par `psetq `setq) (apply `nconc (nreverse new)))))
	  (if temps (list `let* (nreverse temps) set) set))
      (list* (if par `let `let*)
	     (nconc (nreverse temps) (nreverse new)) body))))

(defun cl-loop-handle-accum (def &optional func)  
  (if (eq (car args) `into)
      (let ((var (pop2 args)))
	(or (memq var loop-accum-vars)
	    (progn (push (list (list var def)) loop-bindings)
		   (push var loop-accum-vars)))
	var)
    (or loop-accum-var
	(progn
	  (push (list (list (setq loop-accum-var (gensym)) def))
		   loop-bindings)
	  (setq loop-result (if func (list func loop-accum-var)
			      loop-accum-var))
	  loop-accum-var))))

(defun cl-loop-build-ands (clauses)
  (let ((ands nil)
	(body nil))
    (while clauses
      (if (and (eq (car-safe (car clauses)) `progn)
	       (eq (car (last (car clauses))) t))
	  (if (cdr clauses)
	      (setq clauses (cons (nconc (butlast (car clauses))
					 (if (eq (car-safe (cadr clauses))
						 `progn)
					     (cdadr clauses)
					   (list (cadr clauses))))
				  (cddr clauses)))
	    (setq body (cdr (butlast (pop clauses)))))
	(push (pop clauses) ands)))
    (setq ands (or (nreverse ands) (list t)))
    (list (if (cdr ands) (cons `and ands) (car ands))
	  body
	  (let ((full (if body
			  (append ands (list (cons `progn (append body `(t)))))
			ands)))
	    (if (cdr full) (cons `and full) (car full))))))


(defun cl-expr-contains (x y)
  (cond ((equal y x) 1)
	((and (consp x) (not (memq (car-safe x) `(quote function function*))))
	 (let ((sum 0))
	   (while x
	     (setq sum (+ sum (or (cl-expr-contains (pop x) y) 0))))
	   (and (> sum 0) sum)))
	(t nil)))

	)
]

{ #category : #libraries }
ELisp class >> plist [

	"property lists support"

	^ 
	#(in-library plist

		(defun plist-member (plist prop)
'Return non-nil if PLIST has the property PROP.
PLIST is a property list, which is a list of the form (PROP1 VALUE1 PROP2 VALUE2 ...).  PROP is a symbol.
Unlike plist-get, this allows you to distinguish between a missing property and a property with the value nil.
The value is actually the tail of PLIST whose car is PROP.'
			(cond
				((null plist) nil)
				((equal prop (car plist)) (cdr plist))
				((yes*) (plist-member (cdr (cdr plist)) prop))))

		(defun plist-get (plist prop)
'Extract a value from a property list.
PLIST is a property list, which is a list of the form (PROP1 VALUE1 PROP2 VALUE2...).  
This function returns the value corresponding to the given PROP, or nil if PROP is not one of the properties on the list.'
			(let ((pm (plist-member plist prop)))
				(if (null pm)
					(no*)
					(car pm))))

		(defun plist-remove (plist prop)
'Remove PROP from property list PLIST.'
			(plist-tail-remove plist prop nil))

		(defun plist-tail-remove (plist prop oplist)
'private. used by plist-remove'
			(cond
				((null plist) oplist)		
				((equal prop (car plist)) (append oplist (cdr (cdr plist))))
				((yes*) (plist-tail-remove (cdr (cdr plist)) prop
										  (append oplist (list (car plist))
															(list (cadr plist)))))))			

		(defun plist-put (plist prop val)
'Change value in PLIST of PROP to VAL.
PLIST is a property list, which is a list of the form (PROP1 VALUE1 PROP2 VALUE2 ...).  PROP is a symbol and VAL is any object.
If PROP is already a property on the list, its value is set to VAL,otherwise the new PROP VAL pair is added.  
The PLIST is modified by side effects.The new value is returned'
			(let ((cell (plist-member plist prop)))
				(if (not (null cell)) (setcar: cell val)
					(setq plist (append plist (list prop val))))
				plist))

 		(defun put (symbol prop value)
'Store SYMBOL''s PROP property with value VALUE.
It can be retrieved with (get SYMBOL PROP).'
			(setplist symbol 
				(if (null (symbol-plist symbol))
					(list prop value)
					(plist-put (symbol-plist symbol) prop value)))
			value)

 		(defun get (symbol prop)
'Return the value of SYMBOL''s PROP property.
It can be stored with (put SYMBOL PROP VAL).'
			(plist-get (symbol-plist symbol) prop)) 

		(defun remove-property (symbol prop)
'Remove PROP from the property list of SYMBOL'
			(setplist symbol (plist-remove (symbol-plist symbol) prop)))

)
]

{ #category : #libraries }
ELisp class >> prolog [

	"interfacing with Prolog
http://www.zogotounga.net/comp/squeak/prolog.htm
"

	^ 
	#(in-library prolog

(defmacro make-prolog (class)
	`(let ((prolog (send ,class new)))
		(send prolog inputStream: (send #'*standard-input*' stream))
		(send prolog outputStream: (send #'*standard-output*' stream))))

(defmacro prolog (expert query)
	`(send-for-values ,expert inferSmalltalk: (send (list ,query) asPrologList)))

)
]

{ #category : #libraries }
ELisp class >> provideLibrary [

	"inspired by the 'provide' feature of Emacs Lisp"
	
	^ 
	#(progn

		(defmacro in-library (lib . body)
'Evaluate BODY as the code provided by library LIB, a symbol.
A variable called Library:LIB stores all symbols bound at top-level in BODY, be it as variables, functions or macros.
After BODY has been evaluated, LIB is added to the *libraries*.'
			(let (functions)
				(dolist (form body)
					(if (memq (nth 0 form) `(defun defmacro defvar))
						(setq functions (append functions (list (nth 1form))))))
			`(progn
				(defvar ,(sconcat `#'*library:' lib `*) (quote ,functions))
				,@body
				(provide-library (quote ,lib)))))
	
		(defvar #'*libraries*' nil)

		(defun provide-library (symbol)
'Declare SYMBOL a provided feature. 
The list of features is stored in variable *libraries*'
			(add-to-list `#'*libraries*' symbol)
			(yes*))

		(defun require-library (symbol)
'Load library SYMBOL if it is not provided yet'
			(or (featurep symbol) (load-library symbol)))

		(defun add-to-list (lst element)
'If ELEMENT is not a member of LIST (a quoted symbol), add it as the last element'
			(if (member element (symbol-value lst))
					(symbol-value lst)
				(set lst (append (symbol-value lst) (list element)))))
	
		(defun featurep (symbol)
'Tells weither library SYMBOL is provided'
			(if (member symbol #'*libraries*') (yes*) (no*))))

]

{ #category : #benchmarks }
ELisp class >> setUpCode [

	^ {
'(defun fib (x)
	 (if (< x 2)
		x
		(+ (fib (- x 1)) (fib (- x 2)))))'.
	}

]

{ #category : #libraries }
ELisp class >> smallMacros [

	"a set of macros for mapping Smalltalk methods into functions. it makes it easy to define lisp functions based on simple message sends; moreover the compiler knows how to handle them."

	^
#(in-library small-macros

(defmacro defunary (lisp-name selector #'&optional' doc-string)
	`(progn
		(defun ,lisp-name (x) ,doc-string (send-message `,selector x))
		(put `,lisp-name `unary-message `,selector)))

(defmacro defbinary (lisp-name selector #'&optional' doc-string)
	`(progn
		(defun ,lisp-name (x y) ,doc-string (send-message `,selector x y))
		(put `,lisp-name `binary-message `,selector)))

(defmacro defcascade (lisp-name selectors #'&optional' doc-string)
	`(defun ,lisp-name (x) ,doc-string
		(send-cascade `,selectors x)))

(defmacro defselectors (lisp-name selectors #'&optional' doc-string)
	`(progn
		(defun ,lisp-name (x) ,doc-string (send-selectors `,selectors x))
		(put `,lisp-name `selectors `,selectors)))
)
]

{ #category : #benchmarks }
ELisp class >> testCode [

	^ {
'(+ 1 1)'.
'(defun assoc (x a)
	(cond
		((null a) nil)
		((equal x (car (car a))) (car a))
		(t (assoc x (cdr a)))))'.
'(assoc 1 (list (list 2 5) (list 1 8)))'.
'(fib 12)'
		}
]

{ #category : #libraries }
ELisp class >> turtleGraphics [

	"simple-minded turtles implementation showing how easy it is to leverage Squeak objects from a LISP interpreter. note that this library provides turtles for all dialects, including ULisp and SScheme.

	see LKTurtlePlayGround class comments for details and examples

	(send and send-messages are defined in ELisp class>>smallMacros)"

	^ #(in-library turtle-graphics

(load-library `graphics)

(unless (boundp `#'*turtle-playground*')

	(defvar #'*turtle-playground*' (send LKTurtlePlayGround new))
	(defvar #'*turtle*' (send #'*turtle-playground*' pen))

	(defun turtle-show (bool)
		(send-message (if bool `openInWorld `delete) #'*turtle-playground*' ))

	(defun turtle-size (w h)
		(send-message `extent: #'*turtle-playground*' (point w h)))

	(defun turtle-clear (w h)
		(send-message `clear #'*turtle-playground*'))

	(defmacro turtle (selector #'&rest' arguments)
		`(send-message `,selector #'*turtle*'  ,@arguments))

	(defmacro #'turtle*' (#'&rest' messages)
		(append (list `progn:)
			(mapcar
				(lambda (message) (append `(send #'*turtle*') message))
				messages)))
	))
]

{ #category : #private }
ELisp class >> wantsFullArgumentsListsSupport [
	
	"there is a noticeable overall speedup if this is set to false.
	in that case, only &rest and &optional keywords are recognized

	requires the function deploy-arguments-list defined in library #argumentsLists"

	^ true
]

{ #category : #'LISP-functions' }
ELisp >> * aConsCell [

"(* &rest NUMBERS)
Return the product of any number of NUMBERS, even 0"

	| mul |

	mul := 1.
	(aConsCell ifNil: [^ 1]) do: [:each | 
		(each isNumber or: [each isComplex]) ifFalse: [self lispError: 'Number expected'].
		mul := mul * each].

	^ mul
]

{ #category : #'LISP-functions' }
ELisp >> + aConsCell [

"(+ &rest NUMBERS)
Return the sum of any number of NUMBERS, even 0"

	| sum |

	sum := 0.

	(aConsCell ifNil: [^ 0]) do: [:each | 
		(each isNumber or: [each isComplex]) ifFalse: [self lispError: 'Number expected'].
		sum := sum + each].

	^ sum
]

{ #category : #'LISP-functions' }
ELisp >> - aConsCell [

"(- NUMBER &rest MORE-NUMBERS)
Negate number or subtract numbers.
With one arg, negates it.  With more than one arg, subtracts all but the first from the first."
	
	| x |

	aConsCell ifNil: [self lispError: 'At least one argument expected'].
	x := aConsCell car.
	(aConsCell cdr ifNil: [^ x negated]) do: [:each | 
		(each isNumber or: [each isComplex]) ifFalse: [self lispError: 'Number expected'].
		x := x - each].

	^ x
]

{ #category : #'LISP-functions' }
ELisp >> / aConsCell [

"(/ DIVIDEND DIVISOR &rest MORE-DIVISORS)
Returns first argument divided by all the remaining arguments. 
All arguments must be numbers"

	| x |

	aConsCell ifNil: [self lispError: 'At least one argument expected'].
	x := aConsCell car.
	(aConsCell cdr ifNil: [^ 1/x ]) do: [:each | 
		(each isNumber or: [each isComplex]) ifFalse: [self lispError: 'Number expected'].
		x := x / each].

	^ x


]

{ #category : #'LISP-functions' }
ELisp >> < aConsCell [

"(< NUM1 NUM2 &rest NUMS)
Return t if the arguments (which should be numbers) are in increasing order"

	aConsCell cellsDo: [:c |
		(c car < (c cadr ifNil: [^ self trueValue])) ifFalse: [^ self falseValue]]. 

]

{ #category : #'LISP-functions' }
ELisp >> <= aConsCell [

"(<= NUM1 NUM2 &rest NUMS)
Return t if the arguments (which should be numbers) are in increasing order, with equal arguments allowed"

	aConsCell cellsDo: [:c |
		(c car <= (c cadr ifNil: [^ self trueValue])) ifFalse: [^ self falseValue]]. 

]

{ #category : #'LISP-functions' }
ELisp >> > aConsCell [

"(> NUM1 NUM2 &rest NUMS)
Return t if the arguments (which should be numbers) are in decreasing order"

	aConsCell cellsDo: [:c |
		(c car > (c cadr ifNil: [^ self trueValue])) ifFalse: [^ self falseValue]]. 

]

{ #category : #'LISP-functions' }
ELisp >> >= aConsCell [

"(>= NUM1 NUM2 &rest NUMS)
Return t if the arguments (which should be numbers) are in decreasing order, with equal arguments allowed"

	aConsCell cellsDo: [:c |
		(c car >= (c cadr ifNil: [^ self trueValue])) ifFalse: [^ self falseValue]]. 

]

{ #category : #'LISP-special forms' }
ELisp >> LISPand: aConsCell [

"(and &rest CONDITIONS)
Eval CONDITIONS until one of them yields nil, then return nil.
The remaining conditions are not evaluated at all.
If no condition yields nil, return the last arg's value."

	| val |

	(aConsCell ifNil: [^ self trueValue])  doWithCdr: [:form :cdr |
		val := cdr ifNil: [self evalTailObject: form]
			ifNotNil: [self evalObject: form].
		(val asOneLispValue ==  self falseValue) ifTrue: [^ self falseValue]].

	^ val

]

{ #category : #'LISP-special forms' }
ELisp >> LISPor: aConsCell [

"(or &rest CONDITIONS)
Eval CONDITIONS until one of them yields non-nil, then return that value.
The remaining args are not evaluated at all.
If all args return nil, return nil."

	|  val |

	(aConsCell ifNil: [^ self falseValue]) doWithCdr: [:form :cdr | 
		val := cdr ifNil: [self evalTailObject: form]
			ifNotNil: [self evalObject: form multipleValue: true].
		(val asOneLispValue == self falseValue) ifFalse: [^ val]].

	^ self falseValue

]

{ #category : #'LISP-functions' }
ELisp >> append: aConsCell [

"(append &rest LISTS)
Concatenate all the arguments.
The result is a list whose elements are the elements of all LISTS."

	| cons |
	
	aConsCell ifNil: [^ nil].

	aConsCell cdr ifNil: [^ aConsCell car].

	aConsCell doWithCdr: [:ea :cdr |
		ea ifNotNil:[	| e |
			e := (ea isConsCell and: [cdr notNil]) 
					ifTrue: [ea listCopy] ifFalse: [ea].
			cons ifNil: [cons := e] ifNotNil: [cons append: e]]	].
	
	^ cons

]

{ #category : #'LISP-functions' }
ELisp >> aref: aConsCell [

"(aref SEQUENCE N)
Return element of SEQUENCE at index N.
SEQUENCE can be a list or a vector (first index is 0).
More generally it can be any Object (first index is then 1)"

	^ self elt: aConsCell

	
]

{ #category : #'LISP-functions' }
ELisp >> assoc: aConsCell [

"(assoc KEY LIST)
Return non-nil if KEY is `equal' to the car of an element of LIST.
The value is actually the element of LIST whose car is KEY.
Elements of LIST that are not conses are ignored."

	| key |

	key := aConsCell car.
	(aConsCell cadr ifNil: [^ self falseValue]) do: [:elt |
		(elt isConsCell and: [elt car = key]) ifTrue: [^ elt]].

	^ self falseValue

	
]

{ #category : #'LISP-functions' }
ELisp >> assq: aConsCell [

"(assq KEY LIST)
Return non-nil if KEY is `eq' to the car of an element of LIST.
The value is actually the element of LIST whose car is KEY.
Elements of LIST that are not conses are ignored."

	| key |

	key := aConsCell car.
	(aConsCell cadr ifNil: [^ self falseValue]) do: [:elt |
		(elt isConsCell and: [elt car == key]) ifTrue: [^ elt]].

	^ self falseValue

	
]

{ #category : #'LISP-functions-math' }
ELisp >> atan: aConsCell [

"(atan z)
(atan x y)
returns the arctangent of angle z
(when given two arguments angle is x/y with special values for x=0)
"
	
	aConsCell cdr ifNil: [^ aConsCell car arcTan].

	aConsCell car isZero ifTrue: 
		[^ aConsCell cadr >= 0 ifTrue: [0] ifFalse: [Float pi]].

	^ (aConsCell car / aConsCell cadr) arcTan
]

{ #category : #'LISP-functions-predicates' }
ELisp >> atom: aConsCell [

"(atom OBJECT)
Return t if OBJECT is not a cons cell.  This includes nil."

	^ self class test: aConsCell car isConsCell not

]

{ #category : #'LISP-functions' }
ELisp >> caar: aConsCell [

"(caar LIST)
Return the car of the car of LIST"

	^ aConsCell car car car

	
]

{ #category : #'LISP-functions' }
ELisp >> cadr: aConsCell [

"(cadr LIST)
Return the car of the cdr of LIST"

	^ aConsCell car cdr car

	
]

{ #category : #'LISP-functions' }
ELisp >> carSafe: aConsCell [

"(car-safe OBJECT)
Return the car of OBJECT if it is a cons cell, or else nil."

	^ aConsCell car isConsCell ifFalse: [nil] ifTrue: [aConsCell caar]

	
]

{ #category : #'LISP-functions' }
ELisp >> cdar: aConsCell [

"(cdar LIST)
Return the cdr of the car of LIST"

	^ aConsCell car cdar

	
]

{ #category : #'LISP-functions' }
ELisp >> cddr: aConsCell [

"(cddr LIST)
Return the cdr of the cdr of LIST"

	^ aConsCell car cdr cdr

	
]

{ #category : #'LISP-functions-math' }
ELisp >> ceiling: aConsCell [

	| x n |

	x := aConsCell car.	
	n := x ceiling.
	^ LKValues with: n with: x-n
]

{ #category : #'LISP-functions-predicates' }
ELisp >> complexP: aConsCell [

"(complexp NUMBER)
Return #t if NUMBER is complex (if its imaginary part is not O)."

	^ self test: aConsCell car isComplex
]

{ #category : #'LISP-functions' }
ELisp >> concat: aConsCell [

"(concat &rest STRINGS)
Concatenate all STRINGS"

	aConsCell ifNil: [^ ''].
	^ String streamContents: [:str |
			aConsCell 	do: [:s | str nextPutAll: s asString]]

]

{ #category : #'LISP-special forms' }
ELisp >> cond: aConsCell [

"(cond &rest CLAUSES)
Try each clause until one succeeds.
Each clause looks like (CONDITION &rest BODY).  CONDITION is evaluated
and, if the value is non-nil, this clause succeeds:
then the expressions in BODY are evaluated and the last one's
value is the value of the cond-form.
If no clause succeeds, cond returns nil.
If a clause has one element, as in (CONDITION),
CONDITION's value if non-nil is returned from the cond-form."

	aConsCell do: [:clause | | v |
		v := self evalObject: clause first.
		(v == self falseValue) ifFalse: 
		[
			(clause cdr ifNil: [^ v]) 
				doWithCdr: [:c :cdr | 
					cdr ifNil: [^ self evalTailObject: c].
					self evalObject: c]
		]].

	^ self falseValue

]

{ #category : #'LISP-functions' }
ELisp >> cons: aConsCell [
	
"(cons CAR CDR)
Create and return a new cons cell.
CAR and CDR can be any object. The result will be a list if CDR is nil."

	^ ConsCell car: aConsCell car cdr: aConsCell cadr

]

{ #category : #'LISP-functions-predicates' }
ELisp >> consP: aConsCell [

"(consp OBJECT)
Return t if OBJECT is a cons cell"

	^ self class test: aConsCell car isConsCell
]

{ #category : #'LISP-functions' }
ELisp >> copyList: aConsCell [

"(copy-list LIST)
Return a copy of LIST. 
The elements of the copy are not copied themselves"

	^ (aConsCell car ifNil: [^nil]) listCopy

	
]

{ #category : #'LISP-functions' }
ELisp >> copySeq: aConsCell [

"(copy-seq SEQUENCE)
Return a copy of SEQUENCE, a list, vector or string. 
The elements of the copy are not copied themselves"

	(aConsCell car ifNil: [^nil]) isConsCell ifTrue: [^ aConsCell car listCopy].
	^ aConsCell car copy

	
]

{ #category : #'LISP-special forms' }
ELisp >> defvar: aConsCell [

"(defvar SYMBOL [INITVALUE])
Set value for SYMBOL to INITVALUE, only if SYMBOL has no value"

	| sym |
	
	sym := self checkSymbol: aConsCell car.

	(self topmostLisp lispEnvironment bindsSymbol: sym)
		ifFalse: [self topmostLisp symbolValuesAdd: 
					sym -> (self evalObject: aConsCell cadr)].
	^ sym
]

{ #category : #'LISP-functions' }
ELisp >> delete: aConsCell [

"(delete ELT SEQUENCE)
Delete by side effect any occurrences of ELT as a member of SEQUENCE.
The modified SEQUENCE is returned.  Comparison is done with `equal'.
If the first member of SEQUENCE is ELT, there is no way to remove it by side effect; therefore, write `(setq foo (delete element foo))'
to be sure of changing the value of `foo'"

	| list elt cell |

	elt := aConsCell car.
	list := aConsCell cadr ifNil: [^ nil].

	list isCollection ifTrue: [^ list select: [:ea | ea ~= elt]].

	cell := ConsCell new cdr: list.

	[(cell := cell cdr) notNil] whileTrue:
		[[cell cdr notNil and: [cell cadr = elt]] whileTrue: [cell setcdr: cell cddr]].
	
	list car = elt ifTrue: [^ list cdr].
	^ list
]

{ #category : #'LISP-functions-system' }
ELisp >> deleteFile: aConsCell [

	| fname |
	
	fname := FileDirectory default fullNameFor:aConsCell car.

	(FileDirectory default fileExists: fname)
		ifFalse: [self lispError: 'no such file: ', fname].

	FileDirectory deleteFilePath: fname.
	^ self trueValue
]

{ #category : #'LISP-functions' }
ELisp >> delq: aConsCell [

"(delq ELT SEQUENCE)
Delete by side effect any occurrences of ELT as a member of SEQUENCE.
The modified SEQUENCE is returned.  Comparison is done with `eq'.
If the first member of SEQUENCE is ELT, there is no way to remove it by side effect; therefore, write `(setq foo (delq element foo))'
to be sure of changing the value of `foo'"

	| list elt cell |

	elt := aConsCell car.
	list := aConsCell cadr ifNil: [^ nil].

	list isCollection ifTrue: [^ list select: [:ea | ea ~~ elt]].

	cell := ConsCell new cdr: list.

	[(cell := cell cdr) notNil] whileTrue:
		[[cell cdr notNil and: [cell cadr == elt]] whileTrue: [cell setcdr: cell cddr]].
	
	list car = elt ifTrue: [^ list cdr].
	^ list
]

{ #category : #'LISP-special forms' }
ELisp >> do: aConsCell [

"(do ((<variable1> <init1> <step1>) ...)
	  (<test> <expression> ...)
	      <command> ...)"

	| sublisp varspecs test expression command |

	varspecs := aConsCell car.
	test := aConsCell second car.
	expression := aConsCell second cdr.
	command := aConsCell nthcdr: 2.

	sublisp := self subLisp: #do form: aConsCell body: command. 
	
	varspecs ifNotNil:
	[
		varspecs do: [:spec |
		sublisp symbolValuesAdd: (sublisp checkSymbol: spec car) -> (sublisp evalObject: spec second)]
	].

	[(sublisp evalObject: test) == self falseValue]
	whileTrue:
	[
		command ifNotNil: [command do: [:form | sublisp evalObject: form]].
		varspecs ifNotNil:
		[
			(varspecs collect: [:spec | 
				spec car -> (sublisp evalObject: (spec third ifNil: [spec car]))	]) 
			do: [:v | sublisp lispEnvironment addSymbolValue: v]
		]
	].

	(expression ifNil: [^ nil]) 
		doWithCdr: [:c :cdr | 
			cdr ifNil: [^ sublisp evalTailObject: c].
			sublisp evalObject: c]


]

{ #category : #'LISP-special forms' }
ELisp >> dolist: aConsCell [

"(dolist (VAR LIST [RESULT]) &rest BODY)
Evaluate BODY for each VAR in LIST, then evaluate RESULT and return the value. If no RESULT argument is given, return nil."

	| var list result body sublisp |

	var := aConsCell caar.
	list := self evalObject: aConsCell car cadr.
	result := aConsCell car nth: 2 ifAbsent: [nil].
	body := aConsCell cdr.

	list ifNil: [^ self evalObject: result multipleValue: true].

	sublisp := self subLisp: #dolist form: aConsCell body: body. 

	list do: [:v |
		sublisp checkSymbol: var.
		sublisp symbolValuesAdd: var -> v.
		body do: [:form |
			sublisp evalObject: form]].

	^ self evalObject: result multipleValue: true

]

{ #category : #'LISP-special forms' }
ELisp >> dotimes: aConsCell [

" (dotimes (VAR COUNT [RESULT]) &rest BODY)
Evaluate BODY with VAR bound to successive integers running from 0,
inclusive, to COUNT, exclusive.  Then evaluate RESULT to get
the return value (nil if RESULT is omitted)."

	| var n result body sublisp |

	var := aConsCell caar.
	n := self evalObject: aConsCell car cadr.
	result := aConsCell car nth: 2 ifAbsent: [nil].
	body := aConsCell cdr.

	sublisp := self subLisp: #dotimes form: aConsCell body: body. 

	0 to: n-1 do: [:v |
		sublisp checkSymbol: var.
		sublisp symbolValuesAdd: var -> v.
		body do: [:form |
			sublisp evalObject: form]].

	^ self evalObject: result multipleValue: true

]

{ #category : #'LISP-functions-predicates' }
ELisp >> eq: aConsCell [
	
"(eq O1 O2)
Return t if O1 and O2 are the same object."

	| o1 o2 |

	o1 := aConsCell car.
	o2 := aConsCell cadr.

	^ self class test: (o1 == o2
		or: [o1 isLKPrimitive 
				and: [o2 isLKPrimitive]
				and: [o1 selector == o2 selector]])

]

{ #category : #'LISP-functions-predicates' }
ELisp >> equal: aConsCell [
	
"(equal O1 O2)
Return t objects O1 and O2 have similar structure and contents."

	^ self class test: aConsCell car = aConsCell cadr

]

{ #category : #'LISP-functions-predicates' }
ELisp >> evenP: aConsCell [

"(evenp NUMBER)
Return #t if NUMBER is even."

	^ self class test: aConsCell car even


]

{ #category : #'LISP-functions-system' }
ELisp >> fileExistsP: aConsCell [

	^ self test: (FileDirectory default fileExists: 
					(FileDirectory default fullNameFor:aConsCell car))
]

{ #category : #'LISP-functions-math' }
ELisp >> floor: aConsCell [

	| x n |

	x := aConsCell car.	
	n := x floor.
	^ LKValues with: n with: x-n
]

{ #category : #'LISP-special forms' }
ELisp >> fork: aConsCell [

	[self subLisp evalTailObject: aConsCell car] fork.
	^ self trueValue
]

{ #category : #'LISP-functions' }
ELisp >> gcd: aConsCell [

"(gcd n1 ...)
Returns the greatest common divisor of its arguments"

	| n |
	n := aConsCell car ifNil: [^ 0].

	aConsCell cdr do: [:m | n := n gcd: m].
	^ n
	


]

{ #category : #'LISP-functions' }
ELisp >> gensym: aConsCell [

"(gensym [PREFIX])
Generate a new uninterned symbol.
Its name is made by appending a number to PREFIX, default is 'g'"

	| sym uIndexBinding uIndex |

	uIndexBinding := environment symbolValueBinding: #'*u-index*'.
	uIndexBinding value: uIndexBinding value + 1.
	uIndex := uIndexBinding value.
	sym := self unintern: (aConsCell car ifNil: ['g']), uIndex asString n: uIndex.

	uninternedSymbols add: sym.
	^ sym
	 
]

{ #category : #GUI }
ELisp >> guiColor [

	^ (Color r: 0.0 g: 0.452 b: 0.677) lighter
	
]

{ #category : #'LISP-functions' }
ELisp >> identity: aConsCell [

"(identity ARG)
Return ARG itself, unchanged"

	^ aConsCell car
]

{ #category : #'LISP-special forms' }
ELisp >> if: aConsCell [

"(if COND THEN &rest ELSE)
If COND yields non-nil, do THEN, else do ELSE
Returns the value of THEN or the value of the last of the ELSE's.
If COND yields nil and there is no ELSE, return nil."

	^ ((self evalObject: (aConsCell nth: 0)) == self falseValue)
		ifFalse: [self evalTailObject: (aConsCell nth: 1)]
		ifTrue: [(aConsCell nthCell: 2 ifAbsent: [^ nil])
					doWithCdr: [:c :cdr | 
						cdr ifNil: [^ self evalTailObject: c].
						self evalObject: c]]

]

{ #category : #'private - symbols' }
ELisp >> initialize [

	super initialize.
	uninternedSymbols := WeakSet new
]

{ #category : #'LISP-functions-predicates' }
ELisp >> integerP: aConsCell [

"(integerp OBJECT)
Return #t if OBJECT is an Integer."

	^ self test: aConsCell car isInteger


]

{ #category : #'LISP-functions' }
ELisp >> intern: aConsCell [

"(intern STRING)
Return the symbol with name STRING"

	^ aConsCell car asSymbol

	
]

{ #category : #'private - subclasses may implement' }
ELisp >> lambdaForm: aSymbol withArgsAndBody: aConsCell [

	"this implementation relies on the Lisp code in library #argumentsList (see class-side) to redefine all supported arg list keywords (&key, &aux etc.) in terms of &rest and &optional only"

	(aConsCell car notNil
	and: [self class wantsFullArgumentsListsSupport]
	and: [(self fboundp: #'deploy-arguments-list' inCons) = self trueValue])
		ifFalse: [^ ConsCell car: aSymbol cdr: aConsCell ].

	aConsCell car detect: [:form | 
		form isConsCell
		or: [form first = $&
			 and: [(#(#'&rest' #'&body' #'&optional') identityIncludes: form) not]]]
		ifNone: [^ ConsCell car: aSymbol cdr: aConsCell ].

	^ self evalObject: ((ConsCell car: #'deploy-arguments-list') 
							addLast: aSymbol;
							append: aConsCell)
			 multipleValue: true.

]

{ #category : #'LISP-functions' }
ELisp >> last: aConsCell [

"(last X [N])
Return the last link of the list X.  Its car is the last element.
If X is nil, return nil.
If N is non-nil, return the Nth-to-last link of X.
If N is bigger than the length of X, return X."

	| n |

	aConsCell car ifNil: [^ nil].
	(n := aConsCell cadr) ifNil: [^ aConsCell car last]
		ifNotNil: [ | len |
					len := aConsCell length.
					^ aConsCell car nthcdr: ((len - n + 1) max: 0)]
	
]

{ #category : #'LISP-functions' }
ELisp >> lcm: aConsCell [

"(lcm n1 n2)
Returns the least common multiple of its arguments"

	aConsCell car ifNil: [^ 1].
	aConsCell cdr cadr ifNotNil: [self lispError: 'too many arguments for lcm'].
	"to be fixed... "	

	^ ((self * aConsCell) // (self gcd: aConsCell)) abs




]

{ #category : #'LISP-functions' }
ELisp >> length: aConsCell [

"(length SEQUENCE)
Return the length of vector, list or string SEQUENCE."

	(aConsCell car isString or: [aConsCell car isArray])
		ifTrue: [^ aConsCell car size].
	
	^ (aConsCell car ifNil: [^ 0]) length
]

{ #category : #'LISP-functions-predicates' }
ELisp >> listP: aConsCell [

"(listp OBJECT)
Return #t if OBJECT is a list. "

	aConsCell ifNil: [self lispError: 'one argument is required'].
	aConsCell car ifNil: [^ self trueValue].
	^ self class test: (aConsCell car isConsCell and: [aConsCell car isList])
]

{ #category : #'LISP-functions-predicates' }
ELisp >> lowerCaseP: aConsCell [

"(lower-case-p CHARACTER)
Return #t if CHARACTER is a lower case letter"

	aConsCell car isCharacter ifFalse: [self lispError: 'character expected'].
	^ self class test: aConsCell car isLowercase
]

{ #category : #'LISP-functions' }
ELisp >> makeSymbol: aConsCell [

"(make-symbol STRING)
Return a newly allocated uninterned symbol whose name is STRING"

	| n sym |

	n := 0.
	[sym isNil or: [uninternedSymbols identityIncludes: sym]]
		whileTrue: [sym := self unintern: aConsCell car n: (n := n+1)].
	uninternedSymbols add: sym.
	^ sym
	 

	
]

{ #category : #'LISP-functions' }
ELisp >> mapcar: aConsCell [

"(mapcar FUNCTION SEQUENCE)
Apply FUNCTION to each element of SEQUENCE, and make a list of the results.
The result is a list just as long as SEQUENCE.
SEQUENCE may be a list, a vector, a string or any Collection"

	| fcell slot seq |

	fcell := 	(ConsCell car: aConsCell car) cdr: (slot := (ConsCell new)).

	(seq := aConsCell cadr ifNil: [^ nil]) isConsCell ifTrue:
	[
		^ seq collect: [:cell | 
				slot setcar: cell.
				self funcall: fcell]
	].

	^ (seq collect: [:each | slot setcar: each. self funcall: fcell]) asArray asConsList

]

{ #category : #'LISP-functions' }
ELisp >> max: aConsCell [

"(max &rest NUMBERS)
Returns the minimum of NUMBERS"

	^ (aConsCell ifNil: [self lispError: 'At least one argument expected'])
		topForms max


]

{ #category : #'LISP-functions' }
ELisp >> member: aConsCell [

"(member ELT LIST)
Return non-nil if ELT is an element of LIST.  
Comparison is done with equal.
The returned value is the tail of LIST whose car is ELT."

	aConsCell cadr ifNil: [^ self falseValue].
	aConsCell cadr cellsDo: [:cell | cell car = aConsCell car ifTrue: [^ cell]].
	^ self falseValue
]

{ #category : #'LISP-functions' }
ELisp >> memq: aConsCell [

"(memq ELT LIST)
Return non-nil if ELT is an element of LIST.  
Comparison is done with eq.
The returned value is the tail of LIST whose car is ELT."

	aConsCell cadr ifNil: [^ self falseValue].
	aConsCell cadr cellsDo: [:cell | cell car == aConsCell car ifTrue: [^ cell]].
	^ self falseValue
]

{ #category : #'LISP-functions' }
ELisp >> min: aConsCell [

"(min &rest NUMBERS)
Returns the minimum of NUMBERS"

	^ (aConsCell ifNil: [self lispError: 'At least one argument expected'])
		topForms min.


]

{ #category : #'LISP-special forms' }
ELisp >> multipleValueProg1: aConsCell [

"(multiple-value-prog1 FIRST &rest BODY)
Eval FIRST and BODY sequentially; return the values from FIRST"

	| val |
	val := self evalToValues: aConsCell first.
	(aConsCell cdr ifNil: [^ val]) do: [:form | self evalObject: form].
	^ val
]

{ #category : #'LISP-functions-predicates' }
ELisp >> nEqual: aConsCell [
	
"(n-equal NUM1 NUM2 &rest NUMS)
Return t if the arguments (which should be numbers) are equal"

	aConsCell do: [:ea |
		(ea isNumber or: [ea isComplex]) 
			ifFalse: [^ self lispError: 'number expected']].

	aConsCell cellsDo: [:c |
		(c car = (c cadr ifNil: [^ self trueValue])) ifFalse: [^ self falseValue]]. 


]

{ #category : #'LISP-functions' }
ELisp >> nconc: aConsCell [

"(nconc &rest LISTS)
Concatenate any number of LISTS by altering them.
Only the last argument is not altered, and need not be a list."

	| i lists |
	
	lists := ConsCell new.
	(aConsCell ifNil: [^ nil]) do: [:each | each ifNotNil: [lists addLast: each]].
	lists := lists cdr ifNil: [^ nil].

	i := 0.
	[true] whileTrue:
	[
		(lists nth: i) last 
			setcdr: (lists nth: i+1 ifAbsent: [^ lists car]).
		i := i + 1
	]	


]

{ #category : #'LISP-functions' }
ELisp >> newline: aConsCell [

"(newline [port])
Writes an end of line to port."

	| port |

	port := aConsCell car. 
	(port isNil or: [port == self trueValue]) ifTrue: [port := self standardOutput]. 	port stream cr.
	port endEntry.
	^ self trueValue
]

{ #category : #'LISP-functions-predicates' }
ELisp >> not: aConsCell [

"(not OBJECT)
Return t if OBJECT is false."

	^ self class test: aConsCell car == self falseValue
]

{ #category : #'LISP-functions' }
ELisp >> nreverse: aConsCell [

"(nreverse LIST)
Reverse LIST by modifying cdr pointers.
Returns the beginning of the reversed list."

	| lastCell |

	(aConsCell car ifNil: [^ nil]) cells do: [:cell |
		cell setcdr: lastCell.
		lastCell := cell].

	^ lastCell 
]

{ #category : #'LISP-functions' }
ELisp >> nth: aConsCell [

"(nth N LIST)
Return the Nth element of LIST.
N counts from zero.  If LIST is not that long, nil is returned."

	^ aConsCell cadr nth: aConsCell car

	
]

{ #category : #'LISP-functions' }
ELisp >> nthcdr: aConsCell [

"(nthcdr N LIST)
Return the Nth cons cell in LIST.
For example, (nthcdr 2 (list 1 2 3 4 5)) returns (3 4 5)"

	^ aConsCell cadr nthcdr: aConsCell car

	
]

{ #category : #'LISP-functions-predicates' }
ELisp >> null: aConsCell [

"(null OBJECT)
Return t if OBJECT is nil."

	^ self class test: aConsCell car isNil
]

{ #category : #'LISP-functions-predicates' }
ELisp >> numberP: aConsCell [

"(numberp OBJECT)
Return #t if OBJECT is a number."

	^ self class test: (aConsCell car isNumber or: [aConsCell car isComplex])
".. we need the double test for Squeak 3.8 where a Complex answers false to #isNumber"
]

{ #category : #'LISP-functions' }
ELisp >> numberTOstring: aConsCell [

"(number->string NUMBER [BASE])
Returns as a string an external representation of NUMBER in the given BASE.
BASE is either 2, 8, 10, or 16. If omitted, BASE defaults to 10. "

	| n base |

	n := aConsCell car.
	base := aConsCell cadr ifNil: [10].

	n isComplex ifTrue: [^ self class complexString: n base: base].
	^ n printStringBase: base
]

{ #category : #'LISP-functions-predicates' }
ELisp >> oddP: aConsCell [

"(oddp NUMBER)
Return #t if NUMBER is odd."

	^ self class test: aConsCell car odd
]

{ #category : #'LISP-functions-system' }
ELisp >> pathNameDelimiter: ignored [

"(path-name-delimiter)
return the directory separator character"

	^ FileDirectory activeDirectoryClass pathNameDelimiter
]

{ #category : #'LISP-functions' }
ELisp >> peekChar: aConsCell [

"(peek-char &optional STREAM)
Returns the next character available from STREAM, without updating the STREAM to point to the following character. If no more characters are available, an end of file object is returned."

	| str |  

	(str := aConsCell car ifNil: [self standardInput]) isLKIOPort 
		ifTrue: 
		[
			str atEnd ifTrue: [^ LKIOPort eof].
			^ str stream peek
		].

	^ str asString first
	
	
	
]

{ #category : #'LISP-functions-system' }
ELisp >> platformName: unused [

"(platform-name)
Returns the name of the current operating system"

	^ SmalltalkImage current platformName
]

{ #category : #'LISP-functions-math' }
ELisp >> primeP: aConsCell [

"(primep NUMBER)
Return #t if NUMBER is prime."

	^ self test: (aConsCell car isPrime)
]

{ #category : #'LISP-functions' }
ELisp >> prin1: aConsCell [

"(prin1 FORM &optional STREAM)
Write to STREAM a string representing FORM, readable whenever possible"

	| stream port |

	stream := (port := aConsCell cadr ifNil: [self standardOutput]) stream.
	aConsCell car printOn: stream forLisp: self.
	port endEntry.
	^ aConsCell car
]

{ #category : #'LISP-functions' }
ELisp >> prin1ToString: aConsCell [

"(prin1-to-string FORM)
Return a string representing FORM, readable whenever possible"

	^ aConsCell car printStringForLisp: self
]

{ #category : #'LISP-functions' }
ELisp >> princ: aConsCell [

"(princ FORM &optional STREAM)
Write to STREAM a string representing FORM"

	| port |
	
	(port := aConsCell cadr ifNil: [self standardOutput])
		 stream nextPutAll: aConsCell car asString.
	port endEntry.
	^ aConsCell car
]

{ #category : #'LISP-functions' }
ELisp >> print: aConsCell [

"(print FORM &optional STREAM)
Write to STREAM a string representing FORM, readable whenever possible, preceded by a newline and followed by a space"

	| stream port |

	stream := (port := aConsCell cadr ifNil: [self standardOutput]) stream.
	stream cr.
	aConsCell car printOn: stream forLisp: self.
	stream space.
	port endEntry.
	^ aConsCell car
]

{ #category : #'private - symbols' }
ELisp >> printSymbol: aSymbol on: aStream [

	| sym |

	sym := self uninternedSymbol: aSymbol.

	(sym isAllLetters
		or: [([self reader read: (ReadStream on: sym)] 
				on: Error do: [nil]) == sym])
	ifFalse: [^ aStream nextPut: $| ;nextPutAll: sym; nextPut: $|].

	aStream nextPutAll: sym

]

{ #category : #'LISP-special forms' }
ELisp >> prog1: aConsCell [

"(prog1 FIRST &rest BODY)
Eval FIRST and BODY sequentially; return the value from FIRST"

	| val |
	val := self evalObject: aConsCell first.
	(aConsCell cdr ifNil: [^ val]) do: [:form | self evalObject: form].
	^ val
]

{ #category : #'LISP-special forms' }
ELisp >> prog2: aConsCell [

"(prog1 FIRST SECOND &rest BODY)
Eval FIRST, SECOND and BODY sequentially; return the value from SECOND"

	| val |

	self evalObject: aConsCell first.
	val := self evalObject: aConsCell second.
	((aConsCell nthcdr: 2) ifNil: [^ val]) do: [:form | self evalObject: form].
	^ val
]

{ #category : #'LISP-functions-predicates' }
ELisp >> rationalP: aConsCell [

"(rationalp NUMBER)
Return #t if NUMBER is rational."

	^ self test: (aConsCell car isInteger or: [aConsCell car isFraction])
]

{ #category : #'LISP-functions' }
ELisp >> readChar: aConsCell [

"(read-char &optional STREAM)
Inputs one character from STREAM and returns it as a character object. The corresponding output function is write-char. "

	| stream stdin | 

	stdin := self standardInput.
	(stream := aConsCell car) ifNil: [stream := stdin].

	(stream == stdin and: [stream atEnd]) "weird logic,to be corrected.."
		ifTrue: [
			self focusedREPL 
				ifNil: [self interactivelyFeedInputStream]        "no GUI"
				ifNotNil: ["we have a GUI, just wait for input"
					"first make sure there is no pending output:"
					self standardOutput endEntry; force. 
					"now wait"
					[stream atEnd] whileTrue: [World doOneCycle]]].

	stream isLKIOPort 
		ifTrue: [^ stream atEnd 
					ifTrue: [LKIOPort eof] ifFalse: [stream stream next]]
		ifFalse: [^ stream asString first]
	
]

{ #category : #'LISP-functions-predicates' }
ELisp >> realP: aConsCell [

"(rationalp NUMBER)
Return #t if NUMBER is real (that is, not a complex number)."

	^ self test: aConsCell car isNumber
]

{ #category : #'LISP-functions' }
ELisp >> reverse: aConsCell [

"(reverse LIST)
Reverse LIST, copying.  Returns the beginning of the reversed list."

	^ self nreverse: (aConsCell car ifNil: [^ nil]) listCopy inCons
]

{ #category : #'LISP-functions-math' }
ELisp >> round: aConsCell [

	| x n r |

	x := aConsCell car.	
	n := x rounded.
	(((r := x-n) abs = 0.5)
		and: [n odd]) ifTrue: [n := n - n sign. r := r negated].
	^ LKValues with: n with: r
]

{ #category : #'LISP-functions' }
ELisp >> sconcat: aConsCell [

"(sconcat SYMBOLS)
Concatenate all SYMBOLS into one and return it"

	^ (String streamContents: [:str |
			aConsCell do: [:s | str nextPutAll: s asString]]) asSymbol
]

{ #category : #'LISP-functions' }
ELisp >> setcar: aConsCell [

"(setcar CELL OBJECT)
Set the car of CELL to be OBJECT.  Returns OBJECT."

	| o |
	aConsCell car setcar: (o := aConsCell cadr).
	^ o

	
]

{ #category : #'LISP-functions' }
ELisp >> setcdr: aConsCell [

"(setcdr CELL OBJECT)
Set the cdr of CELL to be OBJECT.  Returns OBJECT."

	| o |
	aConsCell car setcdr: (o := aConsCell cadr).
	^ o


	
]

{ #category : #'LISP-functions' }
ELisp >> sleepFor: aConsCell [

"(sleep-for seconds &optional millisec)"

	(Delay forMilliseconds: (aConsCell car * 1000) + (aConsCell cadr ifNil: [0])) wait.
	^ nil
]

{ #category : #'LISP-functions-predicates' }
ELisp >> stringP: aConsCell [

"(stringp OBJECT)
Return t if OBJECT is a String."

	^ self class test: (aConsCell car isString and: [aConsCell car isSymbol not])
]

{ #category : #'LISP-functions' }
ELisp >> stringTOlist: aConsCell [

	^ aConsCell car asArray asConsList
]

{ #category : #'LISP-functions' }
ELisp >> stringTOnumber: aConsCell [

"(string->number STRING [BASE])
Returns a number expressed by STRING. BASE must be either 2, 8, 10, or 16. If supplied, BASE may be overridden by an explicit radix prefix in string. If BASE is not supplied, then it defaults to 10. If STRING is not a syntactically valid notation for a number, returns #f."

	| base string n |

	string := aConsCell car.
	base := aConsCell cadr ifNil: [10].

	string ifEmpty: [^ self falseValue].

	(string first == $# 
		and: [string size >= 2]
		and: [#($o $O $x $X $b $B $r $R $d $i) identityIncludes: string second])
	ifTrue: 
	[[ ^ self reader read: (ReadStream on: string)] 
		on: Error do: [^self falseValue]].
	
	n := [self reader token parse: aConsCell car base: base] 
			on: Error do: [^self falseValue].
	n isSymbol ifTrue: [^self falseValue].

	^ n



]

{ #category : #'LISP-functions' }
ELisp >> substring: aConsCell [

"(substring STRING START [END])
Return the substring of STRING from START to END.
If END is omitted, it defaults to the length of the string.
If START or END is negative, it counts from the end.
"

	| string beg end |

	string := aConsCell car.
	beg := aConsCell cadr.
	beg < 0 ifTrue: [beg := string size + beg].
	end := aConsCell cddr car ifNil: [string size].
	end  < 0 ifTrue: [end := string size + end].

	^ string copyFrom: beg + 1 to: end
]

{ #category : #'LISP-functions-predicates' }
ELisp >> symbolP: aConsCell [

"(symbolp OBJECT)
Return t if OBJECT is a Symbol."

	^ self class test: aConsCell car isSymbol
]

{ #category : #'LISP-functions-system' }
ELisp >> systemPath: aConsCell [

"(system-path PATH)
Return a version of PATH (a string) suitable for the current operating system.
For example, on linux all #\ and #\: are replaced with #/
PATH should be relative"

	| sep path |

	path := aConsCell car.
	sep := FileDirectory slash.
	#('\' '/' ':') do: [:s | path := path copyReplaceAll: s with: sep].

	(FileDirectory slash == $:) ifTrue: "mac OS"
	[
		path first == $: ifTrue: [path := path allButFirst].
		aConsCell car first isAlphaNumeric ifTrue: [path := ':', path].
	].

	^ path
]

{ #category : #'LISP-functions-math' }
ELisp >> truncate: aConsCell [

	| x n |

	x := aConsCell car.	
	n := x truncated.
	^ LKValues with: n with: x-n
]

{ #category : #'private - symbols' }
ELisp >> unintern: aSymbol n: aNumber [

	^ ('uninterned:::n', aNumber asString, ':::', aSymbol) asSymbol
]

{ #category : #'private - symbols' }
ELisp >> uninternedSymbol: aSymbol [ 

	(uninternedSymbols identityIncludes: aSymbol)
		ifFalse: [^ aSymbol].

	^ (aSymbol subStrings: ':') last asSymbol


]

{ #category : #'LISP-functions-predicates' }
ELisp >> upperCaseP: aConsCell [

"(upper-case-p CHARACTER)
Return #t if CHARACTER is an upper case letter"

	aConsCell car isCharacter ifFalse: [self lispError: 'character expected'].
	^ self class test: aConsCell car isUppercase
]

{ #category : #'LISP-functions' }
ELisp >> vectorTOlist: aConsCell [

"(vector-to-list VECTOR)
Returns a list with the elements of VECTOR"

	^ aConsCell car asConsList

]

{ #category : #'LISP-special forms' }
ELisp >> while: aConsCell [

"(while TEST &rest BODY)
If TEST yields non-nil, eval BODY and repeat until TEST returns nil."

	^ [(self evalObject: aConsCell first) == self falseValue]
		whileFalse: [(aConsCell nthCell: 1) do: [:form | self evalObject: form]]
]

{ #category : #'LISP-functions-predicates' }
ELisp >> zeroP: aConsCell [

"(zerop NUMBER)
Test weither NUMBER is 0."

	^ self class test: aConsCell car isZero
]
