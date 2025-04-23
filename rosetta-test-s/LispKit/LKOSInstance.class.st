"
Implements LKOS, the LispKit Object System, very directly ported from STklos (version 0.82) by Erick Gallesio:
http://stklos.net

This class does the job of the C code in STklos (used for bootstrapping the system and defining a few primitives). 

The Scheme counterpart lives in file 'ulisp/lkos/lkos.scm'
 
"
Class {
	#name : #LKOSInstance,
	#superclass : #Object,
	#instVars : [
		'iClass',
		'iSlots',
		'iType',
		'iAccessors',
		'lisp'
	],
	#classVars : [
		'NextMethodPrimitive',
		'SlotCpl',
		'SlotDirectMethods',
		'SlotDirectSlots',
		'SlotDirectSubclasses',
		'SlotDirectSupers',
		'SlotGenericFunction',
		'SlotGettersNSetters',
		'SlotMethods',
		'SlotName',
		'SlotNfields',
		'SlotProcedure',
		'SlotRedefined',
		'SlotSlots',
		'SlotSpecializers'
	],
	#category : #'LispKit-LKOS'
}

{ #category : #'as yet unclassified' }
LKOSInstance class >> allocateInstance: class forLisp: aLisp [

	^ self makeInstanceClass: class
		size: (class iSlots at: SlotNfields)
		type: ((class iSlots at: SlotName) caseOf: {
                   		[#'<generic>'] -> [#generic] .
                 		[#'<simple-method>'] -> [#'simple-method'] . 
                 		[#'<accessor-method>'] -> [#'accessor-method'] 
					} otherwise: [#instance])
		lisp: aLisp
]

{ #category : #'as yet unclassified' }
LKOSInstance class >> basicComputeCpl: supers res: aConsCell [
"
static SCM basic:=compute:=cpl(SCM supers, SCM res)
{
  return NULLP(supers) ? 
    	     STk:=reverse(res) :
             basic:=compute:=cpl(INST:=SLOT(CAR(supers), S:=direct:=supers),
			       STk:=cons(CAR(supers), res));
}
"

	supers ifNil: [^ aConsCell]. "reversed ?"

	^ self basicComputeCpl: (supers car iSlots at: SlotDirectSupers) 
		res: (aConsCell append: supers car inCons)

]

{ #category : #'as yet unclassified' }
LKOSInstance class >> basicComputeSlots: dslots cpl: aConsCell [
"
static SCM basic:=compute:=slots(SCM slots, SCM cpl)
{
  for (cpl = CDR(cpl); !NULLP(cpl); cpl = CDR(cpl))
    slots = STk:=append2(INST:=SLOT(CAR(cpl), S:=direct:=slots), slots);

  return slots;
}

"
	| cpl slots |

	cpl := aConsCell.
	slots := dslots.

	[(cpl := cpl cdr) notNil] whileTrue:
	[
		| nslots |
		nslots := cpl car iSlots at: SlotDirectSlots.
		nslots ifNotNil: [slots := nslots copy append2: slots]
	].

	^ slots
]

{ #category : #'as yet unclassified' }
LKOSInstance class >> basicMakeClass: zeClass name: symb dsupers: dsupers dslots: dslots lisp: aLisp [

	^ self new basicMakeClass: zeClass name: symb dsupers: dsupers dslots: dslots lisp: aLisp

]

{ #category : #'as yet unclassified' }
LKOSInstance class >> class: aSymbol inLisp: aLisp [

	^ aLisp symbolValue: aSymbol 
		ifNone: [self error: 'LKOS class ', aSymbol, ' is undefined !']
]

{ #category : #'as yet unclassified' }
LKOSInstance class >> computeGettersNSetters: slots [ 
"
static SCM compute:=getters:=n:=setters(SCM slots)
{
  SCM res = STk:=nil;
  int i   = 0;

  /* Build a kind of A-list which is something like 
   *     ( .... (slot-name #f . 3) ... )
   * where #f is the slot initialization function and 3 is the offset of a slot
   * in a the vector of slots 
   */
  for (  ; !NULLP(slots); slots = CDR(slots)) 
    res = STk:=cons(STk:=cons(CAR(slots),
			    STk:=cons(STk:=false, MAKE:=INT(i++))),
		   res);
  return res;
}

"
	| i |

	i := 0. "-1 ?"

	^ (slots ifNil: [^ nil]) collect: [:ea | i := i + 1. {ea . false} asConsList append: i]
]

{ #category : #'as yet unclassified' }
LKOSInstance class >> initialize [

	"LKOSInstance initialize"

	SlotName := 1.
	SlotDirectSupers := 2.
	SlotDirectSlots := 3.
	SlotDirectSubclasses := 4.
	SlotDirectMethods := 5.
	SlotCpl := 6.
	SlotSlots := 7.
	SlotNfields := 8.
	SlotGettersNSetters := 9. 
	SlotRedefined := 10.

	SlotMethods := 2.

	SlotGenericFunction := 1.
	SlotSpecializers := 2.
	SlotProcedure := 3.

	NextMethodPrimitive := LKPrimitive new selector: #nextMethod:
]

{ #category : #'as yet unclassified' }
LKOSInstance class >> makeInstanceClass: iClass size: n type: iType lisp: aLisp [

	^ self new makeInstanceClass: iClass size: n type: iType lisp: aLisp

]

{ #category : #accessing }
LKOSInstance >> accessors [

	^ iAccessors 
]

{ #category : #accessing }
LKOSInstance >> accessors: aConsCell [

	iAccessors := aConsCell
]

{ #category : #testing }
LKOSInstance >> applyInTailTo: aConsCell inLisp: aLisp asMacro: ignored [

	| args |

	args := aLisp evalList: aConsCell.

	^ (self procedureForArguments: args lisp: aLisp)
		applyInTailTo: aConsCell inLisp: aLisp asMacro: true

]

{ #category : #testing }
LKOSInstance >> applyTo: aConsCell inLisp: aLisp asMacro: mflag [

	| args |

	args := aLisp evalList: aConsCell.

	^ (self procedureForArguments: args lisp: aLisp)
		applyTo: args inLisp: aLisp asMacro: true

]

{ #category : #'as yet unclassified' }
LKOSInstance >> basicMakeClass: zeClass name: name dsupers: dsupers dslots: dslots lisp: aLisp [

	| cpl slots gns |

	self makeInstanceClass: zeClass size: 10 type: #instance lisp: aLisp.

	iSlots at: SlotName put: name.
	iSlots at: SlotDirectSupers put: dsupers.
	iSlots at: SlotDirectSlots put: dslots.
	iSlots at: SlotDirectSubclasses put: nil.
	iSlots at: SlotDirectMethods put: nil.

	cpl := self class basicComputeCpl: dsupers res: self inCons.
	slots := self class basicComputeSlots: dslots cpl: cpl.
	gns := self class computeGettersNSetters: slots.

	iSlots at: SlotCpl put: cpl.
	iSlots at: SlotSlots put: slots.
	iSlots at: SlotNfields put: (slots ifNil: [0] ifNotNil: [slots length]).
	iSlots at: SlotGettersNSetters put: gns.
	iSlots at: SlotRedefined put: lisp falseValue.

	iAccessors := zeClass iSlots at: SlotGettersNSetters.

	dsupers ifNil: [^ self].

	dsupers do: [:ea | 
		| easlots |
		easlots := ea iSlots at: SlotDirectSubclasses.
		easlots ifNotNil: [easlots append: self inCons]
			ifNil: [ea iSlots at: SlotDirectSubclasses put: self inCons]].
"
static SCM basic:=make:=class(SCM classe, SCM name, SCM dsupers, SCM dslots)
{
  SCM tmp, z, cpl, slots, g:=n:=s;

  /* Allocate one instance */
  z = make:=instance(classe, NUMBER:=OF:=CLASS:=SLOTS, TYPE:=INSTANCE);

  /* Initialize its slots */
  cpl   = basic:=compute:=cpl(dsupers, LIST1(z));
  slots = basic:=compute:=slots(dslots, cpl);
  g:=n:=s = compute:=getters:=n:=setters(slots);

  INST:=SLOT(z, S:=name)	      	    = name;
  INST:=SLOT(z, S:=direct:=supers)     = dsupers;
  INST:=SLOT(z, S:=direct:=slots)      = dslots;
  INST:=SLOT(z, S:=direct:=subclasses) = STk:=nil;
  INST:=SLOT(z, S:=direct:=methods)    = STk:=nil;
  INST:=SLOT(z, S:=cpl)		    = cpl;
  INST:=SLOT(z, S:=slots)	      	    = slots;
  INST:=SLOT(z, S:=nfields)	    = MAKE:=INT(STk:=int:=length(slots));
  INST:=SLOT(z, S:=getters:=n:=setters) = g:=n:=s;
  INST:=SLOT(z, S:=redefined) 	    = STk:=false;

  /* Don't forget to set the accessors list of the object */
  INST:=ACCESSORS(z) = INST:=SLOT(classe, S:=getters:=n:=setters);
  
  /* Add this class in the direct-subclasses slot of dsupers */
  for (tmp = dsupers; !NULLP(tmp); tmp = CDR(tmp)) {
    INST:=SLOT(CAR(tmp), S:=direct:=subclasses) = 
      STk:=cons(z, INST:=SLOT(CAR(tmp), S:=direct:=subclasses));
  }

  return z;
}

"
]

{ #category : #'high level slots access' }
LKOSInstance >> changeClassFrom: aClass to: bClass [

	| newInstance |

	newInstance := self class allocateInstance: bClass.

	((bClass iSlots at: SlotSlots) collect: [:s | 
		"slot-definition-name"
		s isConsCell ifTrue: [s car] ifFalse: [s]])
	do: [:slotName |
			((self testSlotExistence: slotName) == lisp trueValue) ifTrue:
			[
				| slotValue |
				slotValue := self getSlotValue: slotName.
				(slotValue ~~ LKOSVoid) ifTrue:
					[newInstance setSlotValue: slotName to: slotValue]
			]
			ifFalse:
			[
				| init |
				init := bClass slotInitFunction: slotName.
				init ifNotNil:
				[
					newInstance setSlotValue: slotName
						to: (init applyTo: nil inLisp: lisp asMacro: true)
				]
			]
	].

	self becomeForward: newInstance

"
  (let ((new-instance (allocate-instance new-class ())))
    ;; Initalize the slot of the new instance
    (for-each (lambda (slot)
		(if (slot-exists-using-class? old-class old-instance slot)
		    ;; Slot was present in old instance; set it 
		    (if (slot-bound-using-class? old-class old-instance slot)
			(slot-set-using-class!
			     new-class 
			     new-instance 
			     slot 
			     (slot-ref-using-class old-class old-instance slot)))
		    ;; slot was absent; initialize it with its default value
		    (let ((init (slot-init-function new-class slot)))
		      (if init
			  (slot-set-using-class!
			       new-class 
			       new-instance 
			       slot
			       (apply init '()))))))
	      (map slot-definition-name (class-slots new-class)))


"



]

{ #category : #accessing }
LKOSInstance >> getSlot: anInteger [ 

	^ iSlots at: anInteger



]

{ #category : #'high level slots access' }
LKOSInstance >> getSlotValue: slotName [

	slotName isInteger ifTrue: [^ iSlots at: slotName].

	^ self getSlotValue: slotName fromAccessors: iAccessors

 
]

{ #category : #'high level slots access' }
LKOSInstance >> getSlotValue: slotName fromAccessors: aConsCell [

	| accessors |

	accessors := aConsCell.

	[accessors isNil] whileFalse:
	[
		accessors car car == slotName ifTrue:
		[
			| a |
			a := accessors car cdr cdr.
			a isInteger ifTrue: [^ iSlots at: a].
			^ a car applyTo: self inCons inLisp: lisp asMacro: true
		].
		accessors := accessors cdr
	].

	self error: 'slot missing'

"
   (if (null accessors) 
    (error 'slot missing')
    (if (eq? (caar accessors) slot-name)
      (let ((a (cddar accessors)))
        (if (integer? a)
          (send obj getSlot: a)
          (apply (car a) (list obj))))
      (%get-slot-value-from-accessors (cdr accessors) slot-name obj))))
"
]

{ #category : #accessing }
LKOSInstance >> iClass [

	^ iClass
]

{ #category : #accessing }
LKOSInstance >> iClass: aClass [

	iClass := aClass
]

{ #category : #accessing }
LKOSInstance >> iSlots [

	^ iSlots



]

{ #category : #initializing }
LKOSInstance >> initializeObject: initArgs [

	"called for all newly created instance"

	| getNSet slots slotName slotValue tmp |

	getNSet := iClass iSlots at: SlotGettersNSetters.
	slots := iClass iSlots at: SlotSlots .

	[slots isNil] whileFalse:
	[
		slotName := slots car.
		slotValue := LKOSVoid .
		slotName isConsCell ifTrue:
		[
			tmp := LKOSULisp symbolKeyGet: #':init-keyword'
					plist: slotName cdr
					default: LKOSVoid.
			slotName := slotName car.
			tmp == LKOSVoid ifFalse:
			[
				slotValue := LKOSULisp symbolKeyGet: tmp
						plist: initArgs
						default: LKOSVoid
			]
		].
		slotValue == LKOSVoid ifFalse:
		[	
			self slotSet: slotName to: slotValue 
		]		
		ifTrue:
		[
			tmp := getNSet car cdr car.
			tmp == lisp falseValue ifFalse:
			[
				self setSlotValue: slotName 
					to: (tmp applyTo: self inCons inLisp: lisp asMacro: true)
			]
		].
		getNSet := getNSet cdr.
		slots := slots cdr.
	]

"
	(define (%initialize-object object initargs)
  (if (not (instance? object)) (error 'bad instance'))
  (if (not (or (pair? initargs) (null? initargs)))
    (error 'bad initialization list'))
  (let* ((class (send object iClass))
         (get-n-set (send class getSlot: 'getters-n-setters))
         (slots (send class getSlot: 'slots)))
    (while (not (null? slots))
      (let ((slot-name (car slots))
            (slot-value (void)))
        (if (pair? slot-name)
          (let ((tmp (key-get (cdr slot-name) :init-keyword (void))))
            (set! slot-name (car slot-name))
            (if (not (eq? tmp (void)))
              (setq slot-value (key-get initargs tmp (void))))))
        (if (not (eq? slot-value (void)))
             (slot-set! object slot-name slot-value)
          (let ((tmp (cadar get-n-set)))
            (if tmp 
              (%set-slot-value class object slot-name (apply tmp (list object)))))))
      (set! get-n-set (cdr get-n-set))
      (set! slots (cdr slots))))
  object)
"
]

{ #category : #testing }
LKOSInstance >> isLKOSAccessorMethod [

	^ iType == #'accessor-method'
]

{ #category : #testing }
LKOSInstance >> isLKOSClass [

	^ iType == #class
]

{ #category : #testing }
LKOSInstance >> isLKOSGeneric [

	^ iType == #generic
]

{ #category : #testing }
LKOSInstance >> isLKOSInstance [

	^ true
]

{ #category : #testing }
LKOSInstance >> isLKOSMethod [

	^ iType == #method
		or: [ iType == #'simple-method']
		or: [ iType == #'accessor-method']
]

{ #category : #'LispClosure protocol' }
LKOSInstance >> isLispClosure [

	^ self isLKOSGeneric

]

{ #category : #'as yet unclassified' }
LKOSInstance >> isMoreSpecificThan: aMethod withTypes: argCpls [

	| s1 s2 i |

	s1 := self specializers.
	s2 := aMethod specializers.

	s2 safeLength > s1 safeLength ifTrue: [^ false].
	s1 safeLength > s2 safeLength ifTrue: [^ true].

	i := 1.

	[true] whileTrue:
	[ 
		s1 ifNil: [^ true].
		s2 ifNil: [^ false].
		(s1 car ~~ s2 car) ifTrue: [ | cs1 cs2 |
			cs1 := s1 car.
			cs2 := s2 car.
			(argCpls at: i) do: [:type |
				(cs1 == type) ifTrue: [^ true].
				(cs2 == type) ifTrue: [^ false].
			].
			^ false "should not occur"
		].
		s1 := s1 cdr.
		s2 := s2 cdr.
		i := i + 1
	]
]

{ #category : #testing }
LKOSInstance >> isProcedure [

	^ self isLKOSGeneric
]

{ #category : #'LispClosure protocol' }
LKOSInstance >> lispCode [

	^ '<generic-function>'
]

{ #category : #accessing }
LKOSInstance >> lkosClass: aLisp [

	"we should check weither aLisp is related to lisp" 

	self isLKOSGeneric ifTrue: [LKOSInstance class: #'<procedure>' inLisp: aLisp].

	self testChangeClass.
	^ iClass
]

{ #category : #'as yet unclassified' }
LKOSInstance >> makeInstanceClass: zeClass size: n type: zeType lisp: aLisp [

	iClass := zeClass.
	iSlots := Array new: n withAll: LKOSVoid.
	iType := zeType.
	iAccessors := (zeClass isKindOf: self class) 
						ifTrue: [zeClass iSlots at: SlotGettersNSetters] ifFalse: [nil].
	lisp := aLisp

"
static SCM make:=instance(SCM classe, short size, short type)
{
  SCM z;
  int i;

  NEWCELL(z, instance);
  INST:=NUMBER:=OF:=SLOTS(z) = size;
  INST:=TYPE(z)		  = type;
  INST:=CLASS:=OF(z)	  = classe;
  INST:=ACCESSORS(z)	  = classe? INST:=SLOT(classe, S:=getters:=n:=setters): STk:=nil;
  INST:=SLOTS(z)		  = STk:=must:=malloc(size * sizeof(SCM));
  
  /* Set all the slots to unbound */
  for (i = 0; i < size; i++)
    INST:=SLOT(z, i) = STk:=void;

  return z;
}

"
]

{ #category : #printing }
LKOSInstance >> printOn: aStream [

	aStream
		nextPutAll: '[LKOS '; 
		nextPutAll: iType asString;
		nextPutAll: ' ';
		nextPutAll: (self iSlots at: SlotName) asString;
		nextPut: $]


]

{ #category : #printing }
LKOSInstance >> printOn: aStream forLisp: aLisp [

	aLisp ifNil: [^ self printOn: aStream].
	aLisp evalObject: {#'write-object' . self . LKIOPort output: aStream} asConsList

]

{ #category : #printing }
LKOSInstance >> procedureForArguments: aConsCell lisp: aLisp [

	| argCpls methods applicableMethods |

	methods := (iSlots at: SlotMethods) topForms.

	"short-cut:"
	(methods size = 2
		and: [methods first isLKOSAccessorMethod]
		and: [methods second isLKOSAccessorMethod])
	ifTrue:
	[
		^ ((methods first iSlots at: SlotSpecializers) length = aConsCell length
			ifTrue: [methods first] ifFalse: [methods second])
		iSlots at: SlotProcedure
	].

	argCpls := aConsCell safeTopForms collect: [:ea | 
		((ea lkosClass: aLisp) iSlots at: SlotCpl) topForms].

	applicableMethods := methods  
		select: [:m | | msig applicablep | 
			msig := m iSlots at: SlotSpecializers.
			msig := msig isConsCell ifTrue: [msig safeTopForms] ifFalse: [{msig}].
			applicablep := true.
			msig doWithIndex: [:c :i | 
				applicablep := applicablep and: [i <= argCpls size] 
					and: [c == true       "why not <top> ?"
							or: [(argCpls at: i) identityIncludes: c]]].
			applicablep].

	"to do here: ensure thread safety (copy applicableMethods ?)"
 
	applicableMethods ifEmpty: 
		[self error: '(', (self iSlots at: SlotName) ,') no applicable method found'].

	applicableMethods size > 1 ifTrue:
	[
		applicableMethods := applicableMethods sort: [:m1 :m2 |
			m1 isMoreSpecificThan: m2 withTypes: argCpls].

		"	temporary (not thread-safe):"
		applicableMethods doWithIndex: [:am :i |
			i < applicableMethods size ifTrue:
			[
				| env |
				env := (am iSlots at: SlotProcedure) lispEnvironment.
				env 
					addSymbolValue: #'next-method' -> NextMethodPrimitive;
					addSymbolValue: #'lkos-next-method' -> 
						((applicableMethods at: i + 1) iSlots at: SlotProcedure);
					addSymbolValue: #'lkos-next-method-arguments' -> aConsCell
			]].
	].

	^ applicableMethods first iSlots at: SlotProcedure.


	"to do somewhere: use the MOP and apply-generic"






"
dans vm.c de STKLOS:
===============

	FUNCALL:  /* (int nargs, int tailp) */
{
  switch (STYPE(vm->val)) {

    case tc:=instance: {
      if (PUREGENERICP(vm->val)) {
	SCM *argv = vm->sp+nargs-1;
	SCM methods, nm; 
	
	/* methods is the list of applicable methods. Apply the first
	 * one with the tail of the list as first parameter
	 * (next-method). If methods is STk:=nil, that's because the
	 * no-applicable-method triggered didn't yield an error.  
	 */
	methods = STk:=compute:=applicable:=methods(vm->val, nargs, argv, FALSE);
	if (NULLP(methods)) { vm->val = STk:=void; return; }
	
	/* Place the procedure of the first method in the VAL register and
	 * store the next method in the ``next-method'' variable. 
	 */
	nm       = STk:=make:=next:=method(vm->val, nargs, argv, methods);
	vm->val  = INST:=SLOT(CAR(methods), S:=procedure);
	SET:=NEXT:=METHOD(vm->val, nm);
	/* NO BREAK */
      } else {
	SCM gf, args;

	/* Use the MOP and do the call (apply-generic gf args) */
	args = listify:=top(nargs, vm);
	push(vm->val); 
	push(args);
	vm->val = STk:=lookup(STk:=intern('apply-generic'), vm->current:=module, 
			     &gf, FALSE);
	nargs = 2;
	goto FUNCALL;
      }
    }
"
]

{ #category : #accessing }
LKOSInstance >> setSlot: anInteger to: aValue [

	^ iSlots at: anInteger put: aValue
]

{ #category : #'high level slots access' }
LKOSInstance >> setSlotValue: slotName to: slotValue [

	slotName isInteger ifTrue: [^ iSlots at: slotName put: slotValue].

	^ self setSlotValue: slotName to: slotValue fromAccessors: iAccessors

]

{ #category : #'high level slots access' }
LKOSInstance >> setSlotValue: slotName to: slotValue fromAccessors: aConsCell [

	| accessors |

	accessors := aConsCell.

	[accessors isNil] whileFalse:
	[
		accessors car car == slotName ifTrue:
		[
			| a |
			a := accessors car cdr cdr.
			a isInteger ifTrue: [^ iSlots at: a put: slotValue].
			^ a cadr applyTo: {self . slotValue} asConsList
					inLisp: lisp asMacro: true
		].
		accessors := accessors cdr
	].

	self error: 'slot missing'

"(define (%set-slot-value-from-accessors accessors slot-name obj value)
  (if (null accessors) 
    (error 'slot missing')
    (if (eq? (caar accessors) slot-name)
      (let ((a (cddar accessors)))
        (if (integer? a)
          (send obj setSlot:to: a value)
          (apply (cadr a) (list obj value))))
      (%set-slot-value-from-accessors (cdr accessors) slot-name obj value))))
"
]

{ #category : #'high level slots access' }
LKOSInstance >> slotInitFunction: slotSpec [

	"for iType #class only"

	"
 (define (slot-init-function c s)
  (let ((s (slot-definition-name s)))
    (cadr (assq s (slot-ref c 'getters-n-setters)))))
"

	| slotName getNSet |

	slotName := slotSpec isConsCell ifTrue: [slotSpec car] ifFalse: [slotSpec].
	getNSet := self slotRef: SlotGettersNSetters.

	(getNSet cadr ifNil: [^ lisp falseValue]) do: [:elt |
		(elt isConsCell and: [elt car == slotName]) ifTrue: [^ elt]].

	^ lisp falseValue

]

{ #category : #'high level slots access' }
LKOSInstance >> slotRef: slotName [

	self testChangeClass.
	^ self getSlotValue: slotName
]

{ #category : #'high level slots access' }
LKOSInstance >> slotSet: slotName to: slotValue [

	self testChangeClass.
	self setSlotValue: slotName to: slotValue
]

{ #category : #accessing }
LKOSInstance >> specializers [

	| spec |

	spec := iSlots at: SlotSpecializers.
	spec isConsCell ifTrue: [^ spec] ifFalse: [^ spec inCons].
]

{ #category : #'high level slots access' }
LKOSInstance >> testChangeClass [

"
(define (test-change-class obj)
  (let* ((class (send obj iClass))
         (new-class (send class getSlot: 'redefined)))
    (if new-class
      (change-object-class obj class new-class))))
"
	(iClass iSlots at: SlotRedefined) == lisp falseValue ifTrue: [^ self].
	
	self changeClassFrom: iClass to: (iClass iSlots at: SlotRedefined)
]

{ #category : #'high level slots access' }
LKOSInstance >> testSlotExistence: slotName [
"
(define (test-slot-existence accessors slot-name)
  (if (null? accessors) #f
      (or (eq? (caar accessors) slot-name)
          (test-slot-existence (cdr accessors) slot-name))))
"

	| accessors |

	accessors := iAccessors.

	[accessors isNil] whileFalse:
	[
		accessors caar == slotName ifTrue: [^ lisp trueValue].
		accessors := accessors cdr
	].

	^ lisp falseValue
]
