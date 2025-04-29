import { suite } from "./rosetta-test.js";
import { readdirSync, readFileSync } from "fs";
import path from "path";

const jsonSuite = suite("rosetta-test-suites/json-rfc.ros");

jsonSuite.placeholder("list-json-test-files", (env) => {
    // List the files in the suites/json-rfc-fixtures directory ending with .json
    const directory = path.join('rosetta-test-suites', 'json-rfc-fixtures');
    
    try {
        return readdirSync(directory).filter(file => file.endsWith('.json'));
        
    } catch (error) {
        console.error("Error reading JSON test files:", error);
        return [];
    }
});

jsonSuite.placeholder("file-contents", (env, fileName) => {
    try {
        return readFileSync(path.join("rosetta-test-suites", "json-rfc-fixtures", fileName), "utf8");
    } catch (error) {
        console.error("Error reading file:", error);
        return "";
    }
});

jsonSuite.placeholder("parse", (env, jsonString) => {
    try {
        return JSON.parse(jsonString);
    } catch (error) {
        return error;
    }
});

jsonSuite.placeholder("parse-success?", (env, parsed) => {
    return !(parsed instanceof Error);
});

jsonSuite.run();