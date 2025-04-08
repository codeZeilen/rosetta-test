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
                (for-each f (cdr lst)))))

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
    (define (assq object alist)
        (if (null? alist) 
            #f
            (if (equal? (car (car alist)) object) 
                (car alist)
                (assq object (cdr alist)))))
    
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
            (fold-left 
                (lambda (acc x) (string-append acc delimiter x))
                (car str-list) 
                (cdr str-list)))))

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

    (define (string-contains? str substr)
        (if (string-index str substr) #t #f))
    
    (define (string-contains-ci? str substr)
        (if (string-index-ci (string-downcase str) (string-downcase substr)) #t #f))
)