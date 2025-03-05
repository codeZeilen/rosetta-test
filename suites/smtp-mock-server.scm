(begin    
    (define server '())
    (define (server-thread server) (list-ref server 1))
    (define (server-socket server) (list-ref server 2))
    (define (server-port server) (socket-port (list-ref server 2)))
    (define (server-stopped? server) (list-ref server 3))
    (define (server-extensions server) (list-ref server 4))
    (define (server-response-codes server) (list-ref server 5))
    (define (server-command-response-codes server) (list-ref server 6))
    (define (server-auths server) (list-ref server 7))
    (define (server-requests server) (list-ref server 8))
    (define (server-tls? server) (list-ref server 9))
    (define (server-tls-started? server) (list-ref server 10)) ; Was a TLS connection started via STARTTLS?
    (define (server-auth-proc server) (list-ref server 11))
    (define (server-message-data server) (list-ref server 12))

    (define (server-set-thread! server new-thread) 
        (list-set! server 1 new-thread))
    (define (server-set-socket! server new-socket) 
        (list-set! server 2 new-socket))
    (define (server-set-extensions! server new-extensions) 
        (list-set! server 4 new-extensions))
    (define (server-set-response-codes! server new-codes) 
        (list-set! server 5 new-codes))
    (define (server-set-command-response-codes! server new-codes) 
        (list-set! server 6 new-codes))
    (define (server-set-auths! server new-auths) 
        (list-set! server 7 new-auths))
    (define (server-set-requests! server new-requests) 
        (list-set! server 8 new-requests))
    (define (server-enable-tls server) 
        (list-set! server 9 #t))
    (define (server-disable-tls server) 
        (list-set! server 9 #f))
    (define (server-set-tls-started! server boolean) 
        (list-set! server 10 boolean))
    (define (server-set-auth-proc! server proc)
        (list-set! server 11 proc))
    (define (server-set-message-data! server data)
        (list-set! server 12 data))

    (define (server-extensions-with-auth server) 
        (if (empty? (server-auths server))
            (server-extensions server)
            (append 
                (server-extensions server)
                (list (fold-left 
                    (lambda (acc auth-name) (string-append acc " " auth-name))
                    "AUTH"
                    (map
                        (lambda (auth) (car auth))
                        (server-auths server)))))))
    (define (server-auth-methods server)
        (map 
            car
            (server-auths server)))

    ; Mock response codes can be set in three different ways:
    ; 1. By setting response code to be used indefinitely (server-set-response-code! server "250 ")
    ; 2. By setting response code for a specific command indefinitely (server-set-command-response-code! server "EHLO" "250 ")
    ; 3. By adding a response code to the list of response codes (server-add-response-code! server "250 "), 
    ;     which will be used in order and removed from the list
    ; Sets response code to be used indefinitely
    (define (server-set-response-code! server new-code) 
        (server-set-response-codes! server new-code))
    (define (server-set-command-response-code! server command new-code)
        (let
            ((response-pair (assq command (server-command-response-codes server))))
            (if (not response-pair)
                (server-set-command-response-codes! server (append (server-command-response-codes server) (list (cons command new-code))))
                (list-set! response-pair 1 new-code))))
    (define (server-add-response-code! server new-code) 
        (server-set-response-codes! server (append (server-response-codes server) (list new-code))))
    (define (server-has-response-code? server)
        (not (empty? (server-response-codes server))))
    (define (server-has-command-response-code? server command)
        (or 
            (list? (assq command (server-command-response-codes server)))
            (server-has-response-code? server)))
    (define (server-next-command-response-code server command)
        (let
            ((response-pair (assq command (server-command-response-codes server))))
            (if (list? response-pair)
                (cdr response-pair)
                (server-next-response-code server))))
    (define (server-next-response-code server) 
        (let 
            ((response-codes (server-response-codes server)))
            (if (list? response-codes)
                (if (empty? response-codes)
                    (raise (error "No response codes available"))
                    (begin
                        (server-set-response-codes! server (cdr response-codes))
                        (car response-codes)))
                response-codes))) ; Single response code
    (define (let-server-complete-handler)
        (thread-sleep! 0.1))

    (define (create-server tls-enabled) (list 'server '() '() #f '() '() '() '() '() tls-enabled #f (lambda (credentials connection success failure) '()) ""))
    (define (server-stop server) (list-set! server 3 #t))
    (define (server-start server)
        (let 
            ((socket (create-socket)))
            (server-set-socket!
                server
                socket)
            (server-set-thread! 
                server
                (thread (lambda () 
                    (run-mock-smtp-server server))))
            server))

    (define (start-mock-server)
        (server-start (create-server #f)))
    (define (stop-mock-server) (begin
        (server-stop server)
        (thread-wait-for-completion (server-thread server))))

    (define (run-mock-smtp-server server)
        (begin
            (define CA_FILE "./smtp-fixtures/cacert.pem")
            (define CERT_FILE "./smtp-fixtures/server.pem")
            (define KEY_FILE "./smtp-fixtures/server.key")
            (define connection '())
            (define (init) (begin 
                (set! 
                    connection 
                    (if (server-tls? server)
                        (secure-server-socket-wrap (socket-accept (server-socket server)) CA_FILE CERT_FILE KEY_FILE #t) 
                        (socket-accept (server-socket server))))
                (if (null? connection)
                    #f
                    (begin 
                        (socket-write connection "220 OK\r\n")
                        #t))))
            (define (close-sockets) (begin 
                (socket-close connection)
                (socket-close (server-socket server))))
            (define (write-prepared-response-code-else command alternative-branch) 
                (if (server-has-command-response-code? server command) 
                    (socket-write connection (string-append (server-next-command-response-code server command) "\r\n")) 
                    (alternative-branch)))
            (define (handle request-string) (begin
                ; Log the request
                (server-set-requests! 
                    server 
                    (append (server-requests server) (list (string-trim request-string))))
                ; Handle the request
                (let
                    ((command (string-upcase (request-command request-string)))
                        (args (request-arguments request-string)))
                    (write-prepared-response-code-else
                        command
                        (lambda ()
                            (cond 
                                ((= command "EHLO") (ehlo (car args)))
                                ((= command "AUTH") (auth args))
                                ((= command "MAIL") (mail args))
                                ((= command "RCPT") (rcpt args))
                                ((= command "VRFY") (vrfy args))
                                ((= command "DATA") (data-command args))
                                ((= command "STARTTLS") (starttls args))
                                ((= command "QUIT") (quit))
                                ((= command "RSET") (rset))
                                (else (error "Command not found"))))))))
            (define (loop) (let 
                ((request-string (socket-receive connection)))
                (if (empty? request-string)
                    (close-sockets)
                    (begin
                        (handle request-string)
                        (if (server-stopped? server)
                            (close-sockets)
                            (loop))))))
            (define (mail args)
                (if (or (empty? args) (= (second (string-split (car args) ":")) "<invalid>"))
                    (socket-write connection "500\r\n")
                    (socket-write connection "250 2.1.0 OK\r\n")))
            (define (rcpt args)
                (if (or (empty? args) (= (second (string-split (car args) ":")) "<invalid>"))
                    (socket-write connection "500\r\n")
                    (socket-write connection "250 2.1.0 OK\r\n")))
            (define (vrfy args)
                (socket-write connection "250\r\n"))
            (define (quit) 
                (socket-write connection "221 Bye\r\n"))
            (define (rset)
                (socket-write connection "250 2.0.0 OK\r\n"))
            (define (data-command args)
                (define (receive-all-data)
                    (let 
                        ((message-data (socket-receive connection))) 
                        (server-set-message-data! server (string-append (server-message-data server) message-data))
                        (if (not (or (string-suffix? "\r\n.\r\n" message-data) (= ".\r\n" message-data)))
                            (receive-all-data))))
                (write-prepared-response-code-else
                    "DATA"
                    (lambda ()
                        (socket-write connection "354 End data with <CR><LF>.<CR><LF>\r\n")))
                (receive-all-data)
                (write-prepared-response-code-else 
                    "DATA"
                    (lambda () 
                        (socket-write connection "250 2.0.0 OK\r\n"))))
            (define (starttls args)
                (socket-write connection "220 Ready to start TLS\r\n")
                (let 
                    ((secure-socket (secure-server-socket-wrap connection CA_FILE CERT_FILE KEY_FILE #t)))
                    (server-set-tls-started! server #t)
                    (set! connection secure-socket)))
            (define (auth args)
                (define (write-auth-failure-response) 
                    (socket-write connection "535 5.7.8  Authentication credentials invalid\r\n"))
                (define (write-auth-success-response) 
                    (socket-write connection "235 2.7.0 Authentication successful\r\n"))
                (let 
                    ((method (string-upcase (car args)))
                        (initial-response (if (> (length args) 1) (second args) "")))
                    (if (and 
                            (member method '("PLAIN" "LOGIN" "XOAUTH2" "CRAM-MD5")) ; Check whether we support auth method at all
                            (member method (server-auth-methods server))) ; Check whether auth method is listed
                        ((server-auth-proc server) 
                            initial-response 
                            connection
                            write-auth-success-response 
                            write-auth-failure-response)
                        ; else case to capture non-supported methods early RFC 4954 - Section 4
                        (socket-write connection "504 5.5.4 Command not implemented\r\n"))))
            (define (ehlo answer) 
                (define (replace-last list element) (reverse (cons element (cdr (reverse list)))))
                (let 
                    ((answers (fold-left 
                        (lambda (acc extension)
                            (append acc (list (string-append "250-" extension "\r\n"))))
                        (list (string-append "250-" answer "\r\n"))
                        (server-extensions-with-auth server))))
                    (let 
                        ((answers-text (string-join 
                            (replace-last 
                                answers
                                (string-replace "250-" "250 " (last answers)))))) 
                        (socket-write 
                            connection 
                            answers-text))))

            (if (init) (loop))))
            
    ; Custom server-related assertions and predicates
    ;

    (define (assert-extensions server response extensions) (= extensions (smtp-extensions server response)))

    ; Tests whether request 1 corresponds to request 2 (ignoring case)
    (define (request-equal? request1 request2)
        (let
            ((request1-command (string-upcase (request-command request1)))
                (request1-arguments (request-arguments request1))
                (request2-command (string-upcase (request-command request2)))
                (request2-arguments (request-arguments request2)))
            (and 
                (= request1-command request2-command)
                (= request1-arguments request2-arguments))))

    ; Asserts whether the last request matches the given one ignoring case for the command part
    (define (assert-last-request server request) 
        (assert (request-equal? (last (server-requests server)) request)))

    (define (server-includes-request server request) 
        (not (empty? (filter 
                (lambda (req) (request-equal? req request)) 
                (server-requests server)))))

    (define (assert-any-request server request) 
        (assert 
            (server-includes-request server request) 
            (string-append "Expected request " request " but got " (server-requests server))))
            
    ; Get command from a request
    (define (request-command request) (string-trim (car (string-split request " "))))

    ; Get arguments from a request
    (define (request-arguments request) (map string-trim (cdr (string-split request " "))))

    ; Get all recorded requests with a certain command
    (define (server-requests-with-command server command) 
                    (filter 
                        (lambda (request) 
                            (= (string-upcase (request-command request)) command))
                        (server-requests server))))