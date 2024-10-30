as yet unclassified
baseline: spec
	<baseline>
	spec
		for: #common
		do: [ spec blessing: #baseline.
			spec
				package: 'PortsS-Core';
				package: 'PortsS-Interpreter';
				package: 'PortsS-Suites' with: [spec requires: #('Core')];
				group: 'Core' with: #('PortsS-Interpreter' 'PortsS-Core');
				group: 'default' with: #('PortsS-Suites') ].