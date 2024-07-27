macro expansion
applyMacroOn: exprs topLevel: isTopLevel

	| macroResult |
	macroResult := (macroTable at: exprs first) value: exprs allButFirst.
	^ self expand: macroResult topLevel: isTopLevel