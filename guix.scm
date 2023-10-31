(use-modules (guix)
	     (guix build-system gnu)
	     (guix git-download)
	     ((guix licenses) #:prefix license:)
	     (guix packages)
	     (gnu packages autotools)
	     (gnu packages guile)
	     (gnu packages guile-xyz)
	     (gnu packages pkg-config)
	     (gnu packages texinfo))

(define vcs-file?
  ;; Return true if the given file is under version control.
  (or (git-predicate (dirname (dirname (current-source-directory))))
      (const #t)))

(package
 (name "guest")
 (version "0.0.1-git")
 (home-page "https://github.com/paperclip4465/guix-zephyr")
 (source (local-file "." "guest-checkout"
		     #:recursive? #t
		     #:select? vcs-file?))
 (build-system gnu-build-system)
 (arguments
  `(#:modules
    ((ice-9 match)
     (ice-9 ftw)
     ,@%gnu-build-system-modules)
    #:phases
    (modify-phases
     %standard-phases
     (add-after
      'install
      'hall-wrap-binaries
      (lambda* (#:key inputs outputs #:allow-other-keys)
	(let* ((compiled-dir
		(lambda (out version)
		  (string-append
		   out
		   "/lib/guile/"
		   version
		   "/site-ccache")))
	       (uncompiled-dir
		(lambda (out version)
		  (string-append
		   out
		   "/share/guile/site"
		   (if (string-null? version) "" "/")
		   version)))
	       (dep-path
		(lambda (env modules path)
		  (list env
			":"
			'prefix
			(cons modules
			      (map (lambda (input)
				     (string-append
				      (assoc-ref inputs input)
				      path))
				   ,''("guile-libyaml"))))))
	       (out (assoc-ref outputs "out"))
	       (bin (string-append out "/bin/"))
	       (site (uncompiled-dir out "")))
	  (match (scandir site)
	    (("." ".." version)
	     (for-each
	      (lambda (file)
		(wrap-program
		 (string-append bin file)
		 (dep-path
		  "GUILE_LOAD_PATH"
		  (uncompiled-dir out version)
		  (uncompiled-dir "" version))
		 (dep-path
		  "GUILE_LOAD_COMPILED_PATH"
		  (compiled-dir out version)
		  (compiled-dir "" version))))
	      ,''("guest"))
	     #t))))))))
 (inputs
  (list guile-3.0
	guile-libyaml))
 (native-inputs
  (append
   (list autoconf
	 automake
	 pkg-config
	 texinfo)
   (if (%current-target-system)
       ;; add guile/libs for cross compilation support
       (list guile-3.0
	     guile-libyaml)
       '())))
 (native-search-paths
  (list (search-path-specification
	 (variable "ZEPHYR_MODULE_PATH")
	 (files '("zephyr-workspace/modules")))))
 (synopsis "Project meta-tool for Zephyr RTOS")
 (description "Guest is a West replacement implemented in GNU Guile.")
 (license license:gpl3+))
