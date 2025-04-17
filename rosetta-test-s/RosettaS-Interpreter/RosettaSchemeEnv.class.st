Class {
	#name : #RosettaSchemeEnv,
	#superclass : #Object,
	#instVars : [
		'bindings',
		'parent'
	],
	#category : #'RosettaS-Interpreter'
}

{ #category : #accessing }
RosettaSchemeEnv >> at: aSymbol [

	^ bindings 
		at: aSymbol 
		ifAbsent: [
			self parent 
				ifNotNil: [self parent at: aSymbol]
				ifNil: ["TODO: This is thrown at the top env"
					self keyError: aSymbol]] 
]

{ #category : #accessing }
RosettaSchemeEnv >> at: aSymbol put: aValue [

	^ bindings at: aSymbol put: aValue
]

{ #category : #private }
RosettaSchemeEnv >> bindings: dictLike [

	bindings := IdentityDictionary newFrom: dictLike.
]

{ #category : #private }
RosettaSchemeEnv >> findEnvFor: aSymbol [

	^ (bindings includesKey: aSymbol) 
		ifTrue: [self]
		ifFalse: [
			self parent 
				ifNil: [self keyError: aSymbol]
				ifNotNil: [self parent findEnvFor: aSymbol]]
]

{ #category : #'initialize-release' }
RosettaSchemeEnv >> initialize [

	super initialize.
	bindings := Dictionary new.
]

{ #category : #accessing }
RosettaSchemeEnv >> keyError: aSymbol [

	(KeyNotFound key: aSymbol) signal
]

{ #category : #accessing }
RosettaSchemeEnv >> parent [

	^ parent
]

{ #category : #accessing }
RosettaSchemeEnv >> parent: anObject [

	parent := anObject.
]

{ #category : #accessing }
RosettaSchemeEnv >> setBindingsFor: paramOrParams to: arguments [

	paramOrParams isSymbol ifFalse: [
		paramOrParams size = arguments size ifFalse: [RosettaTypeError signal]].
	self bindings: (paramOrParams isSymbol
		ifTrue: [{paramOrParams -> arguments}]
		ifFalse: [
			paramOrParams
				with: arguments
				collect: [:a :b | a -> b]]).
]
