;;; ijanet.el --- Interactive Janet mode

;; Copyright (C) 2019 Andres Mariscal

;; Author: Andres Mariscal <carlos.mariscal.melgar@gmail.com>
;; Created: 17 May 2019
;; Version: 0.0.1
;; Keywords: janet languages repl
;; URL: https://github.com/serialdev/ijanet-mode
;; Package-Requires: ((emacs "24.3", parsec ))
;;; Commentary:
;; Janet Repl support


;;; Commentary:
;;


(defun regex-match ( regex-string string-search match-num )
  (string-match regex-string string-search)
  (match-string match-num string-search))




(defcustom ijanet-shell-buffer-name "*Ijanet*"
  "Name of buffer for ijanet."
  :group 'ijanet
  :type 'string)

(defun ijanet-is-running? ()
  "Return non-nil if ijanet is running."
  (comint-check-proc ijanet-shell-buffer-name))
(defalias 'ijanet-is-running-p #'ijanet-is-running?)

;;;###autoload
(defun ijanet (&optional arg)
  "Run ijanet.
Unless ARG is non-nil, switch to the buffer."
  (interactive "P")
  (let ((buffer (get-buffer-create ijanet-shell-buffer-name)))
    (unless arg
      (pop-to-buffer buffer))
    (unless (ijanet-is-running?)
      (with-current-buffer buffer
        (ijanet-startup)
        (inferior-ijanet-mode)
	)
      (pop-to-buffer buffer)
      (other-window -1)
      )
    ;; (with-current-buffer buffer (inferior-ijanet-mode))
    buffer))



;;;###autoload
(defalias 'run-janet #'ijanet)
;;;###autoload
(defalias 'inferior-janet #'ijanet)


(defun ijanet-startup ()
  "Start ijanet."
(apply 'make-comint-in-buffer "janet" ijanet-shell-buffer-name ijanet-program nil (list "-s")))



(defun maintain-indentation (current previous-indent)
  (when current
    (let ((current-indent (length (ijanet-match-indentation (car current)))))
      (if (< current-indent previous-indent)
	  (progn
	    (comint-send-string ijanet-shell-buffer-name "\n")
	    (comint-send-string ijanet-shell-buffer-name (car current))
	    (comint-send-string ijanet-shell-buffer-name "\n"))
      (progn
	(comint-send-string ijanet-shell-buffer-name (car current))
	(comint-send-string ijanet-shell-buffer-name "\n")))
      (maintain-indentation (cdr current) current-indent)
      )))

(defun ijanet-split (separator s &optional omit-nulls)
  "Split S into substrings bounded by matches for regexp SEPARATOR.
If OMIT-NULLS is non-nil, zero-length substrings are omitted.
This is a simple wrapper around the built-in `split-string'."
  (declare (side-effect-free t))
  (save-match-data
    (split-string s separator omit-nulls)))


(defun ijanet-match-indentation(data)
  (regex-match "^[[:space:]]*" data 0))



(defun ijanet-eval-region (begin end)
  "Evaluate region between BEGIN and END."
  (interactive "r")
  (ijanet t)
  (progn
    (let ((content (ijanet-split "\n" (buffer-substring-no-properties begin end)) ))

      (print (buffer-substring-no-properties (region-beginning) (region-end)))
      (print content)
      (print (buffer-substring-no-properties begin end))
      (maintain-indentation content  0)
  )
    (comint-send-string ijanet-shell-buffer-name "\n")))






;; (defun ijanet-type-check ()
;;   (interactive)
;;   (comint-send-string ijanet-shell-buffer-name (concat "let ijanetmodetype: () = " (thing-at-point 'symbol) ";"))
;;   (comint-send-string ijanet-shell-buffer-name "\n")
;;   )

;; (defun ijanet-type-check-in-container ()
;;   (interactive)
;;   (comint-send-string ijanet-shell-buffer-name (concat "let ijanetmodetype: () = " (thing-at-point 'symbol) "[0];"))
;;   (comint-send-string ijanet-shell-buffer-name "\n")
;;   )


(defun ijanet-parent-directory (dir)
  (unless (equal "/" dir)
    (file-name-directory (directory-file-name dir))))

(defun ijanet-find-file-in-hierarchy (current-dir fname)
  "Search for a file named FNAME upwards through the directory hierarchy, starting from CURRENT-DIR"
  (let ((file (concat current-dir fname))
        (parent (ijanet-parent-directory (expand-file-name current-dir))))
    (if (file-exists-p file)
        file
      (when parent
        (ijanet-find-file-in-hierarchy parent fname)))))


(defun ijanet-get-string-from-file (filePath)
  "Return filePath's file content.
;; thanks to “Pascal J Bourguignon” and “TheFlyingDutchman 〔zzbba…@aol.com〕”. 2010-09-02
"
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))


(defun ijanet-eval-buffer ()
  "Evaluate complete buffer."
  (interactive)
  (ijanet-eval-region (point-min) (point-max)))

(defun ijanet-eval-line (&optional arg)
  "Evaluate current line.
If ARG is a positive prefix then evaluate ARG number of lines starting with the
current one."
  (interactive "P")
  (unless arg
    (setq arg 1))
  (when (> arg 0)
    (ijanet-eval-region
     (line-beginning-position)
     (line-end-position arg))))


;;; Shell integration

(defcustom ijanet-shell-interpreter "janet -s"
  "default repl for shell"
  :type 'string
  :group 'ijanet)

(defcustom ijanet-shell-internal-buffer-name "Ijanet Internal"
  "Default buffer name for the internal process"
  :type 'string
  :group 'janet
  :safe 'stringp)


(defcustom ijanet-shell-prompt-regexp "janet:[:digit:]+: "
  "Regexp to match prompts for ijanet.
   Matchint top\-level input prompt"
  :group 'ijanet
  :type 'regexp
  :safe 'stringp)


(defcustom ijanet-shell-prompt-block-regexp " "
  "Regular expression matching block input prompt"
  :type 'string
  :group 'ijanet
  :safe 'stringp)

(defcustom ijanet-shell-prompt-output-regexp ""
  "Regular Expression matching output prompt of evxcr"
  :type 'string
  :group 'ijanet
  :safe 'stringp)

(defcustom ijanet-shell-enable-font-lock t
  "Should syntax highlighting be enabled in the ijanet shell buffer?"
  :type 'boolean
  :group 'ijanet
  :safe 'booleanp)

(defcustom ijanet-shell-compilation-regexp-alist '(("[[:space:]]\\^+?"))
  "Compilation regexp alist for inferior ijanet"
  :type '(alist string))

(defgroup ijanet nil
  "Janet interactive mode"
  :link '(url-link "https://github.com/serialdev/ijanet-mode")
  :prefix "ijanet"
  :group 'languages)

(defcustom ijanet-program (executable-find "janet")
  "Program invoked by `ijanet'."
  :group 'ijanet
  :type 'file)


(defcustom ijanet-args "-s"
  "Command line arguments for `ijanet-program'."
  :group 'ijanet
  :type '(repeat string))



(defcustom ijanet-prompt-read-only t
  "Make the prompt read only.
See `comint-prompt-read-only' for details."
  :group 'ijanet
  :type 'boolean)

(defun ijanet-comint-output-filter-function (output)
  "Hook run after content is put into comint buffer.
   OUTPUT is a string with the contents of the buffer"
  (ansi-color-filter-apply output))


(defun ijanet-eval-sexp-at-point()
  (interactive)
  (let ((sexp (sexp-at-point) ))
    (when sexp
    (comint-send-string ijanet-shell-buffer-name     (message "%S" sexp))
    )
    (comint-send-string ijanet-shell-buffer-name "\n")
  ))


(define-derived-mode inferior-ijanet-mode comint-mode "Ijanet"
  (setq comint-process-echoes t)
  (setq comint-prompt-regexp ijanet-shell-prompt-regexp)

  (setq mode-line-process '(":%s"))
  (make-local-variable 'comint-output-filter-functions)
  (add-hook 'comint-output-filter-functions
  	    'ijanet-comint-output-filter-function)
  (set (make-local-variable 'compilation-error-regexp-alist)
       ijanet-shell-compilation-regexp-alist)
  (setq comint-use-prompt-regexp t)
  (setq comint-inhibit-carriage-motion nil)
  (setq-local comint-prompt-read-only ijanet-prompt-read-only)
  )

;; (progn
;;   (define-key janet-mode-map (kbd "C-c C-b") #'ijanet-eval-buffer)
;;   (define-key janet-mode-map (kbd "C-c C-r") #'ijanet-eval-region)
;;   (define-key janet-mode-map (kbd "C-c C-l") #'ijanet-eval-line)
;;   (define-key janet-mode-map (kbd "C-c C-p") #'ijanet))




(provide 'ijanet)

;;; ijanet.el ends here
