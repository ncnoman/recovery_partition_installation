#!/bin/sh
#############################################
######## recovery partition creator #########
#############################################

#check working directory
RUNNING_DIR="$(pwd)"
if [[ "$RUNNING_DIR" != *"recovery_partition_installation" ]]; then
  echo
  echo " The current working directory is $RUNNING_DIR"
  echo
  echo ' cd to /Volumes/<volume containing this script>/recovery_partition_installation'
  echo
  echo " and run this script from its directory."
  echo
  exit
fi

#identify target disk (bless --info --getBoot) parameters needed for dm tool
BOOT_DISK="$(bless --info --getBoot | awk -F / '{print $3}')"
#the below BOOT_DISK defintion probably only doesn't work on encrypted volumes, but, the above BOOT_DISK definition is simpler, and works with diskutil, df,  and dm nonetheless too.
#preserving it here if this can later be determined and is useful.
#The difference is the above definition is based on /dev/<device> i.e. disk0s2, the below definition is the name of the volume. i.e. "Mac OS"

#BOOT_DISK=$(diskutil info "$(bless --info --getBoot)" | awk -F':' '/Volume Name/ { print $2 }' | sed -e 's/^[[:space:]]*//')

#if more can be determined about what causes diskutil to display "Not applicable" for Volume Name and filesystem Type, this script could be shortened,
#  because the if [ "$CORRECT" != "y" ] confirming the disk to be partitioned with the user and the if [ "$FS_TYPE" == '' ] cases could be skipped.
# (the FS_TYPE definition's use of diskutil can't be avoided since dm must be ran with different syntax depending on the file system.)
#however, its believed to be encryption that causes the unexpected diskutil output, something that should (hopefully) is out of scope for the use case for this script.

FS_TYPE=$(diskutil info "$BOOT_DISK" | awk '$1 == "Type" { print $NF }')
if [ "$FS_TYPE" == '' ]; then
  echo " The file system type could not be determined. The target disk is most likely encrypted."
  echo
  sleep 2
  echo " This script is designed for use on unencrypted volumes, one purpose being to enable FileVault encryption, which requires the Recovery HD partition."
  echo
  sleep 2
  echo " You will be prompted for entering the file system type manually, BUT IT IS UNKNOWN IF THE dm TOOL CAN RUN ON AN ENCRYPTED VOLUME."
  echo " The script will attempt to run as if the boot volume is formatted as hfs+, but success is not gauranteed, nor is it gauranteed to be non-destructive."
  echo " Proceed at your own risk."
  echo " Press Ctrl-C at any time to quit."
  echo
  sleep 5
  read -p " If you wish to continue, press any key."
fi

#check that the target disk BOOT_DISK is not what is currently booted up and mounted at /
BD_MOUNT_POINT="$(df | grep "$BOOT_DISK" | awk '{print $9}')"
if [ "$BD_MOUNT_POINT" == "/" ]; then
  echo
  echo " ********************************************************************************************************************************"
  echo " recovery_install.sh must be ran from a boot volume other than the target boot volume."
  echo
  sleep 2
  echo " Reboot, then press and hold CMD+R while booting, holding the keys until a globe appears, to boot into Internet Recovery."
  echo " * requires an internet connection"
  echo " * wifi requires knowing your wifi password"
  echo " * Alternatively, if another bootable volume is available, and there is no internet available, press and Hold ALT to boot into it"
  echo
  sleep 5
  echo " Once rebooted into Internet Recovery mode, run this script in its Terminal."
  echo " ********************************************************************************************************************************"
  echo
  sleep 1
  exit
fi

