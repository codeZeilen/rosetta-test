"
This is the unit test for the class LKToken. Unit tests are a good way to exercise the functionality of your system in a repeatable and automatic manner. They are therefore recommended if you plan to release anything. For more information, see: 
	- http://www.c2.com/cgi/wiki?UnitTest
	- http://minnow.cc.gatech.edu/squeak/1547
	- the sunit class category

"
Class {
	#name : #LKTokenTest,
	#superclass : #TestCase,
	#category : #'LispKit-Tests'
}

{ #category : #'as yet unclassified' }
LKTokenTest >> testExponent [

	self assert: (LKToken parse: '-12e8') = -1.2e9 .
	self assert: (LKToken parse: '-12.e8') = -1.2e9 .
	self assert: (LKToken parse: '-12.0e8') = -1.2e9 .
	self assert: (LKToken parse: '-12e+8') = -1.2e9 .
	self assert: (LKToken parse: '-12e+8.') = #'-12e+8.' .
	self assert: ((LKToken parse: '12e-3') closeTo: 0.012).
	self assert: ((LKToken parse: '12.e-3') closeTo: 0.012).
	self assert: (LKToken parse: '12e-+3') = #'12e-+3' .
]

{ #category : #'as yet unclassified' }
LKTokenTest >> testFloats [

	self assert: (LKToken parse: '123.0') isFloat.
	self assert: (LKToken parse: '123.0') = 123.
	self assert: (LKToken parse: '123.0I') = #'123.0I'.
	self assert: (LKToken parse: '-12.3') = -12.3.
	self assert: ((LKToken parse: '+.123') closeTo: 0.123).
	self assert: (LKToken parse: '.0') isFloat.
	self assert: (LKToken parse: '.0') = 0.0

]

{ #category : #'as yet unclassified' }
LKTokenTest >> testFractions [

	self assert: (LKToken parse: '12/35') = (12/35).
	self assert: (LKToken parse: '12/35') isFraction.
	self assert: (LKToken parse: '-12/35') = (-12/35).
	self assert: (LKToken parse: '-12/35') isFraction.
	self assert: (LKToken parse: '12//35') = #'12//35'.
	self assert: (LKToken parse: '12/3.5') = #'12/3.5'.
	self assert: (LKToken parse: '12./35') = #'12./35'.
	self assert: (LKToken parse: '12/-35') = #'12/-35'.
	self assert: (LKToken parse: '12/+35') = #'12/+35'.
	self assert: (LKToken parse: '-12/-35') = #'-12/-35'.

]

{ #category : #'as yet unclassified' }
LKTokenTest >> testIntegers [

	self assert: (LKToken parse: '123') = 123.
	self assert: (LKToken parse: '123.') = 123.
	self assert: (LKToken parse: '123I') = #'123I'.
	self assert: (LKToken parse: '-123') = -123.
	self assert: (LKToken parse: '+123') = 123.
	self assert: (LKToken parse: '0.') = 0.

]

{ #category : #'as yet unclassified' }
LKTokenTest >> testSpecials [

	self assert: (LKToken parse: '+') = #'+' .
	self assert: (LKToken parse: '-') = #'-' .
	self assert: (LKToken parse: '+.') = #'+.' .
	self assert: (LKToken parse: '-.') = #'-.' .
	self assert: (LKToken parse: '+-') = #'+-' .
	self assert: (LKToken parse: '-+') = #'-+' .
	self assert: (LKToken parse: '.') = #'.' .

	self assert: (LKToken parse: 'e') = #e .
	self assert: (LKToken parse: '12e') = #'12e' .
	self assert: (LKToken parse: 'e1') = #'e1' .

	self assert: (LKToken parse: '/') = #'/' .
	self assert: (LKToken parse: '/5') = #'/5' .
	self assert: (LKToken parse: '5/') = #'5/' .
]
