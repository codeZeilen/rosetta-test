as yet unclassified
value: values

	^ self interpreter 
		evalExprs: self body
		in: (PortsSchemeEnv new
				setBindingsFor: self params to: values;
				parent: self env;
				yourself)