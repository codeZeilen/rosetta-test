import { suite } from './ports.js';
import { URL } from 'url';

const urlParsingSuite = suite("suites/url-parsing-RFC.ports");

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
    return parseResult instanceof URL ? parseResult.protocol.replace(':', '') : "";
});

urlParsingSuite.placeholder("url-authority", (env, parseResult) => {
    return parseResult instanceof URL ? parseResult.host : "";
});

// Running
urlParsingSuite.run();
