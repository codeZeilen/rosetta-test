suite definition
smtpRcpt: smtp to: recipientAddresses options: optionTuples env: env

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
				do: ["ignore, as the following smtp lastResponse retrieves the error message"].
			result ifNil: [result := smtp lastResponse].
			result].