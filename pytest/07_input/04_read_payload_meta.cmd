curl -s -H "Authorization: Bearer $USER_TOKEN" $GW_HOST/object/$BC_OBJECT_ID/read/meta | jq -e '."dlt-response"' > /dev/null && echo "yes" || echo "no"