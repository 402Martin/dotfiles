# # [C-x] - Edit the current command line in $EDITOR
bindkey '^x' edit-command-line

# # [C-space] - Accept current suggestion
bindkey '^ ' autosuggest-accept

# # =============
# # Key-bindings
# # =============
bindkey -s '^b' 'tls^M'
bindkey -s '^p' 'tmuxinator-list.sh^M'
bindkey -s '^f' 'tmux-sessionizer.sh^M'
bindkey -s '^n' 'tns^M'
bindkey -s '^e' 'hexec.sh^M'
bindkey -s '^h' 'history.sh^M'
bindkey -s '^g' '. get-process.sh^M'
bindkey -s '^z' 'squash-pr-commits.sh^M'
bindkey -s '^d' 'commit-branch-name.sh^M'
