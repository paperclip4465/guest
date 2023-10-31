(define-module (guest scripts list)
  #:use-module (guest scripts)
  #:use-module (guest i18n)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:export (guest-list))

(define* (find-zephyr-modules directories)
  "Return the list of directories containing zephyr/module.yml found
under DIRECTORY, recursively. Return the empty list if DIRECTORY is
not accessible."
  (define (module-directory file)
    (dirname (dirname file)))

  (define (enter? name stat result)
    ;; Skip version control directories.
    (not (member (basename name) '(".git" ".svn" "CVS"))))

  (define (leaf name stat result)
    ;; Add module root directory to results
    (if (and (string= "module.yml" (basename name))
	     (string= "zephyr" (basename (dirname name))))
	(cons (module-directory name) result)
	result))

  (define (down name stat result) result)
  (define (up name stat result) result)
  (define (skip name stat result) result)

  (define (find-modules directory)
    (file-system-fold enter? leaf down up skip error
		      '() (canonicalize-path directory)
		      stat))

  (append-map find-modules directories))

(define (zephyr-modules-cmake-argument modules)
  (format #f "-DZEPHYR_MODULES='~{~a~^;~}'" modules))

(define* (configure-args #:key (configure-flags '())
			 board
			 (build-location "../build")
			 (source-location (getcwd))
			 build-type
			 inputs (out-of-source? #t))
  "Configure the given package."
  `(,(canonicalize-path source-location)
    ,@(if build-type
	  (list (string-append "-DCMAKE_BUILD_TYPE="
			       build-type))
	  '())
    ;; enable verbose output from builds
    "-DCMAKE_VERBOSE_MAKEFILE=ON"
    ,@(if board
	  (list (string-append "-DBOARD=" board))
	  '())
    ,(zephyr-modules-cmake-argument
      (find-zephyr-modules (map cdr inputs)))
    ,@configure-flags))

(define-command (guest-list . args)
  (synopsis "print $ZEPHYR_MODULES for cmake")
  (match args
    (("--help")
     (display (G_ "guest list search-path"))
     (newline)
     (display (G_ "
Print the ZEPHYR_MODULES cmake variable for modules found in SEARCH-PATH\n")))
    ((directories ...)
     (display (zephyr-modules-cmake-argument
	       (find-zephyr-modules directories))))))
