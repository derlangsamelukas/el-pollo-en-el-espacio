
(define diff
  (lambda (new old cc)
    (let ((remove old)
          ;; (change '())
          (add '()))
      (letrec ((loop
                (lambda (new)
                  (match new
                    (()
                     ;; (set! remove old)
                     #f)
                    (((k . v) . new)
                     (let ((kv* (assq k old)))
                       (if kv*
                           (if (equal? v (cdr kv*))
                               (set! remove (remove-if (lambda (pair) (equal? k (car pair))) remove))
                               (set! add (cons (cons k v) add)))
                           (set! add (cons (cons k v) add)))
                       (loop new)))))))
        (loop new)
        (cc remove add)))))

(define map-on-handlers
  (lambda (node on-new on-old dispatch)
    (let ((ons (jref "on" node)))
      (diff
       on-new
       on-old
       (lambda (remove add)
         (map
          (lambda (pair)
            (let* ((event (symbol->string (car pair)))
                   (handler (jref event ons)))
              (off node event handler)))
          remove)
         (map
          (lambda (pair)
            (let ((event (symbol->string (car pair)))
                  (handler
                   (callback
                    (lambda (event)
                      (dispatch (cadr pair) (cons (car (if (null? (cddr pair)) '(#f) (cddr pair))) event))))))
              (on* node event handler)
              (jset! event ons handler)))
          add))))))

(define create-node-from-attrs
  (lambda (attrs dispatch)
    (if (string? attrs)
        (create-text-node attrs)
        (let ((node (create-node (symbol->string (car attrs)))))
          (jset! "on" node (%))
          (apply-changes node '() (cdr attrs) dispatch)
          node))))

(define assoc-list
  (lambda (key lst)
    (cdr (or (assoc key lst) '(#f)))))

(define (sync-handlers node old new dispatch)
  (map-on-handlers node (assoc-list 'on new) (assoc-list 'on old) dispatch))

(define (sync-attributes node old new)
  (define (remove-specials lst)
    (remove-if
     (lambda (attr)
       (assoc (car attr) '((children) (on) (text))))
     lst))
  (let ((new (assoc-list '@ new))
        (old (assoc-list '@ old)))
    (map
     (lambda (pair)
       (unless (equal? (assoc-list (car pair) old) (cadr pair))
         ((js-method "setAttribute" node) (jstring (symbol->string (car pair))) (jstring (cadr pair)))))
     new)
    (map
     (lambda (pair)
       (unless (assoc (car pair) new)
         ((js-method "removeAttribute" node) (symbol->string (car pair)))))
     old)))

(define (sync-children node old new dispatch)
  (let ((children-new (remove-if (lambda (x) (and (list? x) (memq (car x) '(@ on)))) new))
        (children-old(remove-if (lambda (x) (and (list? x) (memq (car x) '(@ on)))) old)))
    (define (update-kept)
      (map
       (lambda (i)
         (map-tree
          (vector-ref (jref "childNodes" node) i)
          node
          (vector-ref (list->vector children-old) i)
          (vector-ref (list->vector children-new) i)
          dispatch))
       (range
        0
        (min (length children-new)
             (length children-old)))))
    (define (remove-old)
      (map
       (lambda (i)
         ((js-method
           "remove"
           (vector-ref
            (jref "childNodes" node)
            (+ i (length children-new))))))
       (range
        0
        (- (length children-old)
           (length children-new)))))
    (define (add-new)
      (map
       (lambda (i)
         ((js-method
            "appendChild"
            node)
          (create-node-from-attrs
           (vector-ref
            (list->vector children-new)
            (+ i (length children-old)))
           dispatch)))
       (range
        0
        (- (length children-new)
           (length children-old)))))
    (update-kept)
    (cond
     ((> (length children-old)
         (length children-new))
      (remove-old))
     ((< (length children-old)
         (length children-new))
      (add-new)))))

(define (apply-changes node old new dispatch)
  (sync-attributes node old new)
  (sync-children node old new dispatch)
  (sync-handlers node old new dispatch))

(define (replace-node node parent new dispatch)
  (replace
   parent
   (create-node-from-attrs new dispatch)
   node))

(define map-tree
  (lambda (node parent old new dispatch)
    (cond
     ((equal? old new) #f)
     ((or (string? old) (string? new))
      (replace-node node parent new dispatch))
     ((equal? (car old) (car new))
      (apply-changes node (cdr old) (cdr new) dispatch))
     (#t (replace-node node parent new dispatch)))))

(define vdom-create
  (lambda (node model render handle-event)
    (letrec ((vdom '(div))
             (update-vdom
              (lambda (new-model)
                (let ((new-vdom (render new-model)))
                  (map-tree node (parent node) vdom new-vdom dispatch)
                  (set! vdom new-vdom))))
             (dispatch
              (lambda (event data)
                (letrec ((new-model (handle-event model event data dispatch)))
                  (unless (equal? model new-model)
                    (set! model new-model)
                    (update-vdom new-model))))))
      ;; (jset! "on" node (%))
      (update-vdom model)
      dispatch)))

(define with-vdom-app
  (lambda (selector model render handle-event init-fn)
    (set! .onload
      (callback (lambda ()
                  (init-fn
                   (vdom-create (query-selector window.document selector)
                                model
                                render
                                handle-event)))))))
