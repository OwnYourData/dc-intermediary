curl -s -H "Authorization: Bearer $MASTER_TOKEN" $GW_HOST/organization/ | jq '[type == "array" and length > 1] | any'