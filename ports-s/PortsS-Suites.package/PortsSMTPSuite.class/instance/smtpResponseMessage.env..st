suite definition
smtpResponseMessage: smtpResponse env: env

	<portsPlaceholderName: 'smtp-response-message'>
	^ (smtpResponse allButFirst: 3) withBlanksTrimmed