running
performTest

	^ self allTests 
		detect: [:test | (self testNameOf: test) = testSelector]
		ifFound: [:test | self portsRunTest: test]