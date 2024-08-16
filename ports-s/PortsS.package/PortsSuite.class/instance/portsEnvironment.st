private-ports
portsEnvironment

	^ portsEnvironment ifNil: [self newPortsEnvironment]