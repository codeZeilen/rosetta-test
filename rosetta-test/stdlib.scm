(begin

    ;
    ; Standard library
    ;

    ; Boolean
    ;

    (define-macro and (lambda args 
        (if (null? args) #t
            (if (= (length args) 1) (car args)
                `(if ,(car args) (and ,@(cdr args)) #f)))))

    (define-macro or (lambda args 
        (if (null? args) #t
            (if (= (length args) 1) (car args)
                `(if (not ,(car args)) (or ,@(cdr args)) #t)))))

    (define-macro xor (lambda args 
        (if (null? args) #f
            (if (= (length args) 1) (car args)
                `(if (not ,(car args)) (xor ,@(cdr args))
                    (if (not (xor ,@(cdr args))) #t #f))))))

    ; Numeric

    (define (abs number) 
        (if (< number 0) 
            (0 - number) 
            number))

    ; Iteration

    (define (map f lst) 
        (if (empty? lst) 
            '() 
            (cons 
                (f (car lst)) 
                (map f (cdr lst)))))

    (define (for-each f lst) 
        (if (not (empty? lst)) 
            (begin 
                (f (car lst)) 
                (for-each f (cdr lst))))
        '()) ; no return value

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

    (define (count pred lst)
        (length (filter pred lst)))

    ; List manipulation / querying
    ;

    (define (reverse lst)
        (define (reverse-help lst res)
            (if (null? lst) res
                (reverse-help (cdr lst) (cons (car lst) res))))
        (reverse-help lst '()))
    
    (define (member element list)
        (any?
            (lambda (x) (equal? x element))
            list))

    (define (unique-list? lst)
        (if (null? lst) #t
            (if 
                (member (car lst) (cdr lst)) 
                #f
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

    ; Associative lists
    ;
    
    (define alist (lambda args
        (if (not (= 0 (modulo (length args) 2))) 
            (raise (error "alist: odd number of arguments"))
            (begin
                (define (alist-help args res)
                    (if (null? args) res
                        (alist-help (cdr (cdr args)) 
                            (cons (list (car args) (car (cdr args))) res))))
                (alist-help args '())))))

    (define (assq object alist)
        (if (null? alist) 
            #f
            (if (eq? (car (car alist)) object) 
                (car alist)
                (assq object (cdr alist)))))

    (define (assv object alist)
        (if (null? alist) 
            #f
            (if (eqv? (car (car alist)) object) 
                (car alist)
                (assv object (cdr alist)))))

    (define (assoc object alist)
        (if (null? alist) 
            #f
            (if (equal? (car (car alist)) object) 
                (car alist)
                (assoc object (cdr alist)))))

    (define (alist-cons key value alist)
        (if (not (list? alist)) 
            (raise (error "alist-cons: alist is not a list"))
            (cons (list key value) alist)))

    (define (alist-delete key alist)
        (if (null? alist) 
            '()
            (if (equal? (car (car alist)) key) 
                (alist-delete key (cdr alist))
                (cons (car alist) 
                    (alist-delete key (cdr alist))))))
    
    ; Hash-table
    ;

    (define (hash-table-size ht)
        (length (hash-table-keys ht)))

    (define (hash-table-exists? ht key)
        (member key (hash-table-keys ht)))

    (define hash-table-ref (lambda args
        (let 
            ((ht (first args)) 
            (key (second args)))
            (cond
                ((= (length args) 2) (begin
                    (if (hash-table-exists? ht key)
                        (hash-table-ref-prim ht key)
                        (raise (error (string-append "hash-table-ref: " key "is not a key in hash-table " ht))))))
                ((= (length args) 3) (begin
                    (if (hash-table-exists? ht key)
                        (hash-table-ref-prim ht key)
                        (third args)))) ; return default value
                (else (raise (error "hash-table-ref: wrong number of arguments")))))))

    (define (hash-table-ref! ht key value)
        (if (not (hash-table-exists? ht key))
            (hash-table-set! ht key value))
        (hash-table-ref ht key))

    (define (hash-table-map ht func)
        (map 
            (lambda (key) 
                (func key (hash-table-ref ht key)))
            (hash-table-keys ht)))

    (define (hash-table-walk ht func)
        (for-each 
            (lambda (key) 
                (func key (hash-table-ref ht key)))
            (hash-table-keys ht)))
        
    (define hash-table-for-each hash-table-walk)

    (define (alist->hash-table alist)
        (define ht (make-hash-table))
        (for-each 
            (lambda (pair) 
                (hash-table-set! ht (car pair) (car (cdr pair))))
            alist)
        ht)

    (define (hash-table->alist ht)
        (map
            (lambda (key) 
                (list key (hash-table-ref ht key)))
            (hash-table-keys ht)))

    ; Aliases
    (define hash-ref hash-table-ref)
    (define hash-ref! hash-table-ref!)
    (define hash-set! hash-table-set!)
    (define hash-size hash-table-size)
    (define hash-exists? hash-table-exists?)
    (define hash-map hash-table-map)
    (define hash-walk hash-table-walk)
    (define hash-for-each hash-table-walk)
    (define hash-delete! hash-table-delete!)
    (define hash-keys hash-table-keys)
    (define hash-values hash-table-values)
    

    ; String
    ;

    (define (string-reverse str)
        (define (reverse-help str res)
            (if (empty? str) res
                (reverse-help (cdr str) (string-append (car str) res))))
        (reverse-help str ""))

    (define string-join (lambda args ; accepts a list of strings and an optional delimiter
        (let 
            ((str-list (first args))
             (delimiter (if (= (length args) 2) (car (cdr args)) "")))
            (if (not (list? str-list)) 
                (raise (error "string-join: first argument is not a list"))
                (if (empty? str-list) 
                    ""
                    (fold-left 
                        (lambda (acc x) (string-append acc delimiter x))
                        (car str-list) 
                        (cdr str-list)))))))

    (define (string-suffix? suffix string)
        (string-prefix? (string-reverse suffix) (string-reverse string)))

    (define (string-suffix-ci? suffix string)
        (string-prefix-ci? (string-reverse suffix) (string-reverse string)))

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

    (define (string-index str substr)
        (define (string-index-help str substr index)
            (if (empty? str) #f
                (if (string-prefix? substr str) index
                    (string-index-help (cdr str) substr (+ index 1)))))
        (string-index-help str substr 0))

    (define (substring str start end)
        (if (or (< start 0) (< end 0) (> start (length str)) (> end (length str)))
            (raise (error "substring: out of bounds")))
        (if (= start end)
            ""
            (begin
                (define (substring-help-to-end str pos end res)
                    (if (or (empty? str) (= pos end)) 
                        res
                        (substring-help-to-end (cdr str) (+ pos 1) end (string-append res (car str)))))
                (define (substring-help-from-start str start pos)
                    (if (= start pos)
                        str
                        (substring-help-from-start (cdr str) start (+ pos 1))))
                (substring-help-to-end 
                    (substring-help-from-start str start 0) 
                    0 end ""))))

    (define (string-contains? str substr)
        (if (string-index str substr) #t #f))
    
    (define (string-contains-ci? str substr)
        (if (string-index (string-downcase str) (string-downcase substr)) #t #f))

    (define (string-contains-every? str substr)
        (define result '())
        (define (string-index-help str substr index)
            (if (empty? str)
                result
                (begin
                    (if (string-prefix? substr str) 
                        (set! result (append result (list index))))
                    (string-index-help (cdr str) substr (+ index 1)))))
        (string-index-help str substr 0))

    (define (string-contains-every-ci? str substr)
        (string-contains-every? (string-downcase str) (string-downcase substr)))

    ; Ports
    ;

    (define (call-with-output-file file-name proc)
        (let 
            ((out-port (open-output-file file-name)))
            (with-exception-handler
                (lambda (e)
                    (close-port out-port)
                    (raise e))
                (lambda ()
                    (let 
                        ((result (proc out-port)))
                        (close-port out-port)
                        result)))))

    (define (call-with-input-file file-name proc)
        (let 
            ((in-port (open-input-file file-name)))
            (with-exception-handler
                (lambda (e)
                    (close-port in-port)
                    (raise e))
                (lambda ()
                    (let 
                        ((result (proc in-port)))
                        (close-port in-port)
                        result)))))

    (define (write-string str port)
        (define (write-string-help str port)
            (if (empty? str) 
                #t
                (begin
                    (write-char (car str) port)
                    (write-string-help (cdr str) port))))
        (if (not (port? port)) 
            (raise (error "write-string: not a port"))
            (write-string-help str port)))

    (define (read-string k port)
        (define (read-string-help num port result)
            (if (= num 0) 
                result
                (begin
                    (let
                        ((next-char (read-char port)))
                        (if (eof-object? next-char)
                            result
                            (read-string-help (- num 1) port (string-append result next-char)))))))
        (if (not (port? port)) 
            (raise (error "read-string: not a port"))
            (read-string-help k port "")))

)