# runbackup workflow

#POST RUN BACKUP

F_CLI_MAC=$(format_mac ${CLI_MAC} ":")
CLI_KERNEL_FILE=$(ls ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/*kernel | xargs -n 1 basename)
CLI_INITRD_FILE=$(ls ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/*initrd* | xargs -n 1 basename)
CLI_REAR_PXE_FILE=$(grep -w append ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/rear* | awk -F':' '{print $1}' | xargs -n 1 basename)
CLI_KERNEL_OPTS=$(grep -h -w append ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_REAR_PXE_FILE} | awk '{print substr($0, index($0,$3))}' | sed 's/vga/gfxpayload=vga/')

Log "$PROGRAM:$WORKFLOW:postbackup:${CLI_NAME}: Fixing PXE permissions for DR image ..."

if [ $(stat -c %a ${STORDIR}/${CLI_NAME}/${CLI_CFG}) != "755" ]; then
  chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}
  if [ $? -ne 0 ]; then
    Error "chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG} failed!"
  fi
fi

if [ $(stat -c %a ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE) != "755" ]; then
  chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE
  if [ $? -ne 0 ]; then
    Error "chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE failed!"
  fi
fi

if [ $(stat -c %a ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_KERNEL_FILE}) != "755" ]; then
  chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_KERNEL_FILE}
  if [ $? -ne 0 ]; then
    Error "chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_KERNEL_FILE} failed!"
  fi
fi

if [ $(stat -c %a ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_INITRD_FILE}) != "755" ]; then
  chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_INITRD_FILE}
  if [ $? -ne 0 ]; then
    Error "chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_INITRD_FILE} failed!"
  fi
fi

if [ $(stat -c %a ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_REAR_PXE_FILE}) != "755" ]; then
  chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_REAR_PXE_FILE}
  if [ $? -ne 0 ]; then
    Log "WARNING:$PROGRAM:$WORKFLOW: chmod 755 ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_REAR_PXE_FILE} failed!"
  fi
fi

Log "$PROGRAM:$WORKFLOW:postbackup:${CLI_NAME}: Fixing PXE permissions for DR image ... Success!"

Log "$PROGRAM:$WORKFLOW:postbackup:${CLI_NAME}: Enabling DRLM Store ..."

if do_remount ro $LOOP_DEVICE $CLI_NAME $CLI_CFG; then
  Log "$PROGRAM:$WORKFLOW:postbackup:FS:MOUNT:LOOPDEV(${CLI_ID}):MNT($STORDIR/$CLI_NAME): ... Success!"
  if enable_nfs_fs_ro $CLI_NAME $CLI_CFG; then
    Log "$PROGRAM:$WORKFLOW:postbackup:NFS:ENABLE(ro):$CLI_NAME: ... Success!"
  else
    report_error "ERROR:$PROGRAM:$WORKFLOW:postbackup:NFS:ENABLE (ro):$CLI_NAME: Problem enabling NFS export (ro)! aborting ..."
    Error "$PROGRAM:$WORKFLOW:postbackup:NFS:ENABLE (ro):$CLI_NAME: Problem enabling NFS export (ro)! aborting ..."
  fi
else
  report_error "ERROR:$PROGRAM:$WORKFLOW:postbackup:FS:MOUNT:LOOPDEV(${CLI_ID}):MNT(${STORDIR}/${CLI_NAME}): Problem mounting Filesystem!"
  Error "$PROGRAM:$WORKFLOW:postbackup:FS:MOUNT:LOOPDEV(${CLI_ID}):MNT(${STORDIR}/${CLI_NAME}): Problem mounting Filesystem!"
fi

Log "$PROGRAM:$WORKFLOW:postbackup:${CLI_NAME}: Enabling DRLM Store .... Success!"

if [[ ! -d ${STORDIR}/boot/cfg ]]; then mkdir -p ${STORDIR}/boot/cfg; fi

Log "$PROGRAM:$WORKFLOW:postbackup:PXE:${CLI_NAME}: Creating MAC Address (GRUB2) boot configuration file ..."

cat << EOF > ${STORDIR}/boot/cfg/${F_CLI_MAC}
       
  echo "Loading Linux kernel ..."
  linux (tftp)/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_KERNEL_FILE} ${CLI_KERNEL_OPTS}
  echo "Loading Linux Initrd image ..."
  initrd (tftp)/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_INITRD_FILE}

EOF

if [ -f ${STORDIR}/boot/cfg/${F_CLI_MAC} ]; then
  Log "$PROGRAM:$WORKFLOW:postbackup:PXE:${CLI_NAME}:Creating MAC Address (GRUB2) boot configuration file ... Success!"
else
  report_error "ERROR:$PROGRAM:$WORKFLOW:postbackup:PXE:${CLI_NAME}: Problem Creating MAC Address (GRUB2) boot configuration file! aborting ..."
  Error "$PROGRAM:$WORKFLOW:postbackup:PXE:${CLI_NAME}: Problem Creating MAC Address (GRUB2) boot configuration file! aborting ..."
fi
