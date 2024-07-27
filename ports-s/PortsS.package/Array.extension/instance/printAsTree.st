*PortsS
printAsTree

	^ String streamContents: [:stream |
		stream << '('.
		self size > 0 ifTrue: [
			stream << self first printAsTree; crlf.].
		self size > 1 ifTrue: [
			(self allButFirst 
				gather: [:e | (e printAsTree , String crlf) lines])
				collect: [:line | stream tab; << line; crlf]].
		stream << ')']