suite definition
smtpAuthSuccessful: authenticationResult env: env

	<portsPlaceholderName: 'smtp-auth-successful?'>
	
	^ (authenticationResult first: 3) asInteger = 235