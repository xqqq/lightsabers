;; a meta-circular interpreter (reflection tower) is an
;; interpreter which can interpret itself to interpret
;; itself to interpret itself ...

;; This version saves indentation by defining 'cond'.

;; author: Yin Wang (yw21@cs.indiana.edu)



(define Y
  '(lambda (f)
     ((lambda (u) (u u))
      (lambda (x) (f (lambda (t) ((x x) t)))))))


(define interp-text
  `(,Y
    (lambda (interp)
      (lambda (exp)
        (lambda (env)
          (lambda (k)
            (cond
             [(number? exp) (k exp)]
             [(boolean? exp) (k exp)]
             [(string? exp) (k exp)]
             [(symbol? exp) (k (env exp))]
             [(eq? 'cond (car exp))
              ((((,Y (lambda (loop)
                       (lambda (cls)
                         (lambda (env)
                           (lambda (k)
                             (((interp (car (car cls))) env)
                              (lambda (t)
                                (if t
                                    (((interp (car (cdr (car cls)))) env) k)
                                    (((loop (cdr cls)) env) k)))))))))
                 (cdr exp)) env) k)]
             [(eq? 'eq? (car exp))
              (((interp (car (cdr exp))) env)
               (lambda (v1)
                 (((interp (car (cdr (cdr exp)))) env)
                  (lambda (v2) (k (eq? v1 v2))))))]
             [(eq? '= (car exp))
              (((interp (car (cdr exp))) env)
               (lambda (v1)
                 (((interp (car (cdr (cdr exp)))) env)
                  (lambda (v2) (k (= v1 v2))))))]
             [(eq? '* (car exp))
              (((interp (car (cdr exp))) env)
               (lambda (v1)
                 (((interp (car (cdr (cdr exp)))) env)
                  (lambda (v2) (k (* v1 v2))))))]
             [(eq? 'cons (car exp))
              (((interp (car (cdr exp))) env)
               (lambda (v1)
                 (((interp (car (cdr (cdr exp)))) env)
                  (lambda (v2) (k (cons v1 v2))))))]
             [(eq? 'quote (car exp)) (k (car (cdr exp)))]
             [(eq? 'sub1 (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (sub1 v))))]
             [(eq? 'number? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (number? v))))]
             [(eq? 'boolean? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (boolean? v))))]
             [(eq? 'string? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (string? v))))]
             [(eq? 'symbol? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (symbol? v))))]
             [(eq? 'zero? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (zero? v))))]
             [(eq? 'null? (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (null? v))))]
             [(eq? 'car (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (car v))))]
             [(eq? 'cdr (car exp))
              (((interp (car (cdr exp))) env) (lambda (v) (k (cdr v))))]
             [(eq? 'if (car exp))
              (((interp (car (cdr exp))) env)
               (lambda (t)
                 (if t
                     (((interp (car (cdr (cdr exp)))) env) k)
                     (((interp (car (cdr (cdr (cdr exp))))) env) k))))]
             [(eq? 'lambda (car exp))
              (k (lambda (a)
                   (lambda (k)
                     (((interp (car (cdr (cdr exp))))
                       (lambda (x^)
                         (if (eq? x^ (car (car (cdr exp)))) a (env x^))))
                      k))))]
             [(eq? 'rho (car exp))
              (k (lambda (a)
                   (lambda (k)
                     (((interp (car (cdr (cdr exp))))
                       (lambda (x^)
                         (cond
                          [(eq? x^ (car (cdr (cdr (car (cdr exp))))))
                           (lambda (a) (lambda (k^) (k a)))]
                          [(eq? x^ (car (cdr (car (cdr exp))))) env]
                          [(eq? x^ (car (car (cdr exp)))) a]
                          [#t (env x^)])))
                      k))))]
             [#t
              (((interp (car exp)) env)
               (lambda (v1)
                 (((interp (car (cdr exp))) env)
                  (lambda (v2)
                    ((v1 v2) k)))))])))))))



;;;;;;;;; nested evaluators ;;;;;;;;;;

; level 0 is eval, our base evaluator
(define interp0 eval)

; level 1 uses eval to interpret an interpreter text together with the
; input program
(define interp1
  (lambda (e)
    (eval `(((,interp-text (quote ,e)) (lambda (x) x)) (lambda (v) v)))))

