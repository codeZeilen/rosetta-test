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
    const testsPath1 = join(__dirname, '../ports/lispy-tests.json');
    const testsPath2 = join(__dirname, '../ports/lispy-tests2.json');
    
    const tests1 = JSON.parse(readFileSync(testsPath1, 'utf8'));
    testTable = testTable.concat(tests1);
    
    const tests2 = JSON.parse(readFileSync(testsPath2, 'utf8'));
    testTable = testTable.concat(tests2);
} catch (error) {
    console.error(`Error loading test files: ${error.message}`);
    process.exit(1);
}

// Run tests
for (const entry of testTable) {
    const input = entry.input;
    let evalResult;
    
    try {
        evalResult = evalSchemeString(input);
    } catch (error) {
        evalResult = error;
    }
    
    if (matches(evalResult, entry.expected)) {
        console.log(`✅: ${input}`);
    } else {
        console.log(`❌: ${input} got ${valueToString(evalResult)}[${typeof evalResult}] instead of ${valueToString(entry.expected)}[${typeof entry.expected}]`);
    }
}