echo " Target disk:"
echo
diskutil list $BOOT_DISK
echo
sleep 5
read -p " Is this the correct disk to install the Recovery HD partition? (y/n) " CORRECT
echo
if [ "$CORRECT" != "y" ]; then
  echo " Try running the script's toolset manually instead."
  echo
  echo " - for apfs file systems:"
  echo '<path_to_script>/tools/dm ensureRecoveryBooter "<target disk name>" -base "<path_to_script>/resources/BaseSystem.dmg" "<path_to_script>/resources/BaseSystem.chunklist" -diag "<path_to_script>/resources/AppleDiagnostics.dmg" "<path_to_script>/resources/AppleDiagnostics.chunklist" -diagmachineblacklist 0 -installbootfromtarget 0 -slurpappleboot 0 -delappleboot 0 -addkernelcoredump 0'
  echo
  echo " - for non-apfs (hfs+) file systems:"
  echo '<path_to_script>/tools/dm ensureRecoveryPartition "<target disk name>" <path_to_script>/resources/BaseSystem.dmg <path_to_script>/resources/BaseSystem.chunklist <path_to_script>/resources/AppleDiagnostics.dmg <path_to_script>/resources/AppleDiagnostics.chunklist 0 0 0'
  echo
  exit
fi

#determine compatible version from .info file's filename.
INFO_FILE="$(ls $RUNNING_DIR/resources/ | grep -E \.info)"
PACKAGE_VERSION="$( echo $INFO_FILE | awk -F . '{print $1}' | awk -F _ '{print $2}')"
echo " The base system and apple diagnostics files being used are sourced from $PACKAGE_VERSION's installation image."
echo
sleep 3
echo " If $BOOT_DISK has a macOS release other than $PACKAGE_VERSION installed, follow the instructions in $RUNNING_DIR/resources/$INFO_FILE before continuing."
echo
sleep 3

#give user a chance to quit.
read -p " Press any key to continue. Ctrl-C to exit."
echo
sleep 3

#run dm tool based on syntax per filesystem type
if [[ "${FS_TYPE}" == "apfs" ]]; then
	echo "Running ensureRecoveryBooter for APFS target volume $BOOT_DISK"
	$RUNNING_DIR/tools/dm ensureRecoveryBooter "$BOOT_DISK" -base "$RUNNING_DIR/resources/BaseSystem.dmg" "$RUNNING_DIR/resources/BaseSystem.chunklist" -diag "$RUNNING_DIR/resources/AppleDiagnostics.dmg" "$RUNNING_DIR/resources/AppleDiagnostics.chunklist" -diagmachineblacklist 0 -installbootfromtarget 0 -slurpappleboot 0 -delappleboot 0 -addkernelcoredump 0
  SUCCESS=$?
else
	echo "Running ensureRecoveryPartition for Non-APFS target volume $BOOT_DISK"
	$RUNNING_DIR/tools/dm ensureRecoveryPartition "$BOOT_DISK" $RUNNING_DIR/resources/BaseSystem.dmg $RUNNING_DIR/resources/BaseSystem.chunklist $RUNNING_DIR/resources/AppleDiagnostics.dmg $RUNNING_DIR/resources/AppleDiagnostics.chunklist 0 0 0
  SUCCESS=$?
fi

#success prompt
if [ "$SUCCESS" == "0" ]; then
  echo " Finished creating Recovery HD partition."
  echo
  diskutil list "$BOOT_DISK"
  echo
  read -p " Press any key to reboot back into Mac OS. Ctrl-C to exit."
  reboot
fi

#error prompt
if [ "$SUCCESS" != "0" ]; then
  echo " Error encountered."
  echo
  echo " Manually attempt to run the dm tool to create the recovery partition."
  echo
  sleep 2
  diskutil list
  echo
  sleep 5
  echo " - for apfs file systems:"
  echo '<path_to_script>/tools/dm ensureRecoveryBooter "<target disk name>" -base "<path_to_script>/resources/BaseSystem.dmg" "<path_to_script>/resources/BaseSystem.chunklist" -diag "<path_to_script>/resources/AppleDiagnostics.dmg" "<path_to_script>/resources/AppleDiagnostics.chunklist" -diagmachineblacklist 0 -installbootfromtarget 0 -slurpappleboot 0 -delappleboot 0 -addkernelcoredump 0'
  echo
  echo " - for non-apfs (hfs+) file systems:"
  echo '<path_to_script>/tools/dm ensureRecoveryPartition "<target disk name>" <path_to_script>/resources/BaseSystem.dmg <path_to_script>/resources/BaseSystem.chunklist <path_to_script>/resources/AppleDiagnostics.dmg <path_to_script>/resources/AppleDiagnostics.chunklist 0 0 0'
  echo
fi
