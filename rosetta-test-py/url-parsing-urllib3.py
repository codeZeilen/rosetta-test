import rosetta
import urllib3 

suite = rosetta.suite("rosetta-test-suites/url-parsing-rfc.ros")

@suite.placeholder("url-parse")
def url_parse(env, url_string):
    try:
        return urllib3.util.parse_url(url_string)
    except ValueError as e:
        return e

@suite.placeholder("parse-error?")
def parse_error(env, parse_result):
    return isinstance(parse_result, Exception)

@suite.placeholder("url-scheme")
def url_scheme(env, parse_result: urllib3.util.Url):
    return parse_result.scheme or ""

@suite.placeholder("url-authority")
def url_authority(env, parse_result: urllib3.util.Url):
    return parse_result.authority or ""

#
# Running
#

suite.run()