running
run

	self assert: self spec notNil.
	self fillPlaceholders.
	"install root capability, run ports scripts"
	"run individual spec tests"