suite definition
smtpResponseCode: smtpResponse env: env

	<portsPlaceholderName: 'smtp-response-code'>
	^ (smtpResponse first: 3) asInteger