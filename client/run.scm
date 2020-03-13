
(define (login-screen model)
  `(div
    (children
     (div
      (class "login")
      (children
       (div
        (class "headline")
        (text "Hej"))
       (div
        (class "form")
        (children
         (div
          (class "inner")
          (children
           (input (placeholder "Username") (on (input username)))
           (input (placeholder "Password") (on (input password)) (type "password"))
           (button
            (type "button")
            (text "Login")
            (on (click login)))
           .
           ,(if (assoc 'error model)
                `((div (class "error-message") (text ,(cdr (assoc 'error model)))))
                '()))))))))))

(define (list-users model)
  `(div
    (children
     (section
      (class "list")
      (children
       (div
        (children
         (div (text "foo"))
         (div (text "bar"))
         (div (text "baz")))))))))

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

(define handler
  (lambda (model event data dispatch)
    (case event
      ('username (replace-assoc 'username model (jref "value" (jref "target" (cdr data)))))
      ('password (replace-assoc 'password model (jref "value" (jref "target" (cdr data)))))
      ('login
       (if (and (string=? (car (or (assoc-list 'username model) '(""))) "lukas")
                (string=? (car (or (assoc-list 'password model) '(""))) "test"))
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
