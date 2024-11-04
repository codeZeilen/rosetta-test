suite definition
smtpConnect: host port: port env: env

	<portsPlaceholderName: 'smtp-connect'>

	^ SMTPClient openOnHost: (NetNameResolver addressForName: host) port: port