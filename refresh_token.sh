curl -X POST https://id.twitch.tv/oauth2/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=refresh_token&refresh_token=$OLAB0T_REFRESH_TOKEN&client_id=$OLAB0T_CLIENT_ID&client_secret=$OLAB0T_CLIENT_SECRET" | python3 -c "import os, sys, json; payload=json.load(sys.stdin); print('export OLAB0T_USER_ACCESS_TOKEN={}\nexport OLAB0T_REFRESH_TOKEN={}\nexport OLAB0T_CLIENT_SECRET={}'.format(payload.get('access_token'), payload.get('refresh_token'), os.getenv('OLAB0T_CLIENT_SECRET')))" > .env
source .env
