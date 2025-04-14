Class {
	#name : #BaselineOfRosettaS,
	#superclass : #BaselineOf,
	#category : #BaselineOfRosettaS
}

{ #category : #'as yet unclassified' }
BaselineOfRosettaS >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec blessing: #baseline.
			spec
				package: 'RosettaS-Core';
				package: 'RosettaS-Interpreter';
				package: 'RosettaS-Suites' with: [spec requires: #('Core')];
				group: 'Core' with: #('RosettaS-Interpreter' 'RosettaS-Core');
				group: 'default' with: #('RosettaS-Suites') ].
]
