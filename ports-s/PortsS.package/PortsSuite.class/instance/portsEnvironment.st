private-ports
portsEnvironment

	^ portsEnvironment ifNil: [portsEnvironment := self newPortsEnvironment]