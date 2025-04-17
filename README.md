# RosettaTest [![Python Suites](https://github.com/codeZeilen/rosetta-test/actions/workflows/python-suites.yml/badge.svg)](https://github.com/codeZeilen/rosetta-test/actions/workflows/python-suites.yml)

With the RosettaTest project, you only have to write a test suite once for multiple implementations.

(This is still a prototype project. Expect major architectural or API changes, as well as major bugs and inconsistencies.)

## Trying it out

Currently, the best-supported language is Python. To get an idea of how to create and port RosettaTest suites, try the Python version of the SMTP test suite, which runs against the SMTP implementation in the Python standard library.

You can run the SMTP test suite in Python by executing:

```Python
python3 rosetta-test-py/smtp.py
```

This will run the test suite from `/rosetta-test-suites/smtp.rosetta` using the mappings in `/rosetta-test-py/smtp.py`.


## Structure of the Repository

- The core RosettaTest language (`/rosetta-test`)
- RosettaTest language interpreters for 
  - Python (`/rosetta-test-py`) 
  - Ruby (`/rosetta-test-rb`)
  - JavaScript (`/rosetta-test-js`)
  - Smalltalk (`/rosetta-test-s`)
- A full test suite (`/rosetta-test-suites`) for 
  - SMTP (`smtp.rosetta`)
  - RFC JSON parsing (`json-rfc.rosetta`)
- Prototype test suites (`/rosetta-test-suites`) for 
  - sending MIME documents (`sendmail.rosetta`) 
  - RFC URI parsing (`url-parsing-rfc.rosetta`)


## How it Works (Overview)

The test suites are written in the RosettaTest language. The parts that are implementation-specific are designated as _placeholders_. For every implementation that you want to test, you need to fill in these placeholders.

Thus, if you want to execute a RosettaTest suite for your project, you need:

  1. A _RosettaTest language interpreter_ for your language
  2. A _mapping_ that fills each placeholder with a function from the implementation. Often the mapping will not be 1:1, so you might need to write additional code to map the behavior to the expected behavior of the placeholder.


## Acknowledgements
- Syntax tests based on the corpus from [tree-sitter-scheme](https://github.com/6cdh/tree-sitter-scheme)
- JSON-RFC Suite tests are based on the [JSONTestSuite](https://github.com/nst/JSONTestSuite)
