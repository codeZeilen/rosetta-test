Class {
	#name : #PortsSMTPSuite,
	#superclass : #PortsSuite,
	#instVars : [
		'sockets'
	],
	#category : #'PortsS-Suites'
}

{ #category : #'suite definition' }
PortsSMTPSuite >> createSocket: env [

	<portsPlaceholderName: 'create-socket'>

	| serverSocket |
	serverSocket := Socket newTCP.
	serverSocket listenOn: 4676 backlogSize: 4.
	sockets add: serverSocket.
	^ serverSocket
]

{ #category : #'test selection' }
PortsSMTPSuite >> excludeCapabilities [

	^ #(
		"not implemented"
		'root.commands.auth.xoauth2' 
		'root.commands.auth.cram-md5' 
		'root.commands.auth.plain-auth' 
		'root.commands.rset' 
		'root.commands.help' 
		'root.commands.expn'
		'root.crlf-injection-detection.commands.detection.expn'
		'root.smtputf8'
		'root.8bitmime.send-message.mandatory-options'
	

		"decided to detect"
		'root.crlf-injection-detection.commands.mitigation'
		'root.crlf-injection-detection.send-message.mitigation'
		
		"SqueakSSL does not work"
		'root.commands.starttls'
		'root.commands.automatic-starttls')
]

{ #category : #'test selection' }
PortsSMTPSuite >> excludeTests [

	^ #('test_other_auth_failures'
		'test_buggy_auth_with_too_many_challenges' "AUTH method not supported"
		'test_Timeout_during_connect_to_server_with_TLS')
]

{ #category : #private }
PortsSMTPSuite >> getResponse: smtp [

	^ {smtp responseCode . smtp responseMessage}
]

{ #category : #'suite definition' }
PortsSMTPSuite >> parseOptions: optionLists for: addresses [
		
	^ optionLists 
		ifNotEmpty: [optionLists collect: [:optionList |
			optionList
				collect: [:option |
					option isString 
						ifTrue: [option -> '']
						ifFalse: [option first -> option second]]
				as: Dictionary]]
		ifEmpty: [(1 to: addresses size) collect: [:i | Dictionary new]].

	
]

{ #category : #'suite definition' }
PortsSMTPSuite >> secureServerSocketWrap: socketStream ca: caFIlePath cert: certFilePath key: keyFilePath control: controlUnderlyingSocket env: env [

	<portsPlaceholderName: 'secure-server-socket-wrap'>

	| stream |
	stream := SqueakSSL secureSocketStream on: socketStream socket.
	stream sslAccept: SqueakSSL ensureSampleCertFile.
	^ stream
]

{ #category : #running }
PortsSMTPSuite >> setUp [

	sockets := OrderedCollection new.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthCredentialsError: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-credentials-error?'>
	
	^ (authenticationResult isKindOf: TelnetProtocolError) and: [authenticationResult code = 535]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthNotSupportedError: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-not-supported-error?'>
	^ (authenticationResult isKindOf: TelnetProtocolError) and: [authenticationResult code = 504]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthSuccessful: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-successful?'>
	^ authenticationResult isArray and: [authenticationResult first = 235]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthenticate: smtp method: authMethod credentials: credentials useInitialResponse: aBoolean env: env [

	<portsPlaceholderName: 'smtp-authenticate-initial-response'>
	
	authMethod = 'LOGIN' ifFalse: [self error]. "Only login method will be tried by #login"
	smtp user: credentials first.
	smtp password: credentials second.
	[smtp login]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpConnect: host port: port env: env [

	<portsPlaceholderName: 'smtp-connect'>

	[^ (SMTPClient openOnHost: (NetNameResolver addressForName: host) port: port)
		useTLSIfAvailable: false;
		yourself]
			on: SocketPrimitiveFailed
			do: [:ex | ^ ex]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpConnected: smtpClient env: env [

	<portsPlaceholderName: 'smtp-connected?'>

	^ smtpClient isConnected
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpData: smtp content: content env: env [

	<portsPlaceholderName: 'smtp-data'>
	
	[smtp data: content]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpDisconnect: smtp env: env [

	<portsPlaceholderName: 'smtp-disconnect'>
	^ smtp = #() ifFalse: [smtp close]
	
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpEhlo: smtp content: content env: env [

	<portsPlaceholderName: 'smtp-ehlo'>

	smtp localHostName: content.
	[smtp initiateSession]
		on: TelnetProtocolError
		do: [:e | ^ e]
		on: SMTPValueError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpExtensionNotSupportedError: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-extension-not-supported-error?'>
	
	^ smtpResponse isKindOf: ProtocolClientError
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpExtensions: smtp ehloResponse: response env: env [

	<portsPlaceholderName: 'smtp-extensions'>

	^ smtp serverCapabilities
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpIsError: anObject env: env [

	<portsPlaceholderName: 'smtp-error?'>
	
	^ (anObject isKindOf: TelnetProtocolError) 
		or: [anObject isKindOf: SMTPValueError]
		or: [anObject isKindOf: SocketPrimitiveFailed]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpMail: smtp from: fromAddress mailOptions: options env: env [

	<portsPlaceholderName: 'smtp-mail-with-options'>
	
	| optionsDict |
	optionsDict := (self parseOptions: {options} for: {fromAddress}) first.
	
	[smtp mailFrom: fromAddress options: optionsDict]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpRcpt: smtp to: recipientAddresses options: optionLists env: env [

	<portsPlaceholderName: 'smtp-rcpt'>
	| options |
	
	options := self parseOptions: optionLists for: recipientAddresses.
	
	^ recipientAddresses 
		with: options 
		collect: [:recipient :recipientOptions | | result |
			[smtp recipient: recipient options: recipientOptions]
				on: SMTPValueError 
				do: [:e | result := e]
				on: TelnetProtocolError
				do: [:e | result := e].
			result ifNil: [result := self getResponse: smtp].
			result].
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpResponseCode: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-response-code'>
	smtpResponse isArray ifTrue: [^ smtpResponse first].
	((smtpResponse isKindOf: TelnetProtocolError) or: [smtpResponse isKindOf: SMTPValueError]) ifTrue: [
		^ smtpResponse code].
	self error: 'Undefined case for smtpResponse object'
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpResponseMessage: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-response-message'>
	smtpResponse isArray ifTrue: [^ smtpResponse second withUnixLineEndings].
	(smtpResponse isKindOf: TelnetProtocolError) ifTrue: [^ smtpResponse protocolInstance responseMessage withUnixLineEndings].
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpRset: smtp env: env [

	<portsPlaceholderName: 'smtp-rset'>
	
	self shouldBeImplemented.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpSendMessage: smtp content: content from: fromAddress to: recipientAddresses mailOptions: mailOptions recipientOptions: recipientOptions env: env [

	<portsPlaceholderName: 'smtp-send-message-with-options'>
	[smtp mailFrom: fromAddress to: recipientAddresses text: content]
		on: TelnetProtocolError
		do: [:e | ^ {e}]
		on: SMTPValueError
		do: [:e | ^ {e}].
	^ {self getResponse: smtp}
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpStarttls: smtpClient env: env [

	<portsPlaceholderName: 'smtp-starttls'>
	
	[smtpClient starttls]
		on: TelnetProtocolError
		do: [:e | ^ e]
		on: ProtocolClientError
		do: [:e | ^ e].
	^ self getResponse: smtpClient
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpVrfy: smtp address: address env: env [

	<portsPlaceholderName: 'smtp-vrfy'>

	[smtp verify: address]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketAccept: socket env: env [

	<portsPlaceholderName: 'socket-accept'>
	| connectionSocket |
	self flag: #todo. "Consider porting to socket stream"

	connectionSocket := socket waitForAcceptFor: 1.
	self assert: connectionSocket isConnected.
	^ SocketStream on: connectionSocket "Otherwise a timeout exception occurs"
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketClose: socket env: env [

	<portsPlaceholderName: 'socket-close'>

	^ socket close
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketPort: socket env: env [

	<portsPlaceholderName: 'socket-port'>

	^ socket port
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketReceive: socketStream env: env [

	<portsPlaceholderName: 'socket-receive'>

	[socketStream isDataAvailable] whileFalse: [Processor yield]. "Give the mock server or client a chance to do something"
	^ socketStream nextAvailable
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketWrite: socketStream content: content env: env [

	<portsPlaceholderName: 'socket-write'>
	socketStream nextPutAll: content; flush.
	Processor yield.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> suiteSource [

	^ self readSuiteFileNamed: 'smtp.ports'
]

{ #category : #running }
PortsSMTPSuite >> tearDown [

	sockets do: [:s | s close].
	sockets removeAll.
]
