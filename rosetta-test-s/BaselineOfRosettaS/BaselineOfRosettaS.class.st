Class {
	#name : #BaselineOfRosettaS,
	#superclass : #BaselineOf,
	#category : #BaselineOfRosettaS
}

{ #category : #baseline }
BaselineOfRosettaS >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec blessing: #baseline.
			spec
				package: 'RosettaS-Core' with: [spec requires: #('OSProcess')];
				package: 'RosettaS-Interpreter' with: [spec requires: #(LispKit)];
				package: 'RosettaS-Suites' with: [spec requires: #('Core')];
				package: 'LispKit' with: [spec requires: #('ConsCell' 'Continuation')]; "Added to repo, as only available via SqueakMap"
				package: 'ConsCell';
				package: 'Continuation';
				package: 'OSProcess' with: [
					spec repository: 'http://www.squeaksource.com/OSProcess'];
				group: 'Core' with: #('RosettaS-Interpreter' 'RosettaS-Core');
				group: 'default' with: #('RosettaS-Suites') ].
]
