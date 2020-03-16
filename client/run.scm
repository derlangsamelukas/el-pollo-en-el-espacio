
(define (users)
  (append
   (map (const "yay") (range 0 12))
   '("foo" "bar" "baz")))

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
  (define (field grow string)
    `(div (@ (class "field item") (style ,(string-append "flex-grow: " (number->string grow) ";"))) ,string))
  (define (row string)
    `(div (@ (class "row"))
          ,(field 3 string)
          ,(field 1 "foo")))
  `(div
    (div
     (@ (class "list"))
     (div
      (@ (class "inner"))
      (h1 "user list")
      (input (@ (placeholder "search")) (on (input search)))
      (div
       (@ (class "scroll"))
       ,@(map row (remove-if-not (lambda (s) ((jmethod "includes" (new window.String (jstring s))) (car-or (assoc-list 'search model) "")))
                                 (users))))
      (button
       (on (click load-users))
       "list users")
      (button
       (on (click add-user))
       "add user")))))

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
      ('search
       (replace-assoc 'search model (jref "value" (jref "target" (cdr data)))))
      ('username (replace-assoc 'username model (jref "value" (jref "target" (cdr data)))))
      ('password (replace-assoc 'password model (jref "value" (jref "target" (cdr data)))))
      ('login
       (if (and (string=? (car-or (assoc-list 'username model) "") "lukas")
                (string=? (car-or (assoc-list 'password model) "") "test"))
           (replace-assoc 'screen model 'overview)
           (begin
             (timeout (lambda () (dispatch 'clear)) 2000)
             (cons '(error . "wrong password") model))))
      ('clear
       (remove-if (lambda (pair) (eq? (car pair) 'error)) model))
      ('add-user
       (fetchit "/api/user/add" ((jmethod "stringify" (jref "JSON" (jwindow))) (% "id" 1 "name" "lukas" "age" 22)) (lambda (r) (then ((jmethod "text" r)) print)))
       model)
      ('load-users
       (fetchit "/api/user/list" (lambda (r) (then ((jmethod "json" r)) (lambda (response) (print (map jobject->alist (vector->list response)))))))
       model)
      (else model))))

(define (run run)
  (let ((app (query-selector (jdocument) "#app")))
    (vdom-create app '((screen overview)) render handler)))

(set! .onload (callback run))
