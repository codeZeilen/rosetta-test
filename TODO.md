# TODOs

## Steps
 - Fill basic placeholders for current state of SMTP suite to check whether the current setup makes any sense or needs to much hidden state

## Roadmap
 - Create SMTP suite
 - Create Squeak/Smalltalk implementation

## Design Challenges
 - Reduce set of primitives (potentially use Gauche stdlib)
  - Load stdlib first then let implementations replace stuff with primitive (e.g. map, reverse)
 - Decide on exception vs return values for error cases
  - Exceptions might not be available everywhere
 - Module system, as this is already becoming an issue
 - Decide on whether to use normal interpreter or switch to bytecode format (ideally with user-level compiler)
  - cons: Less accessible
  - pro: Can make implementing tools easier, probably more efficient
 - Ensure R7RS-small compatibility!
  - define-syntax, syntax-rules, `...`

## Long-term Challenges
 - Can we do an LSP in lispy?