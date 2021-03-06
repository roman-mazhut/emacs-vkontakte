(require 'json)

(setq access_token "CHANGEME")
(setq profile_id CHANGEME)
(setq vk_api_url "https://api.vk.com/method/%s?%s&access_token=%s")

(defun array-to-list (array)
  (map 'list (lambda (x) x) array))

(defun find-vk-id-in-string (string)
  (setq friend-id nil)
  (setq p1 (posix-string-match "[0-9]+" string))
  (setq p2 (match-end 0))
  (when (and p1 p2)(setq friend-id (substring string p1 p2)))
  friend-id)

(defun vkontakte-get-username (user-id)
  (with-current-buffer
      (url-retrieve-synchronously (format vk_api_url "users.get" (format "user_ids=%s&fields=first_name,last_name" user-id) access_token))
    (sleep-for 0 300)
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq user (json-read-from-string (buffer-string)))
    (setq user (cdr (pop user)))
    (setq user (array-to-list user))
    (setq user (car user))
    (when (consp user)
      (setq first-name (decode-coding-string (cdr (assoc 'first_name user)) 'utf-8))
      (setq last-name (decode-coding-string (cdr (assoc 'last_name user)) 'utf-8))
      (format "%s %s"
	      first-name
	      last-name))))

(defun vkontakte-get-friends-list ()
  (with-current-buffer
      (url-retrieve-synchronously (format vk_api_url "friends.get" (format "user_id=%s&order=hints&fields=first_name,last_name,online" profile_id) access_token))
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq vkontakte-friends (json-read-from-string (buffer-string)))
    (setq vkontakte-friends (cdr (pop vkontakte-friends)))
    (array-to-list vkontakte-friends)
    ))

(defun vkontakte-send-message (friend-id message)
  (with-current-buffer
      (url-retrieve-synchronously (format vk_api_url "messages.send" (format "user_id=%s&message=%s" friend-id message) access_token))
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq message-send-result (json-read-from-string (buffer-string)))
    ))

(defun vkontakte-get-messages-history (friend-id)
  (with-current-buffer
      (url-retrieve-synchronously (format vk_api_url "messages.getHistory" (format "user_id=%s&count=25" friend-id) access_token))
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq messages-history (json-read-from-string (buffer-string)))
    (setq messages-history (cdr (pop messages-history)))
    (array-to-list messages-history)
    ))

(defun vkontakte-get-dialogs ()
  (with-current-buffer
      (url-retrieve-synchronously (format vk_api_url "messages.getDialogs" "count=15" access_token))
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq messages-history (json-read-from-string (buffer-string)))
    (setq messages-history (cdr (pop messages-history)))
    (array-to-list messages-history)
    ))

(defun vkontakte-get-friends ()
  (with-current-buffer (url-retrieve-synchronously (format vk_api_url "friends.get" (format "user_id=%s&order=hints&fields=first_name,last_name,online" profile_id) access_token))
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (setq friends (json-read-from-string (buffer-string)))
    (setq friends (cdr (pop friends)))
    (array-to-list friends)
    ))

(defun vkontakte-get-current-friend-id ()
  (setq p1 (line-beginning-position))
  (setq p2 (line-end-position))
  (setq line (buffer-substring-no-properties p1 p2))
  (setq friend-id (find-vk-id-in-string line))
  friend-id)

(defun vkontakte-draw-dialog-with-friend (friend-id)
  (setq vkontakte-dialog-buffer (get-buffer-create (format "*VK %s*" friend-id)))
  (set-buffer vkontakte-dialog-buffer)
  (erase-buffer)
  (font-lock-mode 1)
  (setq vkontakte-message-history (vkontakte-get-messages-history friend-id))
  (setq user-ids '())
  (loop for message being the elements of (reverse vkontakte-message-history)
	do
	(when (listp message)
	  (setq read_state (cdr (assoc 'read_state message)))
	  (setq from_id (cdr (assoc 'from_id message)))
	  (when (not (assoc (intern (format "%s" from_id)) user-ids))
	    (setq user-ids (acons (intern (format "%s" from_id)) (vkontakte-get-username from_id) user-ids)))
	  (setq username (cdr (assoc (intern (format "%s" from_id)) user-ids)))
	  (setq body (decode-coding-string (cdr (assoc 'body message)) 'utf-8))
	  (setq message-info (format "%s %s: %s\n"
				     from_id
				     username
				     body))
	  (setq message-info (propertize message-info 'font-lock-face `(:foreground ,(if (eq read_state 1) "green" "red"))))
	  (with-current-buffer vkontakte-dialog-buffer
	    (insert-string "--------------------\n")
	    (insert-string message-info)
	    (insert-string "--------------------\n"))))
  (local-set-key (kbd "C-c C-w") 'vkontakte-send)
  (local-set-key (kbd "C-c C-r") (lambda () (interactive) (vkontakte-draw-dialog-with-friend friend-id)))
  (switch-to-buffer vkontakte-dialog-buffer))

(defun vkontakte-open-dialog-with-current-friend ()
  (interactive)
  (setq current-friend-id (vkontakte-get-current-friend-id))
  (vkontakte-draw-dialog-with-friend current-friend-id))

(defun vkontakte-draw-friends ()
  (interactive)
  (setq vkontakte-friends-buffer (get-buffer-create "*VK Friends*"))
  (set-buffer vkontakte-friends-buffer)
  (erase-buffer)
  (font-lock-mode 1)
  (setq vkontakte-friends (vkontakte-get-friends))
  (loop for friend being the elements of vkontakte-friends
	do
	(setq online (cdr (assoc 'online friend)))
	(setq user_id (cdr (assoc 'user_id friend)))
	(setq first_name (decode-coding-string (cdr (assoc 'first_name friend)) 'utf-8))
	(setq last_name (decode-coding-string (cdr (assoc 'last_name friend)) 'utf-8))
	(setq friend-info (format "%10d %s %s\n"
				  user_id
				  first_name
				  last_name))
	(setq friend-info (propertize friend-info 'font-lock-face `(:foreground ,(if (eq online 1) "green" "red"))))
	(with-current-buffer vkontakte-friends-buffer
	  (insert-string friend-info)))
	(beginning-of-buffer)
	(local-set-key (kbd "C-c C-o") 'vkontakte-open-dialog-with-current-friend)
	(local-set-key (kbd "C-c C-w") 'vkontakte-send)
	(local-set-key (kbd "C-c C-r") 'vkontakte-draw-friends)
	(switch-to-buffer vkontakte-friends-buffer))

(defun vkontakte-draw-dialogs ()
  (interactive)
  (setq vkontakte-dialogs-buffer (get-buffer-create "*VK Dialogs*"))
  (set-buffer vkontakte-dialogs-buffer)
  (erase-buffer)
  (font-lock-mode 1)
  (setq vkontakte-dialogs (vkontakte-get-dialogs))
  (setq user-ids '())
  (loop for dialog being the elements of vkontakte-dialogs
	do
	(when (listp dialog)
	  (setq from_id (cdr (assoc 'uid dialog)))
	  (when (not (assoc (intern (format "%s" from_id)) user-ids))
	    (setq user-ids (acons (intern (format "%s" from_id)) (vkontakte-get-username from_id) user-ids)))
	  (setq dialog-name (cdr (assoc (intern (format "%s" from_id)) user-ids)))
	  (setq read-state (cdr (assoc 'read_state dialog)))
	  (setq dialog-info (format "%10d %20s | %s: %s\n"
				    from_id
				    dialog-name
				    (if (eq (cdr (assoc 'out dialog)) 1) "Me" dialog-name)
				    (decode-coding-string (cdr (assoc 'body dialog)) 'utf-8)))
	  (setq dialog-info (propertize dialog-info 'font-lock-face `(:foreground ,(if (eq read-state 1) "green" "red"))))
	  (with-current-buffer vkontakte-dialogs-buffer
	    (insert-string dialog-info)
	    (insert-string "-------------------------------------\n"))))
	(beginning-of-buffer)
	(local-set-key (kbd "C-c C-o") 'vkontakte-open-dialog-with-current-friend)
	(local-set-key (kbd "C-c C-w") 'vkontakte-send)
	(local-set-key (kbd "C-c C-r") 'vkontakte-draw-dialogs)
	(switch-to-buffer vkontakte-dialogs-buffer))

(defun vkontakte-send (message)
  (interactive "Message:")
  (setq friend-id (find-vk-id-in-string (buffer-name)))
  (when (not friend-id) (setq friend-id (vkontakte-get-current-friend-id)))
  (vkontakte-send-message friend-id message))
