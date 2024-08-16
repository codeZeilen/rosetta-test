spec definition
suiteSource

	^ (FileDirectory default / '..' / '..' / #ports / 'suites') readOnlyFileNamed: 'fs.ports' do: [:portsFile |
		portsFile contents]