# TODOs

## Steps
 - Fill basic placeholders for current state of SMTP suite to check whether the current setup makes any sense or needs to much hidden state
  - implement tests for auth
  - implement test for helo
  - implement test for quitting session
 - In Ports-S:
  - implement placeholders for file ops
  - implement run

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
    - requires pattern matching and syntax-rules, with those we can get some code from the R7RS spec

## Long-term Challenges
 - Can we do an LSP in lispy?