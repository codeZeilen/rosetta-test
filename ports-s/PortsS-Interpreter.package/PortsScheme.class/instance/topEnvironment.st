evaluating
topEnvironment

	^ topEnvironment ifNil: [
		topEnvironment := PortsSchemeEnv new
			bindings: {
				#true -> true.
				#false -> false.
				#+ -> [:args | args first + args second].
				#- -> [:args | args first - args second].
				#'string-append' -> [:args | args fold: #,].
				#append -> [:args | args fold: #,].
				#* -> [:args | args first * args second].
				#/ -> [:args | args first / args second].
				#= -> [:args | args first = args second].
				#> -> [:args | args first > args second].
				#< -> [:args | args first < args second].
				#<= -> [:args | args first <= args second].
				#abs -> [:args | args first abs].
				#sqrt -> [:args | args first sqrt].
				#inexact -> [:args | args first asFloat].
				#length -> [:args | args first size].
				#car -> [:args | args first first].
				#cdr -> [:args | args first size > 1 ifTrue: [args first allButFirst] ifFalse: [Array empty]].
				#list -> [:args | args].
				#'null?' -> [:args | args first isNil or: [args first isCollection and: [args first isEmpty]]].
				#cons -> [:args | {args first} , args second "TODO: this is not right"].
				#'create-placeholder' -> [:args | self createPlaceholder: args].
				#not -> [:args | args first not].
				#apply -> [:args | args first value: args second].
				#map -> [:args | args second collect: [:e | args first value: {e}]].
				#'for-each' -> [:args | args second do: [:e | args first value: {e}]].
				#'list-ref' -> [:args | args first at: args second + 1].
				#'list-set!' -> [:args | args first at: args second + 1 put: args third].
				#raise -> [:args | args first signalerContext ifNil: [args first signal] ifNotNil: [args first pass]].
				#error -> [:args | Error new messageText: args first; yourself].
				#'is-placeholder?' -> [:args | self isPlaceholderP: args].
				#'list?' -> [:args | args first isCollection].
				#'string-upcase' -> [:args | args first asUppercase].
				#'string-trim' -> [:args | args first withBlanksTrimmed].
				#'string-split' -> [:args | args first findTokens: args second].
				#'string-replace' -> [:args | args third copyReplaceAll: args first with: args second].
				#'with-exception-handler' -> [:args | [args second value: {}] on: Exception do: [:e | args first value: {e}]].
				#display -> [:args | Transcript showln: args first]};
			yourself.
		self evalString: self portsLibrarySource in: topEnvironment.
		topEnvironment]