;; Boolean expression simplification into sum-of-products
;; author: Yin Wang (yinwang0@gmail.com)


;---------------------------------------------
;; (1) Push 'and' into 'or'
;; (2) Push 'not' into 'and' and 'or'
;; Do (1) and (2) recursively until no more simplification can be made
(define simpl
  (lambda (exp)
    (match exp
      [`(and (or ,a ,b) ,c)
       `(or ,(simpl `(and ,(simpl a) ,(simpl c)))
            ,(simpl `(and ,(simpl b) ,(simpl c))))]
      [`(and ,c (or ,a ,b))
       `(or ,(simpl `(and ,(simpl c) ,(simpl a)))
            ,(simpl `(and ,(simpl c) ,(simpl b))))]
      [`(not (and ,a ,b))
       `(or ,(simpl `(not ,a)) ,(simpl `(not ,b)))]
      [`(not (or ,a ,b))
       `(and ,(simpl `(not ,a)) ,(simpl `(not ,b)))]

      [`(and ,a ,b)
       `(and ,(simpl a) ,(simpl b))]
      [`(or ,a ,b)
       `(or ,(simpl a) ,(simpl b))]
      [`(not ,a ,b)
       `(not ,(simpl a) ,(simpl b))]
      [other other])))



;---------------------------------------------
;; Combine nested expressions with same operator, for example
;; (and (and a b) c) ==> (and a b c)
;; (or a (or b c)) ==> (or a b c)
;; (not (not a)) ==> a
(define combine
  (lambda (exp)
    (define combine1
      (lambda (ct)
        (lambda (exp)
          (match exp
            [`(and ,a ,a)
             (list a)]
            [`(or ,a ,a)
             (list a)]
            [`(and ,x* ...)
             (let ([y* (apply append (map (combine1 'and) x*))])
               (if (eq? 'and ct) y* `((and ,@y*))))]
            [`(or ,x* ...)
             (let ([y* (apply append (map (combine1 'or) x*))])
               (if (eq? 'or ct) y* `((or ,@y*))))]
            [`(not (not ,a))
             ((combine1 ct) a)]
            [other (list other)]))))
    (car ((combine1 'id) exp))))


;; Examples for combine:
;; (combine '(and (and a (and b (and c (and d e))))))
;; (combine '(and (and (and (and a b) c) d) e))
;; (combine '(and (and a (and b c)) (and d e)))
;; (combine '(or (and a (and b c) d)))
;; (combine '(not (not a)))
;; (combine '(not (not (not (not a)))))


;---------------------------------------------
;; main function (simpl then combine)
(define simplify
  (lambda (exp)
    (combine (simpl exp))))



;------------------ examples ------------------
(simplify '(and (or football basketball) baby))

;; ==>
;; '(or (and football baby) (and basketball baby))


;---------------------------------------------
(simplify '(and (not (and a (or b c))) (or d e)))

;; ==>
;; '(or (and (not a) d)
;;      (and (not b) (not c) d)
;;      (and (not a) e)
;;      (and (not b) (not c) e))


;---------------------------------------------
(simplify '(not (and (not a) (not (and b c)))))

;; ==> '(or a (and b c))


;---------------------------------------------
(simplify '(and (or a b) (or a c)))

;; ==> '(or (and a c) (and a d) (and b c) (and b d))

