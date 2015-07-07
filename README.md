# emacs-vkontakte
Simple implementation of vk messaging for emacs

# Getting of vkontakte oauth token
1) Register new app at https://vk.com/editapp?act=create <br/>
2) Go to https://oauth.vk.com/authorize?client_id=APP_ID&scope=69634&redirect_uri=https://oauth.vk.com/blank.html&display=page&v={version}&response_type=token <br/>
3) Take code from url you redirected to <br/>

# Setting up
(setq access_token YOUR_ACCESS_TOKEN) <br/>
(setq profile_id YOUR_PROFILE_ID) <br/>

# Methods and hot keys
M-x vkontakte-draw-friends - show all your friends <br/>
M-x vkontakte-draw-dialogs - show dialogs <br/>
C-c C-o - open dialog at point or dialog with friend at point <br/>
C-c C-w - write message to current dialog or friend at point <br/>
C-c C-r - refresh buffer <br/>

# ToDo
* Refactoring <br/>
* Add timer for auto-reload buffers <br/>
* Mark messages as read when dialog opened <br/>
