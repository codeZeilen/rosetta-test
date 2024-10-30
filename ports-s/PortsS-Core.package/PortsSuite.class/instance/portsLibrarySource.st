private-ports
portsLibrarySource

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'ports.scm' do: [:portsFile |
		portsFile contents]