# runbackup workflow

# Available VARs
# ==============
# CLI_ID (Client Id) 
# CLI_NAME (Client Name)
# CLI_CFG (Client Configuration. If not set = "default"

# Check if the target client for backup is in DRLM client database
if exist_client_name "$CLI_NAME"; then
  CLI_ID=$(get_client_id_by_name $CLI_NAME)
  CLI_MAC=$(get_client_mac $CLI_ID)
  CLI_IP=$(get_client_ip $CLI_ID)
  Log "Client $CLI_ID - $CLI_NAME found in database"
else
  Error "Client $CLI_NAME not found"
fi

# Check if client SSH Server is available over the network
if check_ssh_port "$CLI_IP"; then
  Log "Client $CLI_NAME SSH Server on $SSH_PORT port is available!"
else
  Error "Client $CLI_NAME SSH Server on $SSH_PORT port is not available"
fi

# Update OS version and Rear Version to the database
CLI_DISTO=$(ssh_get_distro $DRLM_USER $CLI_NAME)
CLI_RELEASE=$(ssh_get_release $DRLM_USER $CLI_NAME)

if mod_client_os "$CLI_ID" "$CLI_DISTO $CLI_RELEASE"; then
  Log "Updating OS version $CLI_DISTO $CLI_RELEASE of client $CLI_ID in the database"
else
  LogPrint "Warning: Can not update OS version of client $CLI_ID in the database"
fi

CLI_REAR="$(ssh_get_rear_version $CLI_NAME)"
if mod_client_rear "$CLI_ID" "$CLI_REAR"; then
  Log "Updating ReaR version $CLI_REAR of client $CLI_ID in the database"
else
  LogPrint "Warning: Can not update ReaR version of client $CLI_ID in the database"
fi

# Check what backup rescue type is
if [ "$BACKUP_ONLY_INCLUDE" == "yes" ]; then
  BKP_TYPE=0
  ACTIVE_PXE=0
  LogPrint "Running a Data Only backup"
elif [ "$OUTPUT" == "PXE" ] && [ "$BACKUP_ONLY_INCLUDE" != "yes" ]; then
  BKP_TYPE=1
  ACTIVE_PXE=1
  LogPrint "Running a Recover PXE backup"
elif [ "$OUTPUT" == "ISO" ] && [ "$BACKUP_ONLY_INCLUDE" != "yes" ]; then
  BKP_TYPE=2
  ACTIVE_PXE=0
  LogPrint "Running a Recover ISO backup"
else 
  Error "Backup type not supported OUTPUT != [ PXE | ISO ] and not Data Only Backup"
fi
