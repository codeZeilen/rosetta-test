# TODOs

## Step 
 - SMTP Suite
  - TLS Tests: Ruby has two ways to get an SMTP connection: SMTP.new + call methods on the smtp object + call .start OR SMTP.start directly (gotta work on those multiple placeholder things) 
 - SMTP Spec Ideas
  - 8BITMIME extension present or not
  - Refactor auth tests to use common function
  - AUTH
    - Login can not ask for a password? Check with standard
    - Test initial response with data that is too long (do not send initial response in that case)
      - https://datatracker.ietf.org/doc/html/rfc2821#section-4.5.3.1
    - Test initial response with empty data (eg. "" as username)

## Refactorings

## Roadmap
 - Add Python tests to SMTP suite
 - Improve Squeak/Smalltalk implementation
 - Define base of Ports lang impl and implement the core Scheme procedures
 - Implement library mechanism
 - Ruby / Java implementations?
 - Test suite for Ports itself?
 - Integrate JSONSuite

## Design Challenges
 - Challenge: Server response is an error, or client throws an error -> To which extent should the test suite distinguish between the two?
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
