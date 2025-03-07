(begin

    ;
    ; PORTS objects
    ;

    ; Suite
    ;

    (define (suite suite-name suite-version suite-sources suite-contents) (let 
        ((root-capability (capability 
                "root"
                (filter (lambda (e) (not (is-placeholder? e))) suite-contents))))
        (capability-set-children-parent! root-capability)
        (list
            suite-name 
            suite-version 
            suite-sources
            (filter is-placeholder? suite-contents) ; placeholder
            root-capability)))
    
    (define (is-capability? element) (and (list? element) (= 'capability (car element))))
    (define (is-test? element) (and (list? element) (or (= 'test (car element)) (is-data-test? element))))
    (define (is-data-test? element) (and (list? element) (= 'data-test (car element))))
    (define (is-setup? element) (and (list? element) (= 'setup (car element))))
    (define (is-tearDown? element) (and (list? element) (= 'tearDown (car element))))

    (define sources (lambda source-triples (
        list 'sources source-triples)))

    ; Placeholder 
    ;

    (define placeholder (lambda placeholder-specs (
        let 
            ((placeholder-spec (car placeholder-specs)) 
            (placeholder-docstring (if (> (length placeholder-specs) 1) 
                (car (cdr placeholder-specs)) 
                "")))
            (create-placeholder
                (car placeholder-spec)
                (cdr placeholder-spec)
                placeholder-docstring))))

    ; Capability 
    ;

    (define (capability name contents) (let
        ((new-capability (list 
            'capability
            name 
            (filter is-setup? contents) ; setup
            (filter is-tearDown? contents) ; tearDown
            (filter is-test? contents) ; tests
            (filter is-capability? contents) ; capabilities
            '()))) ; parent
        (verify-unique-names new-capability)
        (for-each 
            (lambda (test) (test-set-capability! test new-capability)) 
            (capability-tests new-capability))
        new-capability))

    (define (verify-unique-names new-capability) (begin
        (if (not (unique-list? (map test-name (capability-tests new-capability))))
            (raise (error "test names must be unique")))
        (if (not (unique-list? (map capability-name (capability-child-capabilities new-capability))))
            (raise (error 
                (fold-left 
                    (lambda (acc capability) 
                        (string-append acc (capability-name capability) " "))
                    "capability names must be unique:"
                    (capability-child-capabilities new-capability)))))
        (for-each
            verify-unique-names 
            (capability-child-capabilities new-capability))))

    (define (capability-set-children-parent! capability) 
        (for-each 
            (lambda (child-capability) (begin
                (capability-set-parent! child-capability capability)
                (capability-set-children-parent! child-capability))) 
            (capability-child-capabilities capability)))

    (define (capability-name capability) (list-ref capability 1))
    (define (capability-setups capability) (list-ref capability 2))
    (define (capability-tearDowns capability) (list-ref capability 3))
    (define (capability-tests capability) (list-ref capability 4))
    (define (capability-child-capabilities capability) (list-ref capability 5))
    (define (capability-parent capability) (list-ref capability 6))
    (define (capability-set-parent! capability parent-capability) 
        (list-set! capability 6 parent-capability))
    (define (capability-all-tests capability) (fold-left 
        (lambda (acc child-capability) 
            (append acc (capability-all-tests child-capability))) 
        (capability-tests capability) 
        (capability-child-capabilities capability)))
    (define (capability-full-name capability) 
        (if (null? (capability-parent capability))
            (capability-name capability)
            (string-append (capability-full-name (capability-parent capability)) "." (capability-name capability))))
        
    (define (capability-run capability) (begin ; add setup/teardown
        (display (string-append "running capability: " (capability-name capability) "\n"))
        (capability-run-tests capability)
        (capability-run-child-capabilities capability)))

    (define (capability-run-tests capability) (begin 
        (map 
            test-run
            (capability-tests capability))))

    (define (capability-run-child-capabilities capability) (begin
        (map capability-run (capability-child-capabilities capability))))    

    (define (capability-run-setups capability) (begin
        (if (not (null? (capability-parent capability)))
            (capability-run-setups (capability-parent capability))
            '())
        (map setup-run (capability-setups capability))))

    (define (capability-run-tearDowns capability) (begin
        (map tearDown-run (capability-tearDowns capability))
        (if (not (null? (capability-parent capability)))
            (capability-run-tearDowns (capability-parent capability))
            '())))

    ; Test Results 
    ;
    (define (test-result test result-symbol optional-exception) (list
        'test-result
        test
        result-symbol
        optional-exception))

    (define (test-result-test test-result) (list-ref test-result 1))
    (define (test-result-result test-result) (list-ref test-result 2))
    (define (test-result-exception test-result) (list-ref test-result 3))

    (define (is-failure? test-result) (equal? 'failure (test-result-result test-result)))
    (define (is-error? test-result) (equal? 'error (test-result-result test-result)))
    (define (is-success? test-result) (equal? 'success (test-result-result test-result)))

    (define (short-hand-test-result test-result expected-failures)
        (cond
            ((and 
                (is-success? test-result) 
                (member 
                    (test-full-name (test-result-test test-result)) 
                    expected-failures)) 
             "S")
            ((is-success? test-result) ".")
            ((and 
                (is-failure? test-result) 
                (member 
                    (test-full-name (test-result-test test-result)) 
                    expected-failures)) 
             "X")
            ((is-failure? test-result) "F")
            ((is-error? test-result) "E")))

    ; Test 
    ;

    (define (test name test-fn) (list
        'test 
        name 
        test-fn
        '())) ; capability
    (define (test-name test) (list-ref test 1))
    (define (test-fn test) (list-ref test 2))
    (define (test-capability test) (list-ref test 3))
    (define (test-set-capability! test capability) (list-set! test 3 capability))
    (define (test-full-name test)
        (string-join 
            (append
                '("test")
                (map string-trim (string-split (test-name test) " ")))
            "_"))
    (define (test-run test) 
        (if (is-data-test? test)
            (data-test-run test)
            (basic-test-run test)))
    ; TODO: Refactor the following to only have a single run fn that is similar to the data-test fn. Then the basic test run is a special case that has only a single empty data line.
    (define (basic-test-run test) (begin
        (capability-run-setups (test-capability test))
        (with-exception-handler 
            (lambda (e) (begin 
                ; Ensure we run the tear downs
                (capability-run-tearDowns (test-capability test))
                (raise e)))
            (lambda () ((test-fn test))))
        (capability-run-tearDowns (test-capability test))))
    (define (data-test-run test) (for-each
        (lambda (data-line) 
            (capability-run-setups (test-capability test))
            (with-exception-handler 
                (lambda (e) (begin 
                    ; Ensure we run the tear downs
                    (capability-run-tearDowns (test-capability test))
                    (raise e)))
                (lambda () (apply (test-fn test) data-line)))
            (capability-run-tearDowns (test-capability test)))
        (data-test-data test)))

    (define (data-test name data test-fn) 
        (list 'data-test name test-fn '() data))
    (define (data-test-data data-test) (list-ref data-test 4))

    (define (test-run-with-result test) 
        (with-exception-handler 
            (lambda (e) 
                (if (is-assertion-error? e)
                    (test-result test 'failure e)
                    (test-result test 'error e)))
            (lambda () 
                (test-run test)
                (test-result test 'success '()))))

    ; Setup/tearDown 
    ;

    (define (setup setup-fn) (list
        'setup
        setup-fn))
    (define (setup-fn setup) (list-ref setup 1))
    (define (setup-run setup) ((setup-fn setup)))

    (define (tearDown tearDown-fn) (list
        'tearDown
        tearDown-fn))
    (define (tearDown-fn tearDown) (list-ref tearDown 1))
    (define (tearDown-run tearDown) ((tearDown-fn tearDown)))

    ; Executing suites
    ;

    (define (select-tests tests only-tests only-capabilities exclude-tests exclude-capabilities)
        (define (test-capability-identifier-matches test capability-prefix-patterns)
            (any? 
                (lambda (capability-prefix-pattern) 
                    (string-prefix? capability-prefix-pattern (capability-full-name (test-capability test))))
                capability-prefix-patterns))
        (filter 
            (lambda (test)
                (not (or
                    ; The following are exclusion criteria, if one of them applies, the test should be excluded
                    (and only-tests (not (member (test-full-name test) only-tests)))
                    (and only-capabilities (not (test-capability-identifier-matches test only-capabilities)))
                    (and exclude-tests (member (test-full-name test) exclude-tests))
                    (and exclude-capabilities (test-capability-identifier-matches test exclude-capabilities)))))
            tests))

    (define (expected-failures-test-result? test-result expected-failures)
        (member (test-full-name (test-result-test test-result)) expected-failures))

    (define (display-test-results test-results expected-failures)
        (define (is-true-failure? test-result)
            (and 
                (is-failure? test-result) 
                (not (expected-failures-test-result? test-result expected-failures))))
        (define (is-true-error? test-result)
            (and 
                (is-error? test-result) 
                (not (expected-failures-test-result? test-result expected-failures))))
        (define (is-expected-failure? test-result)
            (and 
                (is-failure? test-result) 
                (expected-failures-test-result? test-result expected-failures)))
        (define (is-unexpected-pass? test-result)
            (and 
                (is-success? test-result)
                (expected-failures-test-result? test-result expected-failures)))
        (define (is-true-success? test-result)
            (and 
                (is-success? test-result) 
                (not (expected-failures-test-result? test-result expected-failures))))

        (display "\nTests done - Results\n")
        (let 
            ((successes (filter is-true-success? test-results))
             (failures (filter is-true-failure? test-results))
             (errors (filter is-true-error? test-results))
             (expected-failures (filter is-expected-failure? test-results))
             (unexpected-passes (filter is-unexpected-pass? test-results)))
            
            (display 
                (string-append "Success: " (length successes) ", Failure:" (length failures) ", Errors:" (length errors)))
            (if (not (empty? expected-failures))
                (display (string-append ", Expected failures: " (length expected-failures))))
            (if (not (empty? unexpected-passes))
                (display (string-append ", Unexpected passes: " (length unexpected-passes))))
            (display "\n")

            (define (display-test-result-details test-results info)
                (for-each 
                        (lambda (test-result)
                            (display "- " (string-append (test-full-name (test-result-test test-result)) "\n"))
                            (display (info test-result))
                            (display "\n"))
                        test-results))

            (if (not (empty? failures))
                (begin
                    (display "\nFailures:\n")
                    (display-test-result-details 
                        failures
                        (lambda (test-result) (string-append "\t" (test-result-exception test-result))))))

            (if (not (empty? errors))
                (begin
                    (display "\nFailures:\n")
                    (display-test-result-details 
                        errors
                        (lambda (test-result) (string-append "\t" (test-result-exception test-result))))))

            (if (not (empty? unexpected-passes))
                (begin
                    (display "\nUnexpected Passes:\n")
                    (display-test-result-details 
                        unexpected-passes
                        (lambda (test-result) ""))))
    ))

    (define (run-suite suite-name suite-version root-capability only-tests only-capabilities exclude-tests exclude-capabilities expected-failures)
        (display (string-append "Running suite: " suite-name " " suite-version "\n"))
        (let 
            ((tests (capability-all-tests root-capability)))
            (let 
                ((selected-tests (select-tests tests only-tests only-capabilities exclude-tests exclude-capabilities)))
                (let 
                    ((test-results 
                    (map  
                        (lambda (test)
                            (let ((test-result (test-run-with-result test)))
                                (display (short-hand-test-result test-result expected-failures))
                                test-result))
                        selected-tests)))
                    (display-test-results test-results expected-failures)
                    (if (any? 
                            (lambda (test-result) 
                                (or 
                                    (and (is-failure? test-result) (not (expected-failures-test-result? test-result expected-failures)))
                                    (and (is-error? test-result) (not (expected-failures-test-result? test-result expected-failures)))
                                    (and (is-success? test-result) (expected-failures-test-result? test-result expected-failures)))) 
                            test-results)
                        (exit 1))))))
)
