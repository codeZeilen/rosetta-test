import { suite } from './rosetta-test.js';
import { URL } from 'url';

const urlParsingSuite = suite("stdlib url parsing", "rosetta-test-suites/url-parsing-rfc.ros");

urlParsingSuite.placeholder("url-parse", (env, urlString) => {
    try {
        return new URL(urlString);
    } catch (e) {
        return e;
    }
});

urlParsingSuite.placeholder("parse-error?", (env, parseResult) => {
    return parseResult instanceof Error;
});

urlParsingSuite.placeholder("url-scheme", (env, parseResult) => { 
    // WhatWG protocol is the scheme without the colon
    return parseResult instanceof URL ? parseResult.protocol.replace(':', '') : "";
});

urlParsingSuite.placeholder("url-authority", (env, parseResult) => {
    return parseResult instanceof URL ? parseResult.host : "";
});

// Running
urlParsingSuite.run({
    expectedFailures: ["test_ipv6_host"], 
    excludeCapabilities: ["root.authority"]});
