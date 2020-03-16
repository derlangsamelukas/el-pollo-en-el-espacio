(module api (make-resource-handler make-resource)
  (import scheme)
  (import (chicken base))
  (import (chicken string))
  (import spiffy)
  (import uri-common)
  (import intarweb)
  (import matchable)
  (import medea)

  (define (read-all request prev)
    (string-append
     (if (char-ready? (request-port request))
         (read-all
          request
          (string-append
           prev
           (make-string 1 (read-char (request-port request)))))
         prev)))

  (define (list-handler resource)
    (send-response status: 'ok body: (json->string (list->vector (resource-elements resource)))))

  (define (add-handler resource)
    (if (char-ready? (request-port (current-request)))
        (let ((element (read-json (read-all (current-request) ""))))
          (resource-add! resource element)
          (send-response status: 'ok body: "added succesfully"))
        (send-response status: 'ok body: "no request body given")))

  (define-record resource elements key)
  
  (define (remove-handler resource)
    (send-response status: 'ok body: "@todo"))
  
  (define (get-handler resource)
    (send-response status: 'ok body: "@todo"))

  (define (resource-add! resource element)
    (resource-elements-set!
     resource
     (cons
      element
      (resource-elements resource))))

  (define (resource-get resource key)
    (define (loop elements)
      (unless (null? elements)
        (if (equal? (cdr (assoc (resource-key resource) (car elements)))
                    key)
            (car elements)
            (loop (cdr elements)))))
    (loop (resource-elements resource)))

  (define (resource-delete! resource key)
    (resource-elements-set!
     resource
     (reverse
      (foldl
       (lambda (elements element)
         (if (equal? (cdr (assoc (resource-key resource) element))
                     key)
             elements
             (cons element elements)))
       '()
       (resource-elements resource)))))
  
  (define (make-resource-handler prefix-path resource)
    (let ((path (cons '/ (string-split prefix-path "/"))))
      (lambda (cc)
        (let ((uri (uri-path (request-uri (current-request)))))
          (define (f expected actual return)
            (cond
             ((null? expected)
              (return actual))
             ((and (pair? actual)
                   (equal? (car expected) (car actual)))
              (f (cdr expected) (cdr actual) return))
             (else
              (cc))))
          (f
           path
           uri
           (match-lambda
             (("list") (list-handler resource))
             (("add") (add-handler resource))
             (("remove") (remove-handler resource))
             (("get") (get-handler resource))
             (else (cc)))))))))
