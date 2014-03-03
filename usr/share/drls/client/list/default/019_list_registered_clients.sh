Log "####################################################"
Log "# List of clients : 	                         "
Log "####################################################"
if exist_client_name "$CLI_NAME" 
then
	CLI_ID=`get_client_id_by_name $CLI_NAME`
	CLI_MAC=`get_client_mac $CLI_ID`
	CLI_IP=`get_client_ip $CLI_ID`
	CLI_OS=""
	CLI_NET=`get_client_net $CLI_ID`
	clear
	client_list_tittle CLI
	printf '%25s %-25s %-25s %-25s %-25s %-25s %-25s\n' "" "$CLI_ID" "$CLI_NAME" "$CLI_MAC" "$CLI_IP" "$CLI_OS" "$CLI_NET"
else
	clear
	printf '%25s\n' "$(tput bold)$CLI_NAME$(tput sgr0) not found in database!!"
fi
if [ "$CLI_NAME" == "all" ]
then
	list_clients CLI
fi
