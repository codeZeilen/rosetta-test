Class {
	#name : #PortsSchemeEnv,
	#superclass : #Object,
	#instVars : [
		'bindings',
		'parent'
	],
	#category : #'PortsS-Interpreter'
}

{ #category : #accessing }
PortsSchemeEnv >> at: aSymbol [

	^ bindings 
		at: aSymbol 
		ifAbsent: [
			self parent 
				ifNotNil: [self parent at: aSymbol]
				ifNil: ["TODO: This is thrown at the top env"
					self keyError: aSymbol]] 
]

{ #category : #accessing }
PortsSchemeEnv >> at: aSymbol put: aValue [

	^ bindings at: aSymbol put: aValue
]

{ #category : #private }
PortsSchemeEnv >> bindings: dictLike [

	bindings := IdentityDictionary newFrom: dictLike.
]

{ #category : #private }
PortsSchemeEnv >> findEnvFor: aSymbol [

	^ (bindings includesKey: aSymbol) 
		ifTrue: [self]
		ifFalse: [
			self parent 
				ifNil: [self keyError: aSymbol]
				ifNotNil: [self parent findEnvFor: aSymbol]]
]

{ #category : #'initialize-release' }
PortsSchemeEnv >> initialize [

	super initialize.
	bindings := Dictionary new.
]

{ #category : #accessing }
PortsSchemeEnv >> keyError: aSymbol [

	(KeyNotFound key: aSymbol) signal
]

{ #category : #accessing }
PortsSchemeEnv >> parent [

	^ parent
]

{ #category : #accessing }
PortsSchemeEnv >> parent: anObject [

	parent := anObject.
]

{ #category : #accessing }
PortsSchemeEnv >> setBindingsFor: paramOrParams to: arguments [

	paramOrParams isSymbol ifFalse: [
		paramOrParams size = arguments size ifFalse: [PortsTypeError signal]].
	self bindings: (paramOrParams isSymbol
		ifTrue: [{paramOrParams -> arguments}]
		ifFalse: [
			paramOrParams
				with: arguments
				collect: [:a :b | a -> b]]).
]

{ #category : #accessing }
PortsSchemeEnv >> unset: aSymbol [

	bindings removeKey: aSymbol
]
