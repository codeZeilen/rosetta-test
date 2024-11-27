Extension { #name : #Object }

{ #category : #'*PortsS-Interpreter' }
Object >> arrayForm [

	^ self
]

{ #category : #'*PortsS-Interpreter' }
Object >> isPortsSchemePrimitive [

	^ false
]

{ #category : #'*PortsS-Interpreter' }
Object >> isPortsSchemeProcedure [

	^ false
]

{ #category : #'*PortsS-Interpreter' }
Object >> isPortsTrue [

	^ true
]

{ #category : #'*PortsS-Interpreter' }
Object >> printAsTree [

	^ self printString
]
