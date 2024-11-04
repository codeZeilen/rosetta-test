macro expansion
expand: exprs topLevel: isTopLevel

	self expr: exprs shouldFulfill: (exprs isCollection not or: [exprs isString or: [exprs size > 0]]). "Either a non-empty list, or something else"
	true 
		caseOf: {
			[(self isList: exprs) not] -> ["literal"
				^ exprs].
			[#quote = exprs first] -> [
				self expr: exprs shouldFulfill: exprs size = 2.
				^ exprs].
			[#if = exprs first] -> [
				^ self expandIf: exprs].
			[#'set!' = exprs first] -> [
				^ self expandSet: exprs].
			[#define = exprs first or: [#'define-macro' = exprs first]] -> [
				^ self expandDefineAndMacro: exprs topLevel: isTopLevel].
			[#begin = exprs first] -> [
				^ exprs size = 1 
					ifTrue: [nil]		
					ifFalse: [exprs collect: [:expr | self expand: expr topLevel: isTopLevel]]].
			[#lambda = exprs first] -> [
				^ self expandLambda: exprs].
			[#quasiquote = exprs first] -> [
				^ self expandQuasiquoteContent: exprs second].
			[exprs first isSymbol and: [macroTable includesKey: exprs first]] -> [
				^ self applyMacroOn: exprs topLevel: isTopLevel]}
		otherwise: ["recurse"
			^ exprs collect: [:expr | self expand: expr]]


	