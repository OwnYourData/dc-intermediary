curl -s -H "Authorization: Bearer $USER_TOKEN" $GW_HOST/collection/`curl -s -H "Authorization: Bearer $USER_TOKEN" $GW_HOST/collection/list | jq '.[0]."collection-id"'` | jq 'has("collection-id")'