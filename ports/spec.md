# PorTS Spec

## Lang 

PorTS is a Scheme implementation that is compatible with R7RS-small, but does not, by design, implement all of R7RS-small.

### (TODO) Syntax


### Special Forms / Primitive Forms
A PorTS language implementation should implement the following special forms:
 - if
 - quote
 - cond
 - set!
 - variable-unset!
 - define
 - lambda
 - begin
 - define-macro
 - include (loads file relative to CWD)

### Macro Features
PorTS does not support hygenic macros, as we expect macros to be almost exclusively used in standard library definitions.

- unquote
- unquote splicing

### Required Primitive Procedures
- cons
- car, cdr
- pair?
- list
- list-ref, list-set?
- list?
- equal?, eq?
- error
- raise
- with-exception-handler
- number->string
- null?
- symbol?
- boolean?
- display
- not
- +, -, *, /
- >, <, >=, <=, =
- abs
- length
<!-- - apply? -->

<!-- 
Should be ported to PorTS
- length
- append
- string-append
- string-upcase
- string-downcase
- string-index, string-replace, string-trim
- char-whitespace?
-->

### Core Procedures
PorTS aims to implement as many core procedures in PorTS. Language implementors may choose to override the PorTS version with a primitive version for performance or compatibility reasons.

A PorTS interpreter implementation should load the core procedures in the following order:
 1. required primitive procedures
 2. PorTS versions of core procedures
 3. primitive versions of core procedures

### Data Types
- Numeric: Integer, Fraction
- String (Chars are single item Strings) (full Unicode)
- Symbol
- List
- Pair
- Boolean

## Library Backend