(define render
  (lambda (model)
    `(div
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
           (input (placeholder "Username"))
           (input (placeholder "Password") (type "password"))
           (button
            (type "button")
            (text "Login")
            (on (click login)))
           .
           ,(if (assoc 'error model)
                `((div (class "error-message") (text ,(cdr (assoc 'error model)))))
                '())))))))))

(define handler
  (lambda (model event data dispatch)
    (case event
      ('login
       (timeout (lambda () (dispatch 'clear)) 2000)
       (cons '(error . "wrong password") model))
      ('clear '())
      (else model))))

(define run
  (lambda ()
    (let ((app (query-selector (%host-ref document) "#app")))
      (vdom-create app '() render handler))))

(set! .onload (callback run))
