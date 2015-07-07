# emacs-vkontakte
Simple implementation of vk messaging for emacs

# Getting of vkontakte oauth token
1) Register new app at https://vk.com/editapp?act=create
2) Go to https://oauth.vk.com/authorize?client_id=APP_ID&scope=69634&redirect_uri=https://oauth.vk.com/blank.html&display=page&v={version}&response_type=token
3) Take code from url you redirected to

# Setting up
(setq access_token YOUR_ACCESS_TOKEN)
(setq profile_id YOUR_PROFILE_ID)

# Methods and hot keys
M-x vkontakte-draw-friends - show all your friends
M-x vkontakte-draw-dialogs - show dialogs
C-c C-o - open dialog at point or dialog with friend at point
C-c C-w - write message to current dialog or friend at point
C-c C-r - refresh buffer

# ToDo
* Refactoring
* Add timer for auto-reload buffers
* Mark messages as read when dialog opened
