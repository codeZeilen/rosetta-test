private-scheme-evaluation
schemeParse: aString

	^ (LKReader for: self scheme) readString: aString