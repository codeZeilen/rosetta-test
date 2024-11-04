suite definition
socketWrite: socketStream content: content env: env

	<portsPlaceholderName: 'socket-write'>
	^ socketStream sendData: content