private-ports
portsLibrarySource

	^ (FileDirectory default / '..' / '..' / #ports) readOnlyFileNamed: 'ports.lispy' do: [:portsFile |
		portsFile contents]