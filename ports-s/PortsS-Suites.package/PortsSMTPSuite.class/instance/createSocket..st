suite definition
createSocket: env

	<portsPlaceholderName: 'create-socket'>

	| serverSocket |
	serverSocket := Socket newTCP.
	serverSocket listenOn: 4676 backlogSize: 1.
	sockets add: serverSocket.
	^ serverSocket