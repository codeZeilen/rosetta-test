"
This is the unit test for the class ConsCell. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #ConsCellTest,
	#superclass : #TestCase,
	#category : #'LispKit-Tests'
}

{ #category : #'as yet unclassified' }
ConsCellTest >> testAddLast [

	| list1 list2  |

	list1 := #(1 2 3) asCons.
	list2 := #(5 4) asCons.
	self assert: (list1 addLast: list2) = #(1 2 3 (5 4)) asCons.
	self assert: list1= #(1 2 3 (5 4)) asCons.
	self assert: list2 = #(5 4) asCons.
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testAppend [

	| list1 list2  |

	list1 := #(1 2 3) asCons.
	list2 := #(5 4) asCons.

	self assert: (list1 append: list2) == list1.
	self assert: list1= #(1 2 3 5 4) asCons.
	self assert: list2 = #(5 4) asCons.

	self assert: (list1 append: list2) == list1.
	self assert: list1 lispPrintString = '(1 2 3 . #1=(5 4 . #1#))'.
	self assert: list2 lispPrintString = '#1=(5 4 . #1#)'.
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testBindings [

	self assert: (#(lambda () 5) asCons lambdaFormBindingsWith: nil) = #().

	self assert: (#(x y #'&rest' z) asCons 
					bindingsWithArguments: #(1 2 3 4) asCons) 
					= {#x->1. #y->2. #z->#(3 4) asCons}.

	self assert: ((ConsCell car: #x cdr: #z) 
					bindingsWithArguments: #(1 2 3 4) asCons)
					= {#x->1. #z->#(2 3 4) asCons}.

	self assert: (#(x y z k) asCons
					bindingsWithArguments: #(1 2 3 4) asCons) 
					= {#x->1 . #y->2 . #z->3 . #k->4}.

	self assert: (#(x y) asCons bindingsWithArguments: #(1 2) asCons) 
					= {#x->1 . #y->2}.

	self assert: (#(#'&rest' args) asCons bindingsWithArguments: nil) 
					= {#args->nil}.

	self assert: (#args bindingsWithArguments: #(1 2) asCons)
					= {#args->#(1 2) asCons}.

	self assert: ( #(x #'&optional' y) asCons
					bindingsWithArguments: #(1 2) asCons)
					= {#x->1 . #y->2}. 

	self assert: (#(x #'&optional' y) asCons
					bindingsWithArguments: #(1) asCons) 
					= {#x->1 . #y->nil} 
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testCellsDo [

	| list sum |

	list := #(1 2 3) asCons.
	sum := 0.
	list cellsDo: [:c | sum := sum + c car]. 

	self assert: sum = 6

]

{ #category : #'as yet unclassified' }
ConsCellTest >> testCollect [

	| list |

	list := #(1 2 3) asCons.

	self assert: (list collect: [:c | c + 1]) = #(2 3 4) asCons.
	self assert: list = #(1 2 3) asCons.

]

{ #category : #'as yet unclassified' }
ConsCellTest >> testConsList [

	self assert: #(1 2 3 4 5) asConsList = #(1 2 3 4 5) asCons.
	self assert: #() asConsList = nil.
	self assert: #(1) asConsList = #(1) asCons.
	self assert: #((1) 2 (3) 4 5) asConsList printString = '(#(1) 2 #(3) 4 5)' .
]

{ #category : #'to do' }
ConsCellTest >> testCyclicPrinting [

	| cons str |

	cons := #(1 2 3 4 5) asCons.
	cons cdr setcar: cons.

	str := cons lispPrintString.

 	self assert: str = '#1=(1 #1# 3 4 5)'.

	self assert: (ELisp new evalString:  '''', str) lispPrintString = str

]

{ #category : #'to do' }
ConsCellTest >> testCyclicPrinting2 [

	| cons str |

	cons := #(1 2 3 4 5) asCons.
	cons cdr setcar: cons.
	cons cddr cddr setcdr: cons cddr cdr.

	str := cons lispPrintString.

 	self assert: str = '#1=(1 #1# 3 . #2=(4 5 . #2#))'.

	self assert: (ELisp new evalString:  '''', str) lispPrintString = str

]

{ #category : #'to do' }
ConsCellTest >> testCyclicPrinting3 [

	| cons str |

	cons := #(1 2 3 4 5) asCons.
	cons cdr setcar: cons.
	cons setcar: (Array with: #a with: cons with: #b).

	str := cons lispPrintString.

 	self assert: str = '#1=(#(a #1# b) #1# 3 4 5)'.

]

{ #category : #'to do' }
ConsCellTest >> testCyclicPrinting4 [

	| cons str |

	cons := #(1 2) asCons.
	cons := {cons . cons . cons} asCons.

	str := cons lispPrintString.

 	self assert: str = '(#1=(1 2) #1# #1#)'.

	self assert: (ELisp new evalString:  '''', str) lispPrintString = str

]

{ #category : #'to do' }
ConsCellTest >> testCyclicPrinting5 [

	| cons vec str |

	cons := #(1 2 3) asCons.
	vec := {10 . cons . 20}.
	cons cdr setcar: vec.

	str := cons lispPrintString.
 	self assert: str = '#1=(1 #(10 #1# 20) 3)'.

	str := vec lispPrintString.
 	self assert: str = '#1=#(10 (1 #1# 3) 20)'.

]

{ #category : #'as yet unclassified' }
ConsCellTest >> testDo [

	| list sum |

	list := #(1 2 3) asCons.
	sum := 0.
	list do: [:c | sum := sum + c]. 

	self assert: sum = 6

]

{ #category : #'as yet unclassified' }
ConsCellTest >> testFirst [

	| list |

	list := #(1 2 3 4 5) asCons.
	self assert: list first = 1.
	self assert: list second = 2.
	self assert: list third = 3.	
	self assert: list last = #(5) asCons
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testLast [

	self assert: #(1 2 3) asCons last = #(3) asCons.
	
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testLength [

	| c |

	self assert: #(1 2 3) asCons length = 3.
	self should: [(#(1 2) asCons append: 3) length] raise: Error.
	
	c := #(1 2) asCons.
	c append: c.
	self assert: c length isInfinite
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testListCopy [

	| list1 list2  |

	list1 := #(1 2 3) asCons.
	list2 := list1 listCopy.
	list2 addLast: 55.

	self assert: list1= #(1 2 3) asCons.
	self assert: list2 = #(1 2 3 55) asCons.

	(list1 nthCell: 1) setcar: 22.

	self assert: list1= #(1 22 3) asCons.
	self assert: list2 = #(1 2 3 55) asCons.
]

{ #category : #'as yet unclassified' }
ConsCellTest >> testSymbolsForBinding [

	self assert: #(x y #'&rest' z) asCons symbolsForBinding 
					= {#x . #y . #z}.

	self assert: (ConsCell car: #x cdr: #z) symbolsForBinding
					= {#x . #z}.

	self assert: #(x y z k) asCons symbolsForBinding 
					= {#x . #y . #z . #k}.

	self assert: #(x y) asCons symbolsForBinding 
					= {#x . #y}.

	self assert: #(#'&rest' args) asCons symbolsForBinding
					= {#args}.

	self assert: #args symbolsForBinding
					= {#args}.

	self assert: #(x #'&optional' y) asCons symbolsForBinding
					= {#x . #y}.

]

{ #category : #'as yet unclassified' }
ConsCellTest >> testWith [

	| list1 list2  |

	list1 := #(1 2 3 4 5) asCons.
	list2 := #(5 4 3 2 1) asCons.
	self assert: (list1 with: list2 collect: [:i :j | i+j]) = #(6 6 6 6 6) asCons.
	self assert: list1 = #(1 2 3 4 5) asCons.
	self assert: list2 = #(5 4 3 2 1) asCons
]
