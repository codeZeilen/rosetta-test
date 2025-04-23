Extension { #name : #IdentityDictionary }

{ #category : #'*LispKit' }
IdentityDictionary >> bindingFor: aKey ifNone: aBlock [

	"provides a fast access to a possible binding"

	^ ((array at: (self scanFor: aKey)) ifNil: [aBlock]) value 
]
