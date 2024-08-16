running
run

	self assert: self suite notNil.
	self fillPlaceholders.
	"install root capability, run ports scripts"
	"run individual spec tests"