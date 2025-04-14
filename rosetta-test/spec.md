# RosettaTest Spec

## Lang 

RosettaTestLang is a Scheme implementation that is compatible with R7RS-small, but does not, by design, implement all of R7RS-small.

### (TODO) Syntax


### Special Forms / Primitive Forms
A RosettaTestLang implementation should implement the following special forms:
 - if
 - quote
 - cond
 - set!
 - define
 - lambda
 - begin
 - define-macro
 - include (loads file relative to CWD)

### Macro Features
RosettaTestLang does not support hygenic macros, as we expect macros to be almost exclusively used in standard library definitions.

- unquote
- unquote splicing

### Required Primitive Procedures
- cons
- car, cdr
- pair?
- list
- list-ref, list-set!
- list?
- equal?, eq?
- error
- raise
- with-exception-handler
- number->string
- null?
- symbol?
- boolean?
- display (Should not print newline after the string)
- not
- +, -, *, /
- >, <, >=, <=, =
- abs
- length
- exit 
- make-hash-table, hash-table? (All hash-table related primitives are based on srfi-69)
- hash-table-set!
- hash-table-ref-prim (Should only access the value from the dictionary and do nothing else, the correct handling of missing keys and default values is implemented in the standard lib)
- hash-table-delete!
- hash-table-keys, hash-table-values

<!-- - apply? -->

<!-- 
Should be ported to RosettaTestLang
- length
- append
- string-append
- string-upcase
- string-downcase
- string-split
- string-index str, substr: return index of first occurrence of substr, False if not found at all
- string-replace
- string-trim
- char-whitespace?
-->

### Core Procedures
RosettaTestLang aims to implement as many core procedures in RosettaTestLang. Language implementors may choose to override the RosettaTestLang version with a primitive version for performance or compatibility reasons.

A RosettaTestLang interpreter implementation should load the core procedures in the following order into the global environment:
 1. required primitive procedures
 2. RosettaTestLang versions of core procedures
 3. (optional) primitive versions of core procedures

### Data Types
- Numeric: Integer, Fraction
- String (Chars are single item Strings) (full Unicode)
- Symbol
- List
- Pair
- Boolean


## RosettaTest Library

### Required mechanisms
- Declaring which suite is to be used
- Filling placeholders, e.g. by implementing methods and adding annotations, or a dictionary mapping placeholder names to function identifiers
- Starting the execution of the test suite, by calling `run-suite` with the required parameters


### Optional mechanisms
- Warning when placeholders are not defined
- Proposing snippets to fill placeholders quickly
- Selecting/excluding tests and capabilities (only, exclude for tests and capabilities) to denote that a certain features is not supported at all
- Expected failures to denote that a feature should be supported but is currently not passing the marked tests
- Integration with host test runner


### Required interface from the RosettaTest Library
- Loading the rosetta-test.scm definitions
- Defining primitives
 - assert
 - is-assertion-error?
 - create-placeholder
 - is-placeholder?
 - thread
 - thread-wait-for-completion
 - thread-sleep!
 - thread-yield