running
fillPlaceholders
	
	| placeholderMethods placeholderSelectorMap |
	placeholderMethods := self class localMethods select: [:m | 
			m pragmas anySatisfy: [:p | p keyword = #portsPlaceholderName:]]. 
	placeholderMethods := placeholderMethods groupBy: [:m | 
		m pragmas 
			detect: [:p | p keyword = #portsPlaceholderName:]
			ifFound: [:p | p argumentAt: 1]
			ifNone: [self error]].
	(placeholderMethods select: [:group | group size > 1]) keysAndValuesDo: [:placeholderName :methods | 
		Notification signal: 'Duplicate placeholder method for: ' , placeholderName].
		
	placeholderSelectorMap := placeholderMethods collect: [:group | group first selector].
	
	placeholders do: [:placeholder |
		placeholderSelectorMap 
			at: placeholder placeholderName
			ifPresent: [:placeholderSelector | 
				placeholder function: (MessageSend 
					receiver: self 
					selector: placeholderSelector)]].
