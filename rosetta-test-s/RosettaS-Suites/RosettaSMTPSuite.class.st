Class {
	#name : #RosettaSMTPSuite,
	#superclass : #RosettaSuite,
	#instVars : [
		'sockets'
	],
	#category : #'RosettaS-Suites'
}

{ #category : #'suite definition' }
RosettaSMTPSuite >> createSocket: env [

	<rosettaPlaceholderName: 'create-socket'>

	| serverSocket |
	serverSocket := Socket newTCP.
	serverSocket listenOn: 4676 backlogSize: 4.
	sockets add: serverSocket.
	^ serverSocket
]

{ #category : #'test selection' }
RosettaSMTPSuite >> excludeCapabilities [

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
RosettaSMTPSuite >> excludeTests [

	^ #('test_other_auth_failures'
		'test_buggy_auth_with_too_many_challenges' "AUTH method not supported"
		'test_Timeout_during_connect_to_server_with_TLS')
]

{ #category : #private }
RosettaSMTPSuite >> getResponse: smtp [

	^ {smtp responseCode . smtp responseMessage}
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> parseOptions: optionLists for: addresses [
		
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
RosettaSMTPSuite >> secureServerSocketWrap: socketStream ca: caFIlePath cert: certFilePath key: keyFilePath control: controlUnderlyingSocket env: env [

	<rosettaPlaceholderName: 'secure-server-socket-wrap'>

	| stream |
	stream := SqueakSSL secureSocketStream on: socketStream socket.
	stream sslAccept: SqueakSSL ensureSampleCertFile.
	^ stream
]

{ #category : #running }
RosettaSMTPSuite >> setUp [

	sockets := OrderedCollection new.
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpAuthCredentialsError: authenticationResult env: env [

	<rosettaPlaceholderName: 'smtp-auth-credentials-error?'>
	
	^ (authenticationResult isKindOf: TelnetProtocolError) and: [authenticationResult code = 535]
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpAuthNotSupportedError: authenticationResult env: env [

	<rosettaPlaceholderName: 'smtp-auth-not-supported-error?'>
	^ (authenticationResult isKindOf: TelnetProtocolError) and: [authenticationResult code = 504]
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpAuthSuccessful: authenticationResult env: env [

	<rosettaPlaceholderName: 'smtp-auth-successful?'>
	^ authenticationResult isArray and: [authenticationResult first = 235]
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpAuthenticate: smtp method: authMethod credentials: credentials useInitialResponse: aBoolean env: env [

	<rosettaPlaceholderName: 'smtp-authenticate-initial-response'>
	
	authMethod = 'LOGIN' ifFalse: [self error]. "Only login method will be tried by #login"
	smtp user: credentials first.
	smtp password: credentials second.
	[smtp login]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpConnect: host port: port env: env [

	<rosettaPlaceholderName: 'smtp-connect'>

	[^ (SMTPClient openOnHost: (NetNameResolver addressForName: host) port: port)
		useTLSIfAvailable: false;
		yourself]
			on: SocketPrimitiveFailed
			do: [:ex | ^ ex]
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpConnected: smtpClient env: env [

	<rosettaPlaceholderName: 'smtp-connected?'>

	^ smtpClient isConnected
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpData: smtp content: content env: env [

	<rosettaPlaceholderName: 'smtp-data'>
	
	[smtp data: content]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpDisconnect: smtp env: env [

	<rosettaPlaceholderName: 'smtp-disconnect'>
	^ smtp = #() ifFalse: [smtp close]
	
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpEhlo: smtp content: content env: env [

	<rosettaPlaceholderName: 'smtp-ehlo'>

	smtp localHostName: content.
	[smtp initiateSession]
		on: TelnetProtocolError
		do: [:e | ^ e]
		on: SMTPValueError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpExtensionNotSupportedError: smtpResponse env: env [

	<rosettaPlaceholderName: 'smtp-extension-not-supported-error?'>
	
	^ smtpResponse isKindOf: ProtocolClientError
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpExtensions: smtp ehloResponse: response env: env [

	<rosettaPlaceholderName: 'smtp-extensions'>

	^ smtp serverCapabilities
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpIsError: anObject env: env [

	<rosettaPlaceholderName: 'smtp-error?'>
	
	^ (anObject isKindOf: TelnetProtocolError) 
		or: [anObject isKindOf: SMTPValueError]
		or: [anObject isKindOf: SocketPrimitiveFailed]
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpMail: smtp from: fromAddress mailOptions: options env: env [

	<rosettaPlaceholderName: 'smtp-mail-with-options'>
	
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
RosettaSMTPSuite >> smtpRcpt: smtp to: recipientAddresses options: optionLists env: env [

	<rosettaPlaceholderName: 'smtp-rcpt'>
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
RosettaSMTPSuite >> smtpResponseCode: smtpResponse env: env [

	<rosettaPlaceholderName: 'smtp-response-code'>
	smtpResponse isArray ifTrue: [^ smtpResponse first].
	((smtpResponse isKindOf: TelnetProtocolError) or: [smtpResponse isKindOf: SMTPValueError]) ifTrue: [
		^ smtpResponse code].
	self error: 'Undefined case for smtpResponse object'
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpResponseMessage: smtpResponse env: env [

	<rosettaPlaceholderName: 'smtp-response-message'>
	smtpResponse isArray ifTrue: [^ smtpResponse second withUnixLineEndings].
	(smtpResponse isKindOf: TelnetProtocolError) ifTrue: [^ smtpResponse protocolInstance responseMessage withUnixLineEndings].
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpRset: smtp env: env [

	<rosettaPlaceholderName: 'smtp-rset'>
	
	self shouldBeImplemented.
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpSendMessage: smtp content: content from: fromAddress to: recipientAddresses mailOptions: mailOptions recipientOptions: recipientOptions env: env [

	<rosettaPlaceholderName: 'smtp-send-message-with-options'>
	[smtp mailFrom: fromAddress to: recipientAddresses text: content]
		on: TelnetProtocolError
		do: [:e | ^ {e}]
		on: SMTPValueError
		do: [:e | ^ {e}].
	^ {self getResponse: smtp}
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpStarttls: smtpClient env: env [

	<rosettaPlaceholderName: 'smtp-starttls'>
	
	[smtpClient starttls]
		on: TelnetProtocolError
		do: [:e | ^ e]
		on: ProtocolClientError
		do: [:e | ^ e].
	^ self getResponse: smtpClient
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> smtpVrfy: smtp address: address env: env [

	<rosettaPlaceholderName: 'smtp-vrfy'>

	[smtp verify: address]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e].
	^ self getResponse: smtp
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> socketAccept: socket env: env [

	<rosettaPlaceholderName: 'socket-accept'>
	| connectionSocket |
	self flag: #todo. "Consider porting to socket stream"

	connectionSocket := socket waitForAcceptFor: 1.
	self assert: connectionSocket isConnected.
	^ SocketStream on: connectionSocket "Otherwise a timeout exception occurs"
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> socketClose: socket env: env [

	<rosettaPlaceholderName: 'socket-close'>

	^ socket close
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> socketPort: socket env: env [

	<rosettaPlaceholderName: 'socket-port'>

	^ socket port
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> socketReceive: socketStream env: env [

	<rosettaPlaceholderName: 'socket-receive'>

	[socketStream isDataAvailable] whileFalse: [Processor yield]. "Give the mock server or client a chance to do something"
	^ socketStream nextAvailable
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> socketWrite: socketStream content: content env: env [

	<rosettaPlaceholderName: 'socket-write'>
	socketStream nextPutAll: content; flush.
	Processor yield.
]

{ #category : #'suite definition' }
RosettaSMTPSuite >> suiteSource [

	^ self readSuiteFileNamed: 'smtp.rosetta'
]

{ #category : #running }
RosettaSMTPSuite >> tearDown [

	sockets do: [:s | s close].
	sockets removeAll.
]
