initialize-release
initialMacroTable

	^ IdentityDictionary newFrom: {
		#let -> [:args | self macroLet: args]}.