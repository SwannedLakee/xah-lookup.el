;;; mu4e-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from mu4e.el

(autoload 'mu4e "mu4e" "\
If mu4e is not running yet, start it.
Then, show the main window, unless BACKGROUND (prefix-argument)
is non-nil.

(fn &optional BACKGROUND)" t)
(register-definition-prefixes "mu4e" '("mu4e--"))


;;; Generated autoloads from mu4e-actions.el

(register-definition-prefixes "mu4e-actions" '("mu4e-"))


;;; Generated autoloads from mu4e-bookmarks.el

(register-definition-prefixes "mu4e-bookmarks" '("mu4e-"))


;;; Generated autoloads from mu4e-compose.el

(defalias 'mu4e-compose-mail #'mu4e-compose-new)
(autoload 'mu4e-compose-new "mu4e-compose" "\
Mu4e's implementation of `compose-mail'.
TO, SUBJECT, OTHER-HEADERS, CONTINUE, YANK-ACTION SEND-ACTIONS
RETURN-ACTION are as described in `compose-mail', and to the
extend that they do not conflict with mu4e's inner workings.
SWITCH-FUNCTION is ignored.

(fn &optional TO SUBJECT OTHER-HEADERS CONTINUE SWITCH-FUNCTION YANK-ACTION SEND-ACTIONS RETURN-ACTION &rest _)" t)
(autoload 'mu4e-compose-reply-to "mu4e-compose" "\
Reply to the message at point.
Optional TO can be the To: address for the message. If WIDE is
non-nil, make it a \"wide\" reply (a.k.a. \"reply-to-all\").

(fn &optional TO WIDE)" t)
(autoload 'mu4e-compose-reply "mu4e-compose" "\
Reply to the message at point.
If WIDE is non-nil, make it a \"wide\" reply (a.k.a.
\"reply-to-all\").

(fn &optional WIDE)" t)
(autoload 'mu4e-compose-wide-reply "mu4e-compose" "\
Wide reply to the message at point.
I.e., \"reply-to-all\"." t)
(autoload 'mu4e-compose-supersede "mu4e-compose" "\
Supersede the message at point.

That is, send the message again, with all the same recipients;
this can be useful to follow-up on a sent message. The message
must originate from the current user, as determined through
`mu4e-personal-or-alternative-address-p'." t)
(autoload 'mu4e-compose-edit "mu4e-compose" "\
Edit an existing draft message." t)
(autoload 'mu4e-compose-resend "mu4e-compose" "\
Re-send the message at point to ADDRESS.
The message is resent as-is, without any editing. See
`message-resend' for details.

(fn ADDRESS)" t)
(define-mail-user-agent 'mu4e-user-agent #'mu4e-compose-mail #'message-send-and-exit #'message-kill-buffer 'message-send-hook)
(register-definition-prefixes "mu4e-compose" '("mu4e-"))


;;; Generated autoloads from mu4e-config.el

(register-definition-prefixes "mu4e-config" '("mu4e-"))


;;; Generated autoloads from mu4e-contacts.el

(register-definition-prefixes "mu4e-contacts" '("mu4e-"))


;;; Generated autoloads from mu4e-context.el

(register-definition-prefixes "mu4e-context" '("mu4e-" "with-mu4e-context-vars"))


;;; Generated autoloads from mu4e-contrib.el

(register-definition-prefixes "mu4e-contrib" '("eshell/mu4e-attach" "mu4e-"))


;;; Generated autoloads from mu4e-draft.el

(register-definition-prefixes "mu4e-draft" '("mu4e-"))


;;; Generated autoloads from mu4e-folders.el

(register-definition-prefixes "mu4e-folders" '("mu4e-"))


;;; Generated autoloads from mu4e-headers.el

(register-definition-prefixes "mu4e-headers" '("mu4e"))


;;; Generated autoloads from mu4e-helpers.el

(register-definition-prefixes "mu4e-helpers" '("mu4e-"))


;;; Generated autoloads from mu4e-icalendar.el

(register-definition-prefixes "mu4e-icalendar" '("mu4e-"))


;;; Generated autoloads from mu4e-lists.el

(register-definition-prefixes "mu4e-lists" '("mu4e-"))


;;; Generated autoloads from mu4e-main.el

(register-definition-prefixes "mu4e-main" '("mu4e-"))


;;; Generated autoloads from mu4e-mark.el

(register-definition-prefixes "mu4e-mark" '("mu4e-"))


;;; Generated autoloads from mu4e-message.el

(register-definition-prefixes "mu4e-message" '("mu4e-"))


;;; Generated autoloads from mu4e-mime-parts.el

(register-definition-prefixes "mu4e-mime-parts" '("mu4e"))


;;; Generated autoloads from mu4e-modeline.el

(register-definition-prefixes "mu4e-modeline" '("mu4e-"))


;;; Generated autoloads from mu4e-notification.el

(register-definition-prefixes "mu4e-notification" '("mu4e-"))


;;; Generated autoloads from mu4e-org.el

(register-definition-prefixes "mu4e-org" '("mu4e-"))


;;; Generated autoloads from mu4e-query-items.el

(register-definition-prefixes "mu4e-query-items" '("mu4e-"))


;;; Generated autoloads from mu4e-search.el

(register-definition-prefixes "mu4e-search" '("mu4e-"))


;;; Generated autoloads from mu4e-server.el

(register-definition-prefixes "mu4e-server" '("mu4e-"))


;;; Generated autoloads from mu4e-speedbar.el

(autoload 'mu4e-speedbar-buttons "mu4e-speedbar" "\
Create buttons for any mu4e BUFFER.

(fn &optional BUFFER)" t)
(register-definition-prefixes "mu4e-speedbar" '("mu4e"))


;;; Generated autoloads from mu4e-thread.el

(register-definition-prefixes "mu4e-thread" '("mu4e-thread-"))


;;; Generated autoloads from mu4e-update.el

(register-definition-prefixes "mu4e-update" '("mu4e-"))


;;; Generated autoloads from mu4e-vars.el

(register-definition-prefixes "mu4e-vars" '("mu4e"))


;;; Generated autoloads from mu4e-view.el

(register-definition-prefixes "mu4e-view" '("gnus-icalendar-event-from-handle" "mu4e-"))


;;; Generated autoloads from mu4e-window.el

(register-definition-prefixes "mu4e-window" '("mu4e-"))

;;; End of scraped data

(provide 'mu4e-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; mu4e-autoloads.el ends here
