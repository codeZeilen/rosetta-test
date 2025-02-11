# PorTS [![Python Suites](https://github.com/codeZeilen/ports-prototype/actions/workflows/python-suites.yml/badge.svg)](https://github.com/codeZeilen/ports-prototype/actions/workflows/python-suites.yml)

With the PorTS project, you only have to write a test suite once for multiple implementations.


## Trying it out

Currently, the best-supported language is Python. To get an idea of how to create and port PorTS test suites, try the Python version of the SMTP test suite, which runs against the SMTP implementation in the Python standard library.

You can run the SMTP test suite in Python by executing

```Python
python3 ports-py/smtp.py
```

This will run the test suite from `/suites/smtp.ports` using the mappings in `/ports-py/smtp.py`.


## Structure of the Repository

- The core PorTS language (`/ports`)
- PorTS interpreters for Python (`/ports-py`) and Smalltalk (`/ports-s`)
- A full test suite for SMTP (`/suites/smtp.ports`)
- A prototype test suite for file handlers (`/suites/fs.ports`)


## How it Works (Overview)

The test suites are written in the PorTS language. The parts that are implementation-specific are designated as _placeholders_. For every implementation that you want to test, you need to fill in these placeholders.

Thus, if you want to execute a PorTS suite for your project, you need:

  1. A _PorTS interpreter_ for your language
  2. A _mapping_ that fills each placeholder with a function from the implementation. Often the mapping will not be 1:1, so you might need to write additional code to map the behavior to the expected behavior of the placeholder.


## Acknowledgements
- Syntax tests based on the corpus from [tree-sitter-scheme](https://github.com/6cdh/tree-sitter-scheme)