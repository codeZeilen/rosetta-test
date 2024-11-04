suite definition
smtpAuthenticate: smtp method: authMethod credentials: credentials env: env

	<portsPlaceholderName: 'smtp-authenticate'>
	
	authMethod = 'LOGIN' ifFalse: [self error].
	smtp user: credentials first.
	smtp password: credentials second.
	smtp login.
	^ smtp lastResponse