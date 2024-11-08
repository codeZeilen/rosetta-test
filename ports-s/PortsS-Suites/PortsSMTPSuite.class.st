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
	serverSocket listenOn: 4676 backlogSize: 1.
	sockets add: serverSocket.
	^ serverSocket
]

{ #category : #'test selection' }
PortsSMTPSuite >> excludeCapabilities [

	^ #('root.commands.auth.xoauth2' 'root.commands.auth.cram-md5' 'root.commands.auth.plain-auth' 'root.commands.rset')
]

{ #category : #running }
PortsSMTPSuite >> setUp [

	sockets := OrderedCollection new.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthCredentialsError: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-credentials-error?'>
	
	^ authenticationResult isString and: [(authenticationResult first: 3) = '535']
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthNotSupportedError: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-not-supported-error?'>
	^ authenticationResult isString and: [(authenticationResult first: 3) = '504']
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthSuccessful: authenticationResult env: env [

	<portsPlaceholderName: 'smtp-auth-successful?'>
	
	^ authenticationResult isString and: [(authenticationResult first: 3) asInteger = 235]
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpAuthenticate: smtp method: authMethod credentials: credentials env: env [

	<portsPlaceholderName: 'smtp-authenticate'>
	
	authMethod = 'LOGIN' ifFalse: [self error]. "Only login will be tried by #login"
	smtp user: credentials first.
	smtp password: credentials second.
	[smtp login]
		on: TelnetProtocolError
		do: [:e | ^ e response].
	^ smtp lastResponse
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpConnect: host port: port env: env [

	<portsPlaceholderName: 'smtp-connect'>

	^ SMTPClient openOnHost: (NetNameResolver addressForName: host) port: port
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpData: smtp content: content env: env [

	<portsPlaceholderName: 'smtp-data'>
	
	[smtp data: content]
		on: SMTPValueError
		do: [:e | ^ e].
	^ smtp lastResponse
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
		do: [:e | ^ e response].
	^ smtp lastResponse
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpExtensionNotSupportedError: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-extension-not-supported-error?'>
	
	self shouldBeImplemented.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpExtensions: smtp ehloResponse: response env: env [

	<portsPlaceholderName: 'smtp-extensions'>

	^ smtp serverCapabilities
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpIsError: anObject env: env [

	<portsPlaceholderName: 'smtp-error?'>
	
	^ anObject isKindOf: Exception
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpMail: smtp from: fromAddress env: env [

	<portsPlaceholderName: 'smtp-mail'>
	
	[smtp mailFrom: fromAddress]
		on: SMTPValueError
		do: [:e | ^ e]
		on: TelnetProtocolError
		do: [:e | ^ e response].
	^ smtp lastResponse
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpRcpt: smtp to: recipientAddresses options: optionTuples env: env [

	<portsPlaceholderName: 'smtp-rcpt'>
	| options |
	
	options := optionTuples 
		ifNotEmpty: []
		ifEmpty: [(1 to: recipientAddresses size) collect: [:i | {}]].

	^ recipientAddresses 
		with: options 
		collect: [:recipient :recipientOptions | | result |
			[smtp recipient: recipient]
				on: SMTPValueError 
				do: [:e | result := e]
				on: TelnetProtocolError
				do: [:e | result := e response].
			result ifNil: [result := smtp lastResponse].
			result].
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpResponseCode: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-response-code'>
	^ (smtpResponse first: 3) asInteger
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpResponseMessage: smtpResponse env: env [

	<portsPlaceholderName: 'smtp-response-message'>
	^ (smtpResponse allButFirst: 3) withBlanksTrimmed
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpRset: smtp env: env [

	<portsPlaceholderName: 'smtp-rset'>
	
	self shouldBeImplemented.
]

{ #category : #'suite definition' }
PortsSMTPSuite >> smtpSendMessage: smtp content: content from: fromAddress to: recipientAddresses env: env [

	<portsPlaceholderName: 'smtp-send-message'>
	
	[smtp mailFrom: fromAddress to: recipientAddresses text: content]
		on: TelnetProtocolError
		do: [:e | ^ {e response}].
	^ {smtp lastResponse}
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketAccept: socket env: env [

	<portsPlaceholderName: 'socket-accept'>
	self flag: #todo. "Consider porting to socket stream"

	socket waitForConnectionFor: 1.
	^ socket "Otherwise a timeout exception occurs"
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

	^ socketStream receiveData
]

{ #category : #'suite definition' }
PortsSMTPSuite >> socketWrite: socketStream content: content env: env [

	<portsPlaceholderName: 'socket-write'>
	^ socketStream sendData: content
]

{ #category : #'suite definition' }
PortsSMTPSuite >> suiteSource [

	^ (FileDirectory default / '..' / '..' / #ports / 'suites') readOnlyFileNamed: 'smtp.ports' do: [:portsFile |
		portsFile contents]
]

{ #category : #running }
PortsSMTPSuite >> tearDown [

	sockets do: [:s | s close].
	sockets removeAll.
]
