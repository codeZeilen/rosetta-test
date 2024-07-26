evaluating
topEnvironment

	^ topEnvironment ifNil: [
		topEnvironment := PortsSchemeEnv new
			bindings: {
				#+ -> [:args | args first + args second].
				#= -> [:args | args first = args second].
				#car -> [:args | args first first].
				#cdr -> [:args | args first size > 1 ifTrue: [args first allButFirst] ifFalse: [Array empty]].
				#list -> [:args | args].
				#'null?' -> [:args | args first isNil]};
			yourself]