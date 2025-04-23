Extension { #name : #Character }

{ #category : #'*ConsCell' }
Character >> printOn: aStream forLisp: aLisp [

	aLisp ifNotNil: 
		[^ aStream nextPutAll: (aLisp class characterPrintString: self)].

	aStream nextPutAll: (self codePoint caseOf:
	{
		[10] -> ['#\newline'] .
		[9] -> ['#\tab'] .
		[32] -> ['#\space'] .			
		[8] -> ['#\backspace'] .			
		[27] -> ['#\escape'] .			
		[13] -> ['#\return'] .			
		[127] -> ['#\rubout'] .	
	} 
	otherwise: ['#\', self asString])
]
