running
fillPlaceholders
	
	| placeholderMethods placeholderSelectorMap |
	placeholderMethods := self class localMethods select: [:m | 
			m pragmas anySatisfy: [:p | p keyword = #portsPlaceholderName:]]. 
	placeholderSelectorMap := Dictionary newFrom: (placeholderMethods collect: [:m | | key |
		key := m pragmas 
			detect: [:p | p keyword = #portsPlaceholderName:]
			ifFound: [:p | p argumentAt: 1]
			ifNone: [self error].
		key -> m selector]).
	
	placeholders do: [:placeholder |
		placeholderSelectorMap 
			at: placeholder placeholderName
			ifPresent: [:placeholderSelector | 
				placeholder function: (MessageSend 
					receiver: self 
					selector: placeholderSelector)]].
