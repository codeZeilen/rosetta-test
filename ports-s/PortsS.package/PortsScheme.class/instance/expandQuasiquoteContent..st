macro expansion
expandQuasiquoteContent: exprs

	(self isPair: exprs) not ifTrue: [
		"optimize/simplify quasiquote of literal"
		^ {#quote . exprs}].
	
	self 
		expr: #(quasiquote) , exprs
		shouldFulfill: exprs first ~= #unquotesplicing
		message: 'Can not splice in first position'.
		
	#unquote = exprs first ifTrue: [
		"optimize direct unquote after quasiquote"
		self expr: #(quasiquote) , exprs shouldFulfill: exprs size = 2.
		^ exprs second].
	
	((self isPair: exprs first) and: [exprs first first = #unquotesplicing]) 
		ifTrue: [ | unquotesplicing |
			self expr: exprs shouldFulfill: exprs first size = 2.
			unquotesplicing := exprs first.
			^ #(append) , {unquotesplicing second . "recurse" self expandQuasiquoteContent: exprs allButFirst}]
		ifFalse: [
			"Nothing to do here, recurse on both elements"
			^ #(cons) , {self expandQuasiquoteContent: exprs first . self expandQuasiquoteContent: exprs allButFirst}].
	
	
	
