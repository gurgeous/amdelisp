;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; confirm before killing emacs

(defvar confirm-before-kill-emacs nil)
(defun my-kill-emacs-query-function ()
  (or (not confirm-before-kill-emacs)
      (yes-or-no-p "Really kill Emacs? ")))
(add-to-list 'kill-emacs-query-functions 'my-kill-emacs-query-function)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tags

(defun tags-search-tags-table ()
  "Walk directories, looking for a TAGS file. If we find one, visit it."
  (interactive)
  (let ((tags (locate-dominating-file (concat default-directory "gub") "TAGS")))
    (if tags
        (progn
          (visit-tags-table tags)
          (if (functionp 'ffip-clear-project-cache)            
              (ffip-clear-project-cache))
          (message "Loaded %s." tags))
      (error "Could not find TAGS in current path."))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; some useful editing functions

(defun to-column (c &optional text)
  (interactive "nColumn: ")
  (if (null text)
      (setq text " "))
  (if (< (current-column) c)
      (while (< (current-column) c)
        (insert text))))

(defvar current-num 0)
(defun insert-next-num ()
  (interactive)
  (insert (format "%d" current-num))
  (setq current-num (+ current-num 1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; hippie/tabs

(require 'hippie-exp)

(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name
        try-complete-lisp-symbol))

(setq hippie-expand-ignore-buffers
      (append hippie-expand-ignore-buffers '("TAGS")))

(defun my-hippie-tab (arg)
  "Ordinary tab or dabbrev"
  (interactive "*P")
  (cond
   ((and transient-mark-mode mark-active)
    (indent-region (region-beginning) (region-end) nil))
   ((and (eq (char-syntax (preceding-char)) ?w)
         (not (= (current-column) 0)))
    (hippie-expand arg))
   (t (indent-for-tab-command))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rebuild autoloads

(eval-when-compile (require 'autoload))
(defun rebuild-autoloads-dir (dir)
  (dolist (file (directory-files dir))
    (let ((path (format "%s/%s" dir file))
          (excludes '("." "..")))
      (cond
                                        ; ignore some files
       ((or (member file excludes)
            (string-match "autoloads.el$" file)))
       ((file-directory-p path) (rebuild-autoloads-dir path))
       ((string-match ".el$" file)
        (message "generate-file-autoloads(%s)..." file)
        (generate-file-autoloads path))))))

(defun rebuild-autoloads ()
  (interactive)
  (require 'autoload)
  (let* ((source-directory AMDELISP)
         (autoloads (format "%s/autoloads.el" source-directory)))
    (save-excursion
      (with-current-buffer (find-file-noselect autoloads)
        (delete-region (point-min) (point-max))
        (rebuild-autoloads-dir source-directory)
        (save-buffer))
      (message "rebuild-autoload : %s - Done." autoloads))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; nice way to increase/decrese left margin

(defun expand-region-to-whole-lines ()
  "Expand the region to make it encompass whole lines.
If the region is not active, activate the current line."
  (if (not mark-active)
      ;; Create region from current line
      (progn 
        (beginning-of-line)
        (set-mark (point))
        (end-of-line))
    ;; The mark is active, expand region
    (let ((beg (region-beginning))
          (end (region-end)))
      (goto-char beg)
      (beginning-of-line)
      (set-mark (point))
      (goto-char end)
      (unless (bolp) (end-of-line)))))

(defun my-increase ()
  "Increase left margin in region after expanding it to whole lines."
  (interactive)
  (let (deactivate-mark)
    (save-excursion
      (expand-region-to-whole-lines)
      (increase-left-margin (region-beginning) (region-end) nil))))

(defun my-decrease ()
  "Decrease left margin in region after expanding it to whole lines."
  (interactive)
  (let (deactivate-mark)
    (save-excursion
      (expand-region-to-whole-lines)
      (decrease-left-margin (region-beginning) (region-end) nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; kill buffers matching a regex

(defun kill-buffers (regexp)
  (interactive "sKill buffers with file names matching this regex: ")
  (dolist (buffer (buffer-list))
    (let ((file-name (buffer-file-name buffer)))
      (when (and file-name
                 (string-match regexp file-name))
        (message "Killing %s" file-name)
        (kill-buffer buffer)))))

(provide 'added)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; position the main window at startup

(defvar window-position 'right)
(defvar window-columns 100)
(defvar window-fudge '(0 12 0 55))

(defun window-layout ()
  (let ((display-width  (x-display-pixel-width))
        (display-height (x-display-pixel-height))
        (left   (nth 0 window-fudge))
        (right  (nth 1 window-fudge))
        (top    (nth 2 window-fudge))
        (bottom (nth 3 window-fudge))
        (width (* (+ 2 window-columns) (frame-char-width)))
        )

    (add-to-list 'default-frame-alist (cons 'left
                                            (case window-position
                                              ('right (- display-width (+ width right 15)))
                                              ('left left)
                                              ('center (/ (- display-width width) 2)))))
    (add-to-list 'default-frame-alist (cons 'top top))
    (add-to-list 'default-frame-alist (cons 'width window-columns)) 
    (add-to-list 'default-frame-alist (cons 'height (/ (- display-height top bottom 25)
                                                       (frame-char-height))))))

(when window-system
  (add-hook 'after-init-hook 'window-layout))