; level 2 uses interp1 to interpret an interpreter text together with the
; input program
(define interp2
  (lambda (e)
    (interp1 `(((,interp-text (quote ,e)) (lambda (x) x)) (lambda (v) v)))))

; and so on ...
(define interp3
  (lambda (e)
    (interp2 `(((,interp-text (quote ,e)) (lambda (x) x)) (lambda (v) v)))))


; We can extract the above pattern into a general nesting facility, which
; takes a text of interpreter and a number n, and generates an interpreter
; nested to level n.
(define nest-interp
  (lambda (interp n)
    (cond
     [(zero? n) eval]
     [else
      (lambda (e)
        ((nest-interp interp (sub1 n))
         `(((,interp (quote ,e)) (lambda (x) x)) (lambda (v) v))))])))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tests ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-syntax test
  (syntax-rules ()
    ((_ title tested-expression expected-result)
     (let* ((expected expected-result)
            (produced tested-expression))
       (if (equal? expected produced)
           (printf "~s works!\n" title)
           (error
            'test
            "Failed ~s: ~a\nExpected: ~a\nComputed: ~a"
            title 'tested-expression expected produced))))))


;;;;;;;;;; fact 5 ;;;;;;;;;;;
(define fact5
  `((,Y
     (lambda (fac)
       (lambda (n)
         (if (zero? n) 1 (* n (fac (sub1 n)))))))
    5))

(test "fact5 - Level 0"
 ((nest-interp interp-text 0) fact5)
 120)

(test "fact5 - Level 1"
 ((nest-interp interp-text 1) fact5)
 120)

(test "fact5 - Level 2"
 ((nest-interp interp-text 2) fact5)
 120)

(test "fact5 - Level 3"
 ((nest-interp interp-text 3) fact5)
 120)

(time ((nest-interp interp-text 1) fact5))
;; cpu time: 15 real time: 9 gc time: 0

(time ((nest-interp interp-text 2) fact5))
;; cpu time: 15 real time: 12 gc time: 0

(time ((nest-interp interp-text 3) fact5))
;; cpu time: 156 real time: 157 gc time: 16

(time ((nest-interp interp-text 4) fact5))
;; cpu time: 11107 real time: 11706 gc time: 1401



;;;;;;;;; member-test ;;;;;;;;;;
(define member-test
  `(((,Y
      (lambda (member?)
        (lambda (a)
          (lambda (lat)
            (if
             (null? lat) #f
             (if (eq? a (car lat)) #t
                 ((member? a) (cdr lat))))))))
     'a) '(b a c)))

(test "member-test - Level 0"
 ((nest-interp interp-text 0) member-test)
 #t)

(test "member-test - Level 1"
 ((nest-interp interp-text 1) member-test)
 #t)

(test "member-test - Level 2"
 ((nest-interp interp-text 2) member-test)
 #t)

(test "member-test - Level 3"
 ((nest-interp interp-text 3) member-test)
 #t)


;;;;;;;;;;;; rho-test ;;;;;;;;;;;;;;
(define rho-test '(* 2 ((rho (x e k) (* 3 (k 4))) 5)))

(test "rho-test - Level 1"
 ((nest-interp interp-text 1) rho-test)
 8)

(test "rho-test - Level 2"
 ((nest-interp interp-text 2) rho-test)
 8)

(test "rho-test - Level 3"
 ((nest-interp interp-text 3) rho-test)
 8)


;;;;;;;;;;;; prod-test-rho ;;;;;;;;;;;;;
(define prod-test-rho
  `((,Y
     (rho (prod _ __)
       (rho (ls _ k)
         (cond
          [(null? ls) 1]
          [(zero? (car ls)) (k 0)]
          [else (* (car ls) (prod (cdr ls)))]))))
    '(1 2 3 0 5 6)))


(test "prod-test-rho - Level 1"
 ((nest-interp interp-text 1) prod-test-rho)
 0)

(test "prod-test-rho - Level 2"
 ((nest-interp interp-text 2) prod-test-rho)
 0)

(test "prod-test-rho - Level 3"
 ((nest-interp interp-text 3) prod-test-rho)
 0)
