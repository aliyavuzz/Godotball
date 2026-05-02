#!/bin/bash
TOKEN="8644100197:AAEbi0mYfCFQD3vN3Sx1DI8bJJK8hH1j17E"
CHAT_ID="825638717"
MESSAGE="$1"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "text=$MESSAGE" \
    -d "parse_mode=Markdown" > /dev/null
