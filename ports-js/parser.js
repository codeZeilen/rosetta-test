import { readFileSync } from 'fs';
import URL from 'url';


function tokenize(expression) {
    const pattern = /\s*(,@|[('`,)]|"(?:[\\].|[^\\"])*"|;.*|[^\s('"`;,)]*)(.*)/;
    let matcher;
    const tokens = [];
    let part;
    
    for (const line of expression.split('\n')) {
        part = line;
        matcher = part.match(pattern);
        while (matcher && matcher[0] !== '') {
            const token = matcher[1];
            if (token && token !== '' && !token.startsWith(';')) {
                tokens.push(token);
            }
            part = matcher[2];
            matcher = part.match(pattern);
        }
    }
    return tokens;
};

function parseTokens(tokens) {
    if (tokens.length === 0) {
        return [];
    }

    const token = tokens.shift();
    if (token === '(') {
        const list = [];
        while (tokens[0] !== ')') {
            list.push(parseTokens(tokens));
        }
        tokens.shift();
        return list;
    } else if (token === ')') {
        throw new Error("Unexpected ')'");
    } else if (token === "'") {
        return [Symbol.for("quote"), parseTokens(tokens)];
    } else if (token === "`") {
        return [Symbol.for("quasiquote"), parseTokens(tokens)];
    } else if (token === ",") {
        return [Symbol.for("unquote"), parseTokens(tokens)];
    } else if (token === ",@") {
        return [Symbol.for("unquote-splicing"), parseTokens(tokens)];
    } else {
        return parseAtom(token);
    }
};

function parseAtom(token) {
    // 'Numbers become numbers; #t and #f are booleans; "..." string; otherwise Symbol.'
    const lowerToken = token.toLowerCase();
    if (lowerToken === '#t' || lowerToken === '#true') {
        return true;
    }
    if (lowerToken === '#f' || lowerToken === '#false') {
        return false;
    }
    if (token[0] === '"') {
        const rawString = token.slice(1, -1);
        return rawString.replace(/\\n/g, '\n')
            .replace(/\\r/g, '\r')
            .replace(/\\t/g, '\t');
    }
    
    let numberParseTry = parseInt(token);
    if (!isNaN(numberParseTry) && isFinite(token)) {
        return numberParseTry;
    }
    numberParseTry = parseFloat(token); // TODO: This should try to parse a fraction instead
    if (!isNaN(numberParseTry) && isFinite(token)) {
        return numberParseTry; // Replace Fraction with native float for now
    } 
    return Symbol.for(token); // Use native JavaScript Symbol.for()
};

export function parseWithoutExpand(inputString) {
    const tokens = tokenize(inputString);
    return parseTokens(tokens);
};

function main() {
    const testTable = JSON.parse(readFileSync('ports/syntax-tests.json'));

    function matches(structure, target) {
        if (Array.isArray(target)) {
            if (!Array.isArray(structure)) {
                return false;
            }
            if (structure.length !== target.length) {
                return false;
            } else {
                let result = true;
                for (let i = 0; i < target.length; i++) {
                    result = result && matches(structure[i], target[i]);
                }
                return result;
            }
        } else if (target === "Boolean") {
            return typeof structure === 'boolean';
        } else if (target === "String") {
            return typeof structure === 'string';
        } else if (target === "Character") {
            return typeof structure === 'string' && structure.length === 1;
        } else if (target === "Symbol") {
            return typeof structure === 'symbol';
        } else if (target === "Number") {
            return typeof structure === 'number';
        }
    }
    
    for (const entry of testTable.filter(row => typeof row !== 'string')) {
        const parseResult = parseWithoutExpand(entry[0]);
        if (matches(parseResult, entry[1])) {
            console.log(`✅: ${JSON.stringify(entry)}`);
        } else {
            console.log(`❌: ${JSON.stringify(entry)} got ${JSON.stringify(parseResult)} instead`);
        }
    }     
    console.log("End of test run");
}

// run tests only if started directly
if (import.meta.url.startsWith('file:')) {
    const modulePath = URL.fileURLToPath(import.meta.url);
    if (process.argv[1] === modulePath) {
        main()
    }
  }


