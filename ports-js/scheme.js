import { parseWithoutExpand } from './parser.js';


function evalSchemeString(str) {
    return evalScheme(parseWithoutExpand(str));
}

function evalScheme(list) {
    return "hello"
}

console.log(evalSchemeString("(+ 1 2)"))

