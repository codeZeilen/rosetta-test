import urllib.parse
import rosetta
import urllib 

suite = rosetta.suite("rosetta-test-suites/url-parsing-rfc.ros")

@suite.placeholder("url-parse")
def url_parse(env, url_string):
    try:
        return urllib.parse.urlparse(url_string)
    except ValueError as e:
        return e

@suite.placeholder("parse-error?")
def parse_error(env, parse_result):
    return isinstance(parse_result, Exception)

@suite.placeholder("url-scheme")
def url_scheme(env, parse_result: urllib.parse.ParseResult):
    return parse_result.scheme or ""

@suite.placeholder("url-authority")
def url_authority(env, parse_result: urllib.parse.ParseResult):
    return parse_result.netloc or ""

#
# Running
#

suite.run()