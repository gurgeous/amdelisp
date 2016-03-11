;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add the lisp directories to the load path so we can find these
;; packages easily. First add /elisp, then subdirs.

; check version
(when (< (string-to-number (substring emacs-version 0 2)) 24)
  (error "amdelisp only works with emacs 24 or higher"))

;; set amd-elisp
(defvar amd-elisp
  (let* ((this-file (file-truename load-file-name))
         (this-dir (substring (file-name-directory this-file) 0 -1)))
    this-dir))

(add-to-list 'load-path amd-elisp)
(add-to-list 'load-path (format "%s/emacslib" amd-elisp))

(defvar is-win32 (memq system-type '(windows-nt ms-dos ms-windows)))
(defvar is-mac (string-equal system-type "darwin"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)

(package-initialize)

;; install these packages, if necessary
(defun install-packages (packages)
  (let ((install nil))
    (dolist (i packages)
      (if (not (package-installed-p i))
          (setq install t)))
    (when install
      (message "Refreshing package database...")
      (package-refresh-contents)
      (dolist (i packages)
        (when (not (package-installed-p i))
          (message "Installing package %s" i)
          (package-install i))))))

(install-packages
 '(ascii coffee-mode csharp-mode css-mode
         exec-path-from-shell guess-offset haml-mode
         js2-mode less-css-mode lorem-ipsum lua-mode magit
         markdown-mode pager php-mode python-mode rainbow-mode
         ruby-mode solarized-theme volatile-highlights yaml-mode
         yari column-enforce-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Preload stuff.

(load "added")
(load "modes")
(load "prefs")
(load "autoloads")
(load "patches")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inhibit-startup-message is reset to nil right after this file
;; is loaded, so we have to add an after-init-hook to reset it.

(if inhibit-startup-message
    (add-hook 'after-init-hook (lambda () (setq inhibit-startup-message t))))
