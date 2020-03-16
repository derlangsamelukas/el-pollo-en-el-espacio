(include-relative "api")

(import spiffy)
(import openssl)
(import uri-common)
(import intarweb)
(import sxml-serializer)
(import matchable)
(import api)
(import (chicken string))

(define input-files (make-parameter '(client/bridge.scm client/match.scm client/run.scm client/vdom.scm client/logic.scm)))
(define output-file (make-parameter "public/index.js"))

(define users (make-resource '() 'id))
(define sessions (make-parameter '()))

(define user-handler (make-resource-handler "/api/user" users))

(define (with-request-body has-body else)
  (define (read-all request prev)
    (string-append
     (if (char-ready? (request-port request))
         (read-all
          request
          (string-append
           prev
           (make-string 1 (read-char (request-port request)))))
         prev)))
  ;; (read-urlencoded-request-data request)
  (let ((request (current-request)))
    (if (and (request-has-message-body? request)
             (char-ready? (request-port request)))
        (let ((body (read-all request "")))
          (has-body body))
        (else))))

(define (uri-matches predicate)
  (predicate (uri-path (request-uri (current-request)))))

(define (with-uri-match predicate on-match)
  (lambda (cc)
    (if (uri-matches predicate)
        (on-match cc)
        (cc))))

(define (index env)
  (when (eq? env 'dev)
    (load "compile.scm"))
  (string-append
   "<!DOCTYPE html>"
   (serialize-sxml
    `(html
      (head
       (meta (@ (charset "utf-8")))
       (meta (@ (name "viewport") (content "user-scalable=no, initial-scale=1, maximum-scale=1, minimum-scale=1, width=device-width")))
       (link (@ (href "index.css") (type "text/css") (rel "stylesheet"))))
      (body
       (div (@ (id "app")) "")
       (script (@ (src ,(string-append "spock-runtime-" (if (eq? env 'dev) "debug-" "") "min.js"))) (type "text/javascript") "")
       (script (@ (src "index.js")) (type "text/javascript") ""))))))

(define api
  (with-uri-match
   (match-lambda ((/ "api" _ . _) #t) (_ #f))
   (lambda (cc)
     (with-request-body
      (lambda (body)
        (send-response
         status: 'ok
         body: (string-append "body: '" body "'")))
      (lambda ()
        (send-response
         status: 'ok
         body: "no request body"))))))

(define default-handler
  (with-uri-match
   (cut equal? '(/ "") <>)
   (lambda (cc)
     (send-response
      status: 'ok
      body: (index 'dev)))))

(define compose-handlers
  (lambda handlers
    (lambda (cc)
      (if (null? handlers)
          (cc)
          ((car handlers)
           (lambda ()
             ((apply compose-handlers (cdr handlers)) cc)))))))

(define oh compose-handlers)

(parameterize
    ((server-port 4300)
     (root-path "./public")
     (vhost-map `((".*" . ,(oh default-handler user-handler)))))
  (let ((listener (ssl-listen* port: (server-port) certificate: "certs/cert.pem" private-key: "certs/key.pem")))
    (accept-loop listener ssl-accept)))
