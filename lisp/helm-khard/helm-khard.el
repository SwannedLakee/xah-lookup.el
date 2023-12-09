;;; helm-khard.el --- Helm interface for Khard   -*- lexical-binding: t -*-

;; Copyright (C) 2023 Timm Lichte

;; Author: Timm Lichte <timm.lichte@uni-tuebingen.de>
;; URL: https://github.com/timmli/.emacs.d/tree/master/lisp/helm-khard.el
;; Version: 0
;; Last modified: 2023-12-09 Sat 20:56:38
;; Package-Requires: ((helm "3.9.6") (uuidgen "20220405.1345") (yaml-mode "0.0.13"))
;; Keywords: helm

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use,
;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following
;; conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;;; Code:

(require 'helm)
(require 'uuidgen)
(require 'yaml-mode)

(defcustom helm-khard-executable
	(executable-find "khard")
  "Path to Khard's executable."
  :type 'file)

(defcustom helm-khard-config-file
	""
  "Path to Khard's configuration file."
  :type 'file)

(defcustom helm-khard-command-fields
	'("index" "name" "organisations" "categories" "uid" "emails" "phone_numbers")
  "List of used Khard data fields as strings."
  :type 'sexp)

(defvar helm-khard--addressbooks nil
	"List of Khard's addressbooks. This variable is updated in
`helm-khard--import-contacts'.")

(defun helm-khard--import-contacts ()
  "Return a map whose keys are indexes and values are contacts."
	(setq helm-khard--addressbooks
				(let ((addressbooks (with-temp-buffer
															(call-process helm-khard-executable nil t nil
                                            "-c"  helm-khard-config-file
                                            "goto")
															(goto-char (point-min))
															(cl-loop
															 while (not (eobp))
															 collect (string-trim-right (thing-at-point 'line t))
															 do (forward-line)))))
					(cl-loop
					 for addressbook in addressbooks
					 collect `(,addressbook
										 ,(with-temp-buffer
												(call-process helm-khard-executable nil t nil
                                      "-c"  helm-khard-config-file
                                      "filename"
                                      "-a" addressbook)
												(goto-char (point-min))
												(file-name-directory (thing-at-point 'filename t)))))))
	(save-match-data
		(with-temp-buffer
			(call-process helm-khard-executable nil t nil 
                    "-c"  helm-khard-config-file
                    "list" "-p"
                    "-F" (mapconcat 'concat helm-khard-command-fields ","))
			(goto-char (point-min))
			(let (
						;; Each line consists of tab-separated fields
						(line-regexp (concat
													"^"
													(mapconcat
													 #'(lambda (field) (concat "\\(.*\\)")) ; "\\(.*?\\)" would not recognize the whole last field
													 helm-khard-command-fields "\t"))))
				(cl-loop
				 while (re-search-forward line-regexp nil t)
				 do (setq helm-khard--contact nil)
				 collect (progn
									 (setq helm-khard--contact nil)
									 (cl-loop
										for field in helm-khard-command-fields
										for field-number in (number-sequence 1 (length helm-khard-command-fields))
										do (let ((field-value (match-string field-number)))
												 (setq helm-khard--contact
															 (plist-put helm-khard--contact
																					(intern (concat ":" field)) ; Do not use make-symbol!!!
																					(helm-khard--clean-up-complex-field (or field-value "")) ; Function must have its own save-match-data!
																					))))
									 helm-khard--contact))))))

(defvar helm-khard--candidates nil
	"List of string-plist pairs which represent the candidates used in `helm-khard'.")

(defun helm-khard--clean-up-complex-field (field)
	"Clean up FIELD."
	(save-match-data
		;; Remove enclosing brackets
		(while (string-match "^{\\(.*\\)}$" field)
			(setq field (replace-match "\\1" nil nil field)))
		;; Process feature value pairs
		(while (string-match "'\\(.+?\\)': \\['\\(.+?\\)'\\]" field)
			(setq field (replace-match "\\2" nil nil field)))
		;; Remove :::
		(setq field (replace-regexp-in-string "[[:space:]]*:::[[:space:]]*" ", " field))
		;; Remove enclosing brackets
		(while (string-match "^\\[\\(.+?\\)\\]$" field)
			(setq field (replace-match "\\1" nil nil field)))
		;; Remove pairs of '
		(while (string-match "^'\\(.+?\\)', " field)
			(setq field (replace-match "\\1, " nil nil field)))
		(while (string-match ", '\\(.+?\\)', " field)
			(setq field (replace-match ", \\1, " nil nil field)))
		(while (string-match ", '\\(.+?\\)'$" field)
			(setq field (replace-match ", \\1" nil nil field)))
		(while (string-match "^'\\(.*\\)'$" field)
			(setq field (replace-match "\\1" nil nil field)))
		;; Remove remaining brackets
		(setq field (replace-regexp-in-string "[][{}()]" "" field)) ; ']' and '['  must appear in that order first in a character alternative!
		)
	field)

(defun helm-khard--window-width ()
	"Return the width of the window to pass to `helm-khard--candidates-formatter'."
	(1- (window-body-width)))

(defun trim-string-to-length (str max-length)
  "Trim a string to a specified maximum length."
  (substring str 0 (min (length str) max-length)))

(defun hk--trim-field-string (field-value column-length)
  "Trim a FIELD-VALUE to a specified COLUMN-LENGTH."
  (concat (trim-string-to-length
					 field-value
					 (- column-length 2))
					(when (> (length field-value) (- column-length 2))
						"…")))

(defun helm-khard-candidate-formatter (contact)
	"Format contact of `helm-khard'."
  (let* ((name (plist-get contact :name))
         (organisations (plist-get contact :organisations))
         (name+organisations (concat name
                                     (unless (string= organisations "")
                                       (concat " (" organisations ")"))))
         (emails (plist-get contact :emails))
         (phone_numbers (plist-get contact :phone_numbers))
         (categories (plist-get contact :categories)))
    (format "%1$-30s %2$-40s %3$-20s %4$s"
            (hk--trim-field-string name+organisations 30)
            (hk--trim-field-string emails 40)
            (hk--trim-field-string phone_numbers 20)
            categories)))

(defvar helm-khard--last-window-width 0
  "Window width when `helm-khard--make-candidates' was called the last time.")

(defcustom helm-khard-update-window-width nil
  "If non-nil, the candidate list format is updated every time the
window width changes.")

(defun helm-khard--make-candidates ()
	"Populate `helm-khard--candidates' and return it."
	(or (and
       (if helm-khard-update-window-width
           (eq (helm-khard--window-width) helm-khard--last-window-width)
         t)
       helm-khard--candidates)
      (and (setq helm-khard--last-window-width (helm-khard--window-width))
	         (setq helm-khard--candidates 
				         (cl-loop
				          for contact in (helm-khard--import-contacts)
				          collect `(,(helm-khard-candidate-formatter contact)
									          .
									          ,(list contact)))))))

(defun helm-khard-insert-email-action (candidate)
	"Insert emails of contact selected with Helm."
	(insert (string-join 
					 (cl-loop
						for contact in (helm-marked-candidates)
						collect (plist-get (car contact) :emails))
					 ", ")))

(defun helm-khard-insert-name+email-action (candidate)
	"Insert name+email of contact selected with Helm."
	(insert (string-join 
					 (cl-loop
						for contact in (helm-marked-candidates)
						collect (concat
										 "\"" (plist-get (car contact) :name) "\" "
										 "<" (plist-get (car contact) :emails) ">"))
					 ", ")))

(defun helm-khard-insert-phone-action (candidate)
	"Insert phone numbers of contact selected with Helm."
	(insert (string-join 
					 (cl-loop
						for contact in (helm-marked-candidates)
						collect (plist-get (car contact) :phone_numbers))
					 ", ")))

(defun helm-khard-edit-contact-action (candidate)
	"Open the YAML representation of contact selected with Helm."
	(interactive)
	(let* ((contact (car candidate))
				 (uuid (plist-get contact :uid))
				 (buffer (generate-new-buffer (format "*helm-khard<%s>*" uuid))))
		(with-current-buffer buffer
			(call-process helm-khard-executable nil t nil
                    "-c"  helm-khard-config-file
                    "show"
                    "--format" "yaml"
                    "--uid" uuid)
			(goto-char (point-min))
			(helm-khard-edit-mode)
			(setq-local helm-khard-edited-contact-uuid uuid))
		(switch-to-buffer buffer)
		(message "Press %s to save the contact and close the buffer."
						 (substitute-command-keys "\\[helm-khard-edit-finish]"))))

(defun helm-khard-new-contact-action (_candidate)
	"Open YAML template to create a new contact."
	(interactive)
	(let ((buffer (generate-new-buffer "*helm-khard<new>*")))
		(with-current-buffer buffer
			(call-process helm-khard-executable nil t nil
                    "-c"  helm-khard-config-file
                    "template")
			(helm-khard-edit-mode)
			(setq-local helm-khard-edited-contact-uuid nil))
		(switch-to-buffer buffer)
		(goto-char (point-min))
    ;; FIXME: Add candidate in the template as name.
		(message "Press %s to save the contact and close the buffer."
						 (substitute-command-keys "\\[helm-khard-edit-finish]"))))

(defvar-local helm-khard-edited-contact-uuid nil
	"Store the UUID of the contact associated with current buffer.
If nil, the buffer represents a new contact.")

(defvar helm-khard-edit-mode-map
	(let ((map (make-sparse-keymap)))
		(define-key map (kbd "C-c C-c") #'helm-khard-edit-finish)
		map)
	"Keymap for `helm-khard-edit-mode'.")

(defcustom helm-khard-edit-finished-hook nil
	"Hook run when the editing a contact is completed."
	:type 'hook)

(define-derived-mode helm-khard-edit-mode yaml-mode "Helm-khard"
	"Edit a contact using its YAML representation.")

(defcustom helm-khard-vcard-version "3.0"
	"Version of the VCard format used."
	:type 'string)

(defun helm-khard-edit-finish ()
	"Save contact in current buffer with helm-khard."
	(interactive)
	(let* ((input helm-input)
         (filename (make-temp-file "helm-khard-temp-"))
				 (args (if helm-khard-edited-contact-uuid
									 `("-c"  helm-khard-config-file
                     "modify"
										 "--uid" ,helm-khard-edited-contact-uuid
										 "--input-file" ,filename)
								 `("-c"  helm-khard-config-file
                   "new"
									 "--input-file" ,filename
									 "--vcard-version" ,helm-khard-vcard-version
									 "--addressbook"
									 ,(concat
										 (when helm-khard--addressbooks
											 (let ((choice
															(read-string
															 (concat
																"Available address books:\n"
																(cl-loop
																 for addressbook in helm-khard--addressbooks ; addressbook --> (NAME PATH)
																 for position in (number-sequence 0 (length helm-khard--addressbooks))
																 concat (format "\t(%s) %s\n" position (car addressbook))
																 )
																"Please choose an address book (0 is default): "))))
												 (car (nth (string-to-number choice) helm-khard--addressbooks)))))))))
		(write-region (point-min) (point-max) filename)
		(when (equal 0 (apply
										#'call-process-region
										"y\n" ;; ⇐ khard asks for confirmation
										nil
										helm-khard-executable
										nil t nil
										args))
			(kill-buffer)
      (setq helm-khard--candidates nil) ; Update candidates
      (helm-khard helm-input)
			(run-hooks 'helm-khard-edit-finished-hook))))

;; (add-hook 'helm-khard-edit-finished-hook
;; 					#'(lambda ()
;;               (setq helm-khard--candidates nil) ; Update candidates
;;               (helm-khard helm-input))) 

(defun helm-khard-open-vcf-action (candidate)
	"Open VCarf file of the selected contact."
	(let* ((contact (car candidate))
				 (uid (plist-get contact :uid))
				 (path (with-temp-buffer
								 (call-process helm-khard-executable nil t nil
                               "-c"  helm-khard-config-file
                               "filename" uid)
								 (goto-char (point-min))
								 (thing-at-point 'filename t))))
		(find-file-read-only path)))

(defun helm-khard-show-contact-action (candidate)
	"Show details of the selected contact."
	(let* ((input helm-input)
         (contact (car candidate))
				 (uid (plist-get contact :uid))
         (buffer-name "*helm-khard-show*")
				 (buffer (progn (when (get-buffer buffer-name) (kill-buffer buffer-name))
                        (generate-new-buffer buffer-name))))
	  (with-current-buffer buffer
		  (call-process helm-khard-executable nil t nil
                    "-c"  helm-khard-config-file
                    "show" uid)
      (setq buffer-read-only t)
      (local-set-key (kbd "q") 'kill-this-buffer)
		  (switch-to-buffer buffer)
		  (goto-char (point-min)))
    (helm-khard input)))

(defun helm-khard-remove-contact-action (candidate)
	"Remove selected contacts from Khard's database."
  (let ((input helm-input))
	  (cl-loop
	   for raw-candidate in (helm-marked-candidates)
	   do (let* ((contact (car raw-candidate))
						   (uid (plist-get contact :uid))
						   (name (plist-get contact :name)))
				  (if (y-or-n-p (format "Do you want to remove contact %s with uid %s?" name uid))
						  (with-temp-buffer
							  (call-process helm-khard-executable nil t nil
                              "-c"  helm-khard-config-file
                              "remove"
                              "--force" uid)
							  (goto-char (point-min))
							  (message "helm-khard: %s" (string-trim-right (thing-at-point 'line t)))
							  (setq helm-khard--candidates nil)))))
    (helm-khard input)))

(defun helm-khard-copy-vcf-action (candidate)
	"Copy a VCard file from Khard's database to a directory specified by
prompt."
	(let ((to-path (read-directory-name "Select where to copy the VCF: ")))
		(cl-loop
		 for raw-candidate in (helm-marked-candidates)
		 do (let* ((contact (car raw-candidate))
							 (uid (plist-get contact :uid))
							 (name (plist-get contact :name))
							 (from-filename (with-temp-buffer
																(call-process helm-khard-executable nil t nil
                                              "-c"  helm-khard-config-file
                                              "filename" uid)
																(goto-char (point-min))
																(thing-at-point 'filename t)))
							 (to-filename (concat
														 to-path
														 (replace-regexp-in-string " " "" name)
														 ".vcf")))
					(copy-file from-filename to-filename t)
					(message "helm-khard: Copied %s to %s." from-filename to-filename)))))

(defvar helm-khard-vdirsyncer-command
	"vdirsyncer sync"
	"Vdirsyncer command with arguments used in `helm-khard--sync-database'.")

(defun helm-khard-sync-database-action (_candidate)
	"Sync database of Khard using the function in
`helm-khard-vdirsyncer-command'."
  (let*((input helm-input)
        (command (car (split-string helm-khard-vdirsyncer-command)))
        (args (cdr (split-string helm-khard-vdirsyncer-command)))
				(buffer-name "*vdirsyncer-sync*")
				(buffer (progn (when (get-buffer buffer-name) (kill-buffer buffer-name))
											 (get-buffer-create buffer-name))))
		(with-current-buffer buffer
			(apply 'call-process command nil t nil args)
		  (setq buffer-read-only t)
      (local-set-key (kbd "q") 'kill-this-buffer)
		  (switch-to-buffer buffer)
		  (goto-char (point-min)))
	  (message "tl/vdirsyncer-sync-contacts: Syncing in progress, see buffer %s" buffer-name))
	(setq helm-khard--candidates nil)
  (helm-khard input))

(defun helm-khard-import-vcf-action (_candidate)
	"Import VCF with one or more contacts. This function is used by
`helm-khard' when performing an action on a candidate."
	(interactive)
	(let ((input helm-input)
        (filename (read-file-name "Path to VCard file (VCF) to be imported: " (expand-file-name "~/")))
				(dest-path (if helm-khard--addressbooks
						           (let ((choice
										          (read-string
										           (concat
											          "Available address books:\n"
											          (cl-loop
											           for addressbook in helm-khard--addressbooks ; addressbook --> (NAME PATH)
											           for position in (number-sequence 0 (length helm-khard--addressbooks))
											           concat (format "\t(%s) %s\n" position (car addressbook))
											           )
											          "Please choose a target address book (0 is default): "))))
							           (car (cdr (nth (string-to-number choice) helm-khard--addressbooks))))
					           nil)))
		(let ((contacts (helm-khard--import-vcf filename dest-path))) ; VCF can contain several contacts!
			(setq helm-khard--candidates nil)		; Update candidates when calling the `helm-khard' the next time.
			(helm-khard--make-candidates)
			(if (yes-or-no-p (concat
											  "Found " (number-to-string (length contacts)) " contact(s):\n"
											  (cl-loop
											   for contact in contacts
											   concat (concat "- " contact "\n"))  
											  "Do want to edit these imported contacts? "))
				  (cl-loop
				   for contact in contacts
				   ;; do (helm-khard-edit-contact-action contact) ; FIXME
           )
        (helm-khard input)))))

(defun helm-khard--import-vcf (vcf dest-path)
	"Import the contacts in VCF, a file in the VCard format. VCF is
split into several files, adding an UUID if necessary. DEST-PATH
specifies the directory path where the resulting VCFs, named with
their UUID, are put. The function returns a list of UUIDs of the
found contacts."
	(with-temp-buffer 
    (insert-file-contents (expand-file-name vcf))
		(goto-char (point-min))
		(save-match-data
			(cl-loop
			 while (re-search-forward "BEGIN:VCARD" nil t)
			 collect (let ((start-pos (match-beginning 0))) ; The match includes BEGIN:VCARD
								 (if (re-search-forward "END:VCARD" nil t)
										 (let* ((end-pos (match-end 0)) ; The match includes END:VCARD
														(vcard-content (buffer-substring-no-properties start-pos end-pos)))
											 (when (helm-khard--vcard-sanity-check vcard-content)
												 (with-temp-buffer
													 (insert vcard-content)
													 (goto-char (point-min))
													 ;; Keep existing UID, otherwise create new one
													 (let* ((uuid-regexp "^[[:space:]]*UID:[[:space:]]*\\(.+\\)[[:space:]]*$")
																	(uuid (or (save-match-data
																							(re-search-forward uuid-regexp nil t)
																							(match-string 1))
																						(uuidgen-4))) ; uuidgen-4 is from the package uuidgen
																	(filename (concat uuid ".vcf")))
														 (unless (re-search-forward uuid-regexp nil t)
															 (goto-char (point-min))
															 (re-search-forward "BEGIN:VCARD" nil t)
															 (insert "\nUID:" uuid))
														 (write-region (point-min) (point-max) (expand-file-name filename dest-path))
														 uuid))))))))))

(defun helm-khard--vcard-sanity-check (vcard)
	"Check the string VCARD for compliance with the VCard format. It
is assumed that VCARD contains exactly one contact. If VCARD
passes the check, the result is non-nil, otherwise nil."
	(with-temp-buffer
		(insert vcard)
		(goto-char (point-min))
		(save-match-data
			(if (re-search-forward "BEGIN:VCARD" nil t)
					(let ((begin-point (match-end 0)))
						(while (re-search-forward "END:VCARD" nil t))
						(let ((end-point (match-beginning 0)))
							(if (< begin-point end-point) ;; False when there is no END:VCARD
									;; Check the properties between BEGIN:VCARD and END:VCARD
									(cl-loop
									 for line in (split-string (buffer-substring-no-properties begin-point end-point) "\n" t)
									 do (unless (and (numberp (string-match-p "^.+:" line))
																	 (not (numberp (string-match-p "\\(BEGIN\\|END\\):VCARD" line))))
												(cl-return nil))
									 finally return t)								
								nil)))
				nil))))

(defun helm-khard--inject-contacts-into-mu4e (&rest _contacts)
  "Inject Khard's contacts into `mu4e--contacts-set'. Note that,
in order to take effect, this function must be added to an
appropriate hook, or to the function `mu4e--update-contacts',
which updates `mu4e--contacts-set'."
	(unless  helm-khard--candidates
	  (helm-khard--import-contacts))
	(cl-loop
	 for contact in helm-khard--candidates
	 for name = (plist-get (car (cdr contact)) :name)
	 for organisation = (plist-get (car (cdr contact)) :organisations)
	 for emails = (plist-get (car (cdr contact)) :emails)
	 if (not (string= "" emails))
	 do (cl-loop
			 for email in (split-string emails ", ")
			 for name+orga = (concat name (unless (string= organisation "")
																			(concat "  (" organisation ")"))) 
			 for name+orga+email = (concat "\"" name+orga "\" " "<" email ">")
			 do (if (hash-table-p mu4e--contacts-set)
							(puthash name+orga+email t mu4e--contacts-set)
						(message "helm-khard--inject-contacts-into-mu4e: Warning: mu4e--contacts-set is not (yet) a hash!")))))

;; (defcustom helm-khard-inject-mu4e
;;   nil
;;   "When set to non-nil, inject Khard contacts into mu4e's contact set."
;;   :type 'boolean)

(defun helm-khard-new-contact-transformer-action (actions candidate)
  "Action transformer for the `helm-khard' source. If the
candidat is '*Add new contact*', there is only one action to
create a new contact."
  (if (and (stringp candidate) (string= (string candidate) "*Add new contact*"))
      (helm-make-actions
       "New contact" #'helm-khard-new-contact-action
       ;; "Import contacts from VCF" #'helm-khard-import-vcf-action
       ;; "Sync with database" #'helm-khard-sync-database-action
       )
    actions))

(defvar helm-khard--actions
	(helm-make-actions "Insert email address" #'helm-khard-insert-email-action
										 "Insert name + email address" #'helm-khard-insert-name+email-action
										 "Insert phone number" #'helm-khard--insert-phone-action
										 ;; "Compose email" #'helm-khard--compose-email
										 "Edit contact" #'helm-khard-edit-contact-action
										 "New contact" #'helm-khard-new-contact-action
										 "Remove contact" #'helm-khard-remove-contact-action
										 ;; "Merge contact" #'helm-khard--merge-contacts
										 "Show contact" #'helm-khard-show-contact-action
										 "Open VCF of contact" #'helm-khard-open-vcf-action
										 "Copy VCF of contact" #'helm-khard-copy-vcf-action
										 "Import contacts from VCF" #'helm-khard-import-vcf-action
										 ;; "Attach conctact to email" #'helm-khard--attach-contact 
										 "Sync with database" #'helm-khard-sync-database-action
										 )
	"List of pairs (STRING FUNCTIONSYMBOL), which represent the
actions used in `helm-khard'.")

;;;###autoload
(defun helm-khard (&optional input)
	"Search and manage Khard contacts through Helm."
	(interactive)
	(helm :sources (helm-build-sync-source "Khard contacts:"
									 :candidates #'helm-khard--make-candidates
									 :display-to-real nil	; Transform the selected candidate when passing it to action.
									 :action helm-khard--actions
									 ;; :filtered-candidate-transformer 'my-transformer-function
									 :fuzzy-match nil
                   :filtered-candidate-transformer (lambda (candidates _source)
                                                     (if (not candidates)
                                                         (list "*Add new contact*")
                                                       candidates))
                   :action-transformer (lambda (actions candidate)
                                         (helm-khard-new-contact-transformer-action actions candidate))
				           )
	      :buffer "*helm-khard*"
	      :update (lambda () (setq helm-khard--candidates nil))
        :truncate-lines helm-buffers-truncate-lines
        :input (or input
                   (and (use-region-p)
                        (buffer-substring-no-properties (region-beginning) (region-end)))
                   (and (thing-at-point 'email t)
                        (string-remove-prefix "<" (string-remove-suffix ">" (thing-at-point 'email t))))
                   ;; (thing-at-point 'word t)
                   "")))

(provide 'helm-khard)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; helm-khard.el ends here
