(begin

    ;
    ; Standard library
    ;

    (define-macro and (lambda args 
        (if (null? args) #t
            (if (= (length args) 1) (car args)
                `(if ,(car args) (and ,@(cdr args)) #f)))))

    (define-macro or (lambda args 
        (if (null? args) #t
            (if (= (length args) 1) (car args)
                `(if (not ,(car args)) (or ,@(cdr args)) #t)))))

    (define (reverse lst)
        (define (reverse-help lst res)
            (if (null? lst) res
                (reverse-help (cdr lst) (cons (car lst) res))))
        (reverse-help lst '()))

    (define (filter pred lst)
        (define (filter-help pred lst res)
            (if (null? lst) 
                res
                (if (pred (car lst)) 
                    (filter-help pred (cdr lst)  (cons (car lst) res))
                    (filter-help pred (cdr lst)  res))))
        (reverse (filter-help pred lst '())))

    ; copied from Gauche
    (define (fold-right f init seq) 
        (if (null? seq) 
            init 
            (f (car seq) 
                (fold-right f init (cdr seq)))))

    ; copied from Gauche
    (define (fold-left f init seq) 
        (if (null? seq) 
            init 
            (fold-left f 
                (f init (car seq)) 
                (cdr seq))))  

    (define (member element list)
        (any?
            (lambda (x) (equal? x element))
            list))

    (define (unique-list? lst)
        (if (null? lst) true
            (if 
                (member (car lst) (cdr lst)) 
                false
                (unique-list? (cdr lst)))))

    (define (empty? lst)
        (= 0 (length lst)))

    (define (empty-or-null? lst-or-null)
        (or (empty? lst-or-null) (null? lst-or-null)))

    ; Some of the convenience procedures for accessing list elements as provided by SRFI-1
    (define (last list) (car (reverse list)))
    (define (first list) (car list))
    (define (second list) (list-ref list 1))
    (define (third list) (list-ref list 2))
    (define (fourth list) (list-ref list 3))
    (define (fifth list) (list-ref list 4))
    (define (sixth list) (list-ref list 5))
    (define (seventh list) (list-ref list 6))
    (define (eigth list) (list-ref list 7))
    (define (ninth list) (list-ref list 8))
    (define (tenth list) (list-ref list 9))
    
    (define string-join (lambda args ; accepts a list of strings and an optional delimiter
        (let 
            ((str-list (first args))
             (delimiter (if (= (length args) 2) (car (cdr args)) "")))
            (fold-left 
                (lambda (acc x) (string-append acc delimiter x))
                (car str-list) 
                (cdr str-list)))))

    (define (string-prefix? prefix string)
        (if (empty? prefix)
            #t
            (if (empty? string)
                #f
                (if (= (car prefix) (car string))
                    (string-prefix? (cdr prefix) (cdr string))
                    #f))))

    (define (string-prefix-ci? prefix string)
        (string-prefix? (string-downcase prefix) (string-downcase string)))
    
    (define (any? pred lst)
        (if (null? lst) #f
            (if (pred (car lst)) 
                #t
                (any? pred (cdr lst)))))

    (define (all? pred lst)
        (if (null? lst) #t
            (if (pred (car lst)) 
                (all? pred (cdr lst))
                #f)))


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
)
