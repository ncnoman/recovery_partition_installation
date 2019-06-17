# recovery_partition_installation
Creates missing Recovery HD partition needed to enable FileVault. Works with Mojave.

Requirements:

Must download and extract the required dm tool and place in the tools/ directory, and the BaseSystem and AppleDiagnostics files and place in the resources/ directory.

Must run ./recovery_install.sh booted into something other than the disk the Recovery HD will be installed on. 
* press and hold CMD+R while booting to use Apple's Internet Recovery mode. (requires WiFi or LAN with internet)
* press and hold ALT while booting to boot into another available boot disk. (requires another available boot disk)
