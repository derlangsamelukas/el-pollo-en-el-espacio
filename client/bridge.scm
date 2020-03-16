
(define (then p fn)
  ((jmethod "then" p)
   (callback fn)))

(define (catch p fn)
  ((jmethod "catch" p)
   (callback fn)))

(define loggit (native console.log))

(define (append-child node child)
  ((jmethod "appendChild" node)
   child))

(define (query-selector node selector)
  ((jmethod "querySelector" node)
   (jstring selector)))

(define (create-node name)
  ((native-method document.createElement) (%host-ref document) (jstring name)))

(define (create-text-node string)
  ((jmethod "createTextNode" window.document)
   (jstring string)))

(define (jremove! node)
  ((jmethod "remove" node)))

(define jreplace (native-method document.replaceChild))

(define (jset!-attr node key value)
  ((jmethd "setAttribute" node)
   (jstring key)
   value))

(define (jremove-attr! node key)
  ((jmethod "removeAttribute" nde)
   (jstring key)))

(define (jref-attr node key)
  ((jmethod "getAttribute" node)
   node
   (jstring key)))

(define (expr->string expr)
  (with-output-to-string (lambda () (write expr))))

(define (string->expr text)
  (with-input-from-string text read))

(define (fetchit url data cc)
  (let ((p ((native (jref "fetch" (jwindow)))
            url
            (if (or (void? data) (void? cc))
                (%)
                (% "method" "POST" "body" (jstring data))))))
    (then p (if (void? cc) data cc))))

(define (send-list url lst cc)
  (fetchit url (with-output-to-string (lambda () (write lst)))
           (lambda (x)
             (then ((native-method (%property-ref text x)) x)
                   (lambda (text)
                     (with-input-from-string text (o cc read)))))))

(define (fetch-list url cc)
  (fetchit
   url
   (lambda (response)
     (if (= 200 (jref "status" response))
         ((jmethod
           "then"
           ((jmethod "text" response)))
          (lambda (text)
            (with-input-from-string text (o cc read))))
         (cc #f)))))

(define (on* node name native-fn)
  ((jmethod "addEventListener" node)
   (jstring name)
   native-fn))

(define (on node name fn)
  (on* node name (callback fn)))

(define (off node name native-fn)
  ((jmethod "removeEventListener" node)
   (jstring name)
   native-fn))

(define (jparent node)
  (jref "parentNode" node))

(define (nth-cdr x list)
  (if (or (zero? x) (equal? '() list))
      list
      (nth-cdr
       (- x 1)
       (cdr list))))

(define (range start end)
  (define (f x)
    (if (= x end)
        '()
        (cons x (f (+ x 1)))))
  (f start))

(define (fold fn z lst)
  (if (equal? '() lst)
      z
      (fold
       fn
       (fn z (car lst))
       (cdr lst))))

(define (remove-if fn list)
  (reverse
   (fold
    (lambda (list item)
      (if (fn item)
          list
          (cons item list)))
    '()
    list)))

(define (remove-if-not fn list)
  (remove-if (compl fn) list))

(define (replace-assoc key lst value)
  (cons
   (list key value)
   (remove-if
    (lambda (x) (equal? key (car x)))
    lst)))

(define (timeout fn delay)
  ((native (href "setTimeout" (jwindow))) (callback fn) delay))

(define (interval fn delay)
  ((native (jref "setInterval" (jwindow))) (callback fn) delay))

(define (jref key object)
  ((native (%property-ref get (%host-ref Reflect))) object (jstring key)))

;; (define jset!
;;   (lambda (key object value)
;;     ((native (%property-ref set (%host-ref Reflect))) object (jstring key) value)))

(define (jset! key object value)
  ((native
    (path '(Reflect set) (jwindow)))
   object
   (jstring key)
   value))

(define (jmethod method object)
  (lambda args
    (apply
     (native-method (jref (jstring method) object))
     (cons
      object
      args))))

(define (jwindow)
  (%host-ref window))

(define (jdocument)
  (jref "document" (jwindow)))

(define (path path* object)
  (if (null? path*)
      object
      (path (cdr path*)
            (jref (symbol->string (car path*))
                  object))))

(define (jobject->alist object)
  (map
   (lambda (key)
     (cons key (jref key object)))
   (vector->list
    ((jmethod "keys" (jref "Object" (jwindow)))
     object))))
