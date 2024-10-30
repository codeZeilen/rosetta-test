running
portsRun

	"self assert: self suite notNil.
	self 
		fillPlaceholders;
		installPlaceholders.
	
	self allTests do: [:portsTest |
		self portsRunTest: portsTest]."