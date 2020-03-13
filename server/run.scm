(import spiffy)
(import openssl)
(import uri-common)
(import intarweb)
(import sxml-serializer)

(define input-files (make-parameter '(client/bridge.scm client/match.scm client/run.scm client/vdom.scm)))
(define output-file (make-parameter "public/index.js"))

(define index
  (lambda (env)
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
         (script (@ (src "index.js")) (type "text/javascript") "")))))))

(define default-handler
  (lambda (cc)
    (if (equal? '(/ "") (uri-path (request-uri (current-request))))
        (send-response
         status: 'ok
         body: (index 'dev))
        (cc))))

(parameterize
    ((server-port 4300)
     (root-path "./public")
     (vhost-map `((".*" . ,default-handler))))
  (let ((listener (ssl-listen* port: (server-port) certificate: "certs/cert.pem" private-key: "certs/key.pem")))
    (accept-loop listener ssl-accept)))
