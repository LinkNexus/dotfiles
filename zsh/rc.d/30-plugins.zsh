for zsh_autosuggestions_prefix in ${(s.:.)PATH}; do
	for zsh_autosuggestions_file in "${zsh_autosuggestions_prefix%/bin}"/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh(N) \
		"${zsh_autosuggestions_prefix%/bin}"/share/zsh-autosuggestions/zsh-autosuggestions.zsh(N); do
		[[ -f "$zsh_autosuggestions_file" ]] && { source "$zsh_autosuggestions_file"; break 2 }
	done
done
unset zsh_autosuggestions_prefix zsh_autosuggestions_file
