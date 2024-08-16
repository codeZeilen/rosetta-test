# TODOs

## Steps
 - Fill basic placeholders for current state of SMTP suite to check whether the current setup makes any sense or needs to much hidden state
  - implement tests for auth
  - implement test for helo
  - implement test for quitting session
 - In Ports-S:
  - implement placeholders for file ops
  - implement run
 - SMTP Spec Ideas
  - Implement more auth methods
  - 8BITMIME extension present or not
  - SMTPUTF8?
  - Refactor auth tests to use common function
  - AUTH
    - Login can not ask for a password? Check with standard
    - Test initial response with data that is too long (do not send initial response in that case)
      - https://datatracker.ietf.org/doc/html/rfc2821#section-4.5.3.1
    - Test initial response with empty data (eg. "" as username)

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
 - Multiple concrete procedures for one placeholder? Sometimes the same scenario can be fulfilled by multiple procedures in the host (e.g. SMTP auth in Python is done by auth and login, in Ruby by authenticate and start)

## Long-term Challenges
 - Can we do an LSP in lispy?