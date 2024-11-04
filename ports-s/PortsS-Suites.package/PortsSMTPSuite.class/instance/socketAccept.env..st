suite definition
socketAccept: socket env: env

	<portsPlaceholderName: 'socket-accept'>
	self flag: #todo. "Consider porting to socket stream"

	socket waitForConnectionFor: 1.
	^ socket "Otherwise a timeout exception occurs"