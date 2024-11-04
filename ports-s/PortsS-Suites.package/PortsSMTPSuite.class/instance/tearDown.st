running
tearDown

	sockets do: [:s | s close].
	sockets removeAll.