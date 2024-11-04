suite definition
smtpSendMessage: smtp content: content from: fromAddress to: recipientAddresses env: env

	<portsPlaceholderName: 'smtp-send-message'>
	
	[smtp mailFrom: fromAddress to: recipientAddresses text: content]
		on: ProtocolClientError
		do: [:e | "ignore, the smtp lastResponse will get the error response"].
	^ {smtp lastResponse}