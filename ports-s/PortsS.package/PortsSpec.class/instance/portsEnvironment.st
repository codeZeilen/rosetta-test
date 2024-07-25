accessing
portsEnvironment

	^ portsEnvironment ifNil: [self newPortsEnvironment]