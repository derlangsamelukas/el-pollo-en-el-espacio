(import (chicken port))
(import spock)

(with-output-to-file (output-file)
  (lambda ()
    (apply spock (map symbol->string (input-files)))))
