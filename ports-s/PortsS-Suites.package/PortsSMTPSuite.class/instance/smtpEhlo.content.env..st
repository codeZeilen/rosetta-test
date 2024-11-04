suite definition
smtpEhlo: smtp content: content env: env

	<portsPlaceholderName: 'smtp-ehlo'>

	smtp localHostName: content.
	smtp initiateSession.
	^ smtp lastResponse