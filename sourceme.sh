tojson(){ # translate text to json
	cat | jq -R | sed 's/^.// ; s/.$/\\n/' | tr -d '\n'
}

message() { # Usage: $0 [MESSAGE] [CHATFILE] [APIKEY] [MODEL] [URL]
	mkdir -p "$(dirname "$2")"
	echo "$(printf '{"role": "user","content": "%s"}' "$(echo "$1" | tojson)")" >> "$2"
	# echo user's message to the chatfile

	data="$(printf '{"model": "%s", "stream": true, "messages": [%s]}' "$4" "$(cat "$2")" )"

	content=$(mktemp)
	curl --request POST --url $5 \
		--header "Authorization: Bearer $3" \
		--header 'Content-Type: application/json' \
		--data "$data" 2> /dev/null \
	| while IFS= read -r line; do 
		echo "$line" | sed 's/^......//' | grep '^{' \
		| tee >(jq '.choices[0].delta.content' | grep '^"' | jq -j | tee /dev/tty >> $content) \
		| jq '.choices[0].delta.reasoning_content' | grep '^"' | jq -j 
	done
	echo

	echo "$(printf ',{ "role": "assistant", "content": "%s" },' "$(cat $content | tojson)")" >> "$2"
	# echo assistant's message to the chatfile
}


if [ -z "$XDG_CONFIG_HOME" ]; then
	CHAT_HOME="$HOME/.config/chat"
else
	CHAT_HOME="$XDG_CONFIG_HOME/chat"
fi

v3(){
	message "$1" "$CHAT_HOME/$2" "$apikey" "Pro/deepseek-ai/DeepSeek-V3" "https://api.siliconflow.cn/v1/chat/completions"
}

r1(){
	message "$1" "$CHAT_HOME/$2" "$apikey" "Pro/deepseek-ai/DeepSeek-R1" "https://api.siliconflow.cn/v1/chat/completions"
}

lsc(){
	ls "$CHAT_HOME"
}

rmc(){
	rm "$CHAT_HOME/$1"
}

catc(){
	cat "$CHAT_HOME/$1" | sed 's/^,// ; s/,$//' | jq -r ".content"
}
