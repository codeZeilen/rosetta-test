macro expansion
expand: exprs topLevel: isTopLevel

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
				^ self expandQuasiquoteContent: exprs allButFirst].
			[exprs first isSymbol and: [macroTable includesKey: exprs first]] -> [
				^ self applyMacroOn: exprs topLevel: isTopLevel]}
		otherwise: ["recurse"
			^ exprs collect: [:expr | self expand: expr]]


	