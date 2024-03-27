# PorTS Sketches

This repository contains sketches of PorTS test suites. They are neither complete nor runnable. Their purpose is to explore requirements and pitfalls for the design of the PorTS language.

## Structure

- `fs.ports` and `fs.py`: A sketched test suite for file operations and the corresponding definitions of placeholders in Python. Useful for exploring how the definition of placeholders in a target language may work.
- `mime-type.ports`: A sketched test suite for parsing and querying mime-type strings. Useful for exploring how PorTS may cover a variety of features in one test suite.
- `promises-aplus.ports`: A sketched test suite for the [Promises/A+](https://promisesaplus.com/) specification. Useful for exploring how PorTS handles complex, in this case potentially concurrent, behavior.
