suite definition
smtpData: smtp content: content env: env

	<portsPlaceholderName: 'smtp-data'>
	
	[smtp data: content]
		on: SMTPValueError
		do: [:e | ^ e].
	^ smtp lastResponse