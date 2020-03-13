
(define (login-screen model)
  `(div
    (div
     (@ (class "login"))
     (div
      (@ (class "headline"))
      "Hej")
     (div
      (@ (class "form"))
      (div
       (@ (class "inner"))
       (input (@ (placeholder "Username")) (on (input username)))
       (input (@ (placeholder "Password") (type "password")) (on (input password)))
       (button
        (@ (type "button"))
        (on (click login))
        ,(if (assoc 'error model) '(strong (children "aaa")) "Login"))
       .
       ,(if (assoc 'error model)
            `((div (@ (class "error-message")) ,(cdr (assoc 'error model))))
            '()))))))

(define (list-users model)
  `(div
    (div
     (@ (class "list"))
     (div
      (div "foo")
      (div "bar")
      (div "baz")))))

(define screens
  `((login ,login-screen)
    (overview ,list-users)))

(define render
  (lambda (model)
    (apply
     (cadr
      (assoc
       (cadr (assoc 'screen model))
       screens))
     (list model))))

;; (define (render model)
;;   '(div
;;     (children
;;      (div (text "aaa")))))

(define (car-or lst default)
  (if (null? lst)
      default
      (car lst)))

(define handler
  (lambda (model event data dispatch)
    (case event
      ('username (replace-assoc 'username model (jref "value" (jref "target" (cdr data)))))
      ('password (replace-assoc 'password model (jref "value" (jref "target" (cdr data)))))
      ('login
       (if (and (string=? (car-or (assoc-list 'username model) "") "lukas")
                (string=? (car-or (assoc-list 'password model) "") "test"))
           (replace-assoc 'screen model 'overview)
           (begin
             (timeout (lambda () (dispatch 'clear)) 2000)
             (cons '(error . "wrong password") model))))
      ('clear (remove-if (lambda (pair) (eq? (car pair) 'error)) model))
      (else model))))

(define run
  (lambda ()
    (let ((app (query-selector (%host-ref document) "#app")))
      (vdom-create app '((screen login)) render handler))))

(set! .onload (callback run))
