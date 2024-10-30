suite definition
suiteSource

	^ (FileDirectory default / '..' / '..' / #ports / 'suites') readOnlyFileNamed: 'smtp.ports' do: [:portsFile |
		portsFile contents]