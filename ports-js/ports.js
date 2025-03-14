import { readFileSync } from 'fs';
import { Sym, Env, globalEnv, Procedure, evalSchemeString, asString } from './scheme.js';
import path from 'path';

class PortsFunction {
    constructor(func, env) {
        this.function = func;
        this.env = env;
    }
    
    isValid() {
        return this.function != null;
    }

    call(that, ...args) {
        return this.function(this.env, ...args);
    }
    
    get(key) {
        if (key === 0) {
            return Sym(this.portsRole());
        } else if (key === 1) {
            return this;
        } else {
            return null;
        }
    }
}

class PortsSetup extends PortsFunction {
    portsRole() {
        return "setup";
    }
}

class PortsTearDown extends PortsFunction {
    portsRole() {
        return "tearDown";
    }
}

class Placeholder extends PortsFunction {
    constructor(name, parameters, docString) {
        super(null, null);
        this.name = name;
        this.parameters = parameters;
        this.docString = docString;
    }
    
    get(key) {
        if (key === 0) {
            return Sym("placeholder");
        } else {
            return null;
        }
    }
}

class PortsAssertionError extends Error {
    constructor(message) {
        super(message);
        this.name = "PortsAssertionError";
    }
}

function portsAssert(value, msg = "") {
    if (!value) throw new PortsAssertionError(msg || "Assertion failed");
}

function portsAssertEq(expected, actual) {
    if (expected !== actual) throw new PortsAssertionError(`${expected} != ${actual}`);
}

class PortsSuite {
    constructor(fileName) {
        this.schemeEnv = new Env([],[], globalEnv);
        this.initializePortsPrimitives();
        this.initializePorts();
        this.suiteSource = readFileSync(fileName, 'utf8');
        
        this.suiteName = null;
        this.suiteVersion = null;
        this.sources = null;
        this.placeholders = null;
        this.rootCapability = null;
        
        this.placeholderFunctions = {};
        this.setUpFunctions = [];
        this.tearDownFunctions = [];
    }

    initializeSuite() {
        [this.suiteName, this.suiteVersion, this.sources, 
         this.placeholders, this.rootCapability] = this.evalScheme(this.suiteSource);
    }

    evalScheme(code, env = null) {
        if (!env) {
            env = this.schemeEnv;
        }
        return evalSchemeString(code, env);
    }

    evalSchemeWithArgs(code, kwargs) {
        const env = new Env([], [], this.schemeEnv);
        Object.entries(kwargs).forEach(([key, value]) => {
            env.set(Sym(key), value);
        });
        return this.evalScheme(code, env);
    }

    createPlaceholder(name, parameters, docString = "") {
        const newPlaceholder = new Placeholder(name, parameters, docString);
        this.schemeEnv.set(name, newPlaceholder);
        newPlaceholder.env = this.schemeEnv;
        
        if (this.placeholderFunctions[name]) {
            newPlaceholder.function = this.placeholderFunctions[name];
        }
        
        return newPlaceholder;
    }

    initializePortsPrimitives() {
        const primitives = {
            "create-placeholder": (...args) => this.createPlaceholder(...args),
            "is-placeholder?": x => x instanceof Placeholder,
            "assert": portsAssert,
            "assert-equal": portsAssertEq,
            "is-assertion-error?": e => {return e instanceof PortsAssertionError},
       };
        
        Object.keys(primitives).forEach((key) => {
            this.schemeEnv.set(Sym(key), primitives[key]);
        });
    }

    initializePorts() {
        const portsContent = readFileSync("ports/ports.scm", "utf8");
        this.evalScheme(portsContent);
    }

    placeholder(name, func) {
        this.placeholderFunctions[Sym(name)] = func;
        return func;
    }

    setUp(func) {
        this.setUpFunctions.push(func);
        return func;
    }

    tearDown(func) {
        this.tearDownFunctions.push(func);
        return func;
    }

    ensurePlaceholdersAreValid() {
        const invalidPlaceholders = this.placeholders.filter(p => !p.isValid());
        if (invalidPlaceholders.length > 0) {
            const invalidPlaceholderList = invalidPlaceholders.map(p => `- ${asString(p.name)}`).join("\n");
            const invalidPlaceholdersSuggestion = invalidPlaceholders.map(
                p => `suite.placeholder("${asString(p.name)}",\n\tfunction ${asString(p.name).replace(/-/g, '_')}(env, ...args) {\n\t// Implementation needed\n});`
            ).join("\n\n");
            
            throw new Error(`Empty placeholders:\n${invalidPlaceholderList}\n\nFix based on:\n${invalidPlaceholdersSuggestion}`);
        }
    }
inval
    installSetUpTearDownFunctions() {
        this.setUpFunctions.forEach(func => {
            this.rootCapability[2].unshift(new PortsSetup(func, this.schemeEnv));
        });
        this.tearDownFunctions.forEach(func => {
            this.rootCapability[3].unshift(new PortsTearDown(func, this.schemeEnv));
        });
    }

    run({only = null, onlyCapabilities = null, exclude = null, excludeCapabilities = null, expectedFailures = []} = {}) {
        this.initializeSuite();
        this.installSetUpTearDownFunctions();
        this.ensurePlaceholdersAreValid();
        
        // We set the root-capability in the env, as we need it repeatedly
        this.schemeEnv.set(Sym("root-capability"), this.rootCapability);

        this.evalSchemeWithArgs(
            "(run-suite suite_name suite_version root-capability only_tests only_capabilities exclude exclude_capabilities expected_failures)", 
            {suite_name: this.suiteName,
            suite_version: this.suiteVersion,
            only_tests: only, 
            only_capabilities: onlyCapabilities, 
            exclude: exclude, 
            exclude_capabilities: excludeCapabilities,
            expected_failures: expectedFailures});
    }
}

export function suite(fileName) {
    return new PortsSuite(fileName);
}

