Extension { #name : #Object }

{ #category : #'*RosettaS-Interpreter' }
Object >> arrayForm [

	^ self
]

{ #category : #'*RosettaS-Interpreter' }
Object >> isRosettaSchemePrimitive [

	^ false
]

{ #category : #'*RosettaS-Interpreter' }
Object >> isRosettaSchemeProcedure [

	^ false
]

{ #category : #'*RosettaS-Interpreter' }
Object >> isRosettaTrue [

	^ true
]

{ #category : #'*RosettaS-Interpreter' }
Object >> printAsTree [

	^ self printString
]
