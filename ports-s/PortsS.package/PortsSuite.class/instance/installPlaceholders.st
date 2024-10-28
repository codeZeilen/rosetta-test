running
installPlaceholders

	placeholders do: [:placeholder | 
		self portsEnvironment 
			at: placeholder placeholderName asSymbol
			put: placeholder]