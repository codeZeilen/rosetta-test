spec definition
specSource

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'fs.ports' do: [:portsFile |
		portsFile contents]