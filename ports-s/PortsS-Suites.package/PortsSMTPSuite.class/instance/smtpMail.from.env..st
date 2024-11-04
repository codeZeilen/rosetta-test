suite definition
smtpMail: smtp from: fromAddress env: env

	<portsPlaceholderName: 'smtp-mail'>
	
	[smtp mailFrom: fromAddress]
		on: SMTPValueError
		do: [:e | ^ e].
	^ smtp lastResponse