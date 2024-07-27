evaluating
topEnvironment

	^ topEnvironment ifNil: [
		topEnvironment := PortsSchemeEnv new
			bindings: {
				#+ -> [:args | args first + args second].
				#'string-append' -> [:args | args fold: #,].
				#* -> [:args | args first * args second].
				#= -> [:args | args first = args second].
				#> -> [:args | args first > args second].
				#length -> [:args | args first size].
				#car -> [:args | args first first].
				#cdr -> [:args | args first size > 1 ifTrue: [args first allButFirst] ifFalse: [Array empty]].
				#list -> [:args | args].
				#'null?' -> [:args | args first isNil or: [args first isCollection and: [args first isEmpty]]].
				#cons -> [:args | {args first} , args second "TODO: this is not right"].
				#'create-placeholder' -> [:args | self createPlaceholder: args].
				#not -> [:args | args first not].
				#and -> [:args | args first and: [args second]].
				#or -> [:args | args first or: [args second]].
				#map -> [:args | args second collect: [:e | args first value: {e}]].
				#'for-each' -> [:args | args second do: [:e | args first value: {e}]].
				#'list-ref' -> [:args | args first at: args second + 1].
				#'list-set!' -> [:args | args first at: args second + 1 put: args third].
				#raise -> [:args | args first signal].
				#error -> [:args | Error new messageText: args first; yourself].
				#'is-placeholder?' -> [:args | self isPlaceholderP: args]};
			yourself]