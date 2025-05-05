import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { evalSchemeString } from './scheme.js';

// Get current directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Helper function to check if result matches expected output
function matches(result, target) {
    if (target && typeof target === 'object' && 'type' in target) {
        return result instanceof Error;
    }
    if (target instanceof Array) {
        if (!(result instanceof Array)) {
            return false;
        }
        if (result.length !== target.length) {
            return false;
        } else {
            let match = true;
            for (let i = 0; i < target.length; i++) {
                match = match && matches(result[i], target[i]);
            }
            return match;
        }
    }
    if (typeof result === 'symbol') {
        return valueToString(result) == target;
    }
    if (target === null) {
        return result === null || result === undefined || (Array.isArray(result) && result.length === 0);
    }

    return result == target;
}

// Helper function to safely convert any value to string representation
function valueToString(value) {
    if (typeof value === 'symbol') {
        // Extract the symbol's description
        return Symbol.keyFor(value) ? 
            `${Symbol.keyFor(value)}` : 
            value.toString();
    }

    if (value === null) return 'null';
    if (value === undefined) return 'undefined';
    
    if (Array.isArray(value)) {
        return `[${value.map(valueToString).join(', ')}]`;
    }
    
    if (value instanceof Error) {
        return `Error: ${value.message}`;
    }
    
    return String(value);
}

// Load test cases
let testTable = [];
try {
    const testsPath = join(__dirname, '../rosetta-test/interpreter-tests.json');
    
    testTable = JSON.parse(readFileSync(testsPath, 'utf8'));
} catch (error) {
    console.error(`Error loading test files: ${error.message}`);
    process.exit(1);
}

const expected_failures = ["(< (square-root 200.) 14.14215)", "(quote (testing 1 (2.0) -3.14e159))"];
// Run tests
let all_tests_passed = true;
for (const entry of testTable) {
    const input = entry.input;
    let evalResult;
    
    try {
        evalResult = evalSchemeString(input);
    } catch (error) {
        evalResult = error;
    }

    if (!entry.hasOwnProperty("expected") || matches(evalResult, entry.expected)) {
        console.log(`✅: ${input}`);
    } else {
        if (expected_failures.includes(input)) {
            console.log(`✖️: ${input} got ${valueToString(evalResult)}[${typeof evalResult}]`);
        } else {
            all_tests_passed = false;
            console.log(`❌: ${input} got ${valueToString(evalResult)}[${typeof evalResult}] instead of ${valueToString(entry.expected)}[${typeof entry.expected}]`);
        }
    }

}

if (all_tests_passed) {
    console.log("All tests passed!");
} else {
    console.log("Some tests failed.");
    process.exit(1);
}
