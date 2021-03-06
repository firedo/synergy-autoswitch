# synergy-autoswitch

Synergy ([symless.com](https://symless.com/synergy)) for Linux version 1.X Autoswitcher (between client and server mode) &amp; start at login window (GDM3 greeter)

NOTE: This script simply checks if remote Synergy server responds and connects to that server. It falls back to 2nd server and as a last resort creates it's own server. It does not work like the Synergy version 2 where keyboard activity causes switching between computers.

I'm sharing my Bash script and autostart desktop files for starting Synergy version 1.x in client/server mode (using autoswitch and loop). Includes a short guide to enable Synergy @ Ubuntu 18.04 login window (GDM3 greeter).

I originally made this script for my IOMMU/VFIO Windows 10 Gaming virtual machine running under Linux host. The Win 10 VM switches also between client/server, but [based on if a specific USB device (keyboard) is present or not.](https://github.com/firedo/synergy-windows-switch-usb) I sometimes also like to switch my laptop as a server to control my Linux host.

Quick Install guide:

1. `git clone https://github.com/firedo/synergy-autoswitch.git`
1. `cd synergy-autoswitch`
1. `cp synergy-autoswitch.desktop /usr/share/gdm/greeter/autostart/synergy-autoswitch.gdm.desktop` (edit the "Exec=" to point to the 'synergy-autoswitch' script)
1. (optional, for GDM greeter) `sudo cp synergy-autoswitch.gdm.desktop /usr/share/gdm/greeter/autostart/synergy-autoswitch.gdm.desktop` (edit the "Exec=" to point to the 'synergy-autoswitch' script)
1. `chmod a+rx synergy-autoswitch functions.sh settings.sh` # Add read and execute permission for all users (incl. the greeter user)
1. `cp settings.sh.example settings.sh`
1. Modify 'settings.sh' to your liking (for ex. leave SynergyClientX variables empty to enable starting Server only)


Copy/Update Synergy server config from the current user to the GDM greeter user (optional) 
============================================================================

* '/var/lib/gdm3' is the default home folder in Ubuntu 18.04 for GDM greeter's user ('gdm'). Use the script's 'debug' argument in the 'synergy-autoswitch.gdm.desktop' file to find out the correct home folder (requires reboot or `systemctl restart gdm`).

1. Open Synergy GUI => File => Save configuration as... => Save to `~/.config/Synergy/synergy-server.conf`
1. `sudo cp -R ~/.synergy /var/lib/gdm3` # Copy SSL (trusted servers & server's private key) files from the current user
1. `sudo -u gdm mkdir -p /var/lib/gdm3/.config/Synergy` # Create path
1. `sudo cp ~/.config/Synergy/synergy-server.conf /var/lib/gdm3/.config/Synergy` # Copy Synergy config from the current user
1. `sudo chown -R gdm:gdm /var/lib/gdm3/.config /var/lib/gdm3/.synergy` # Change file owners

NOTE: The script causes "client connected/disconnected" messages in the remote Synergy server's log every 10-30 seconds.

Feel free to use, edit & share these files. Pull requests for bugs or extra features are also welcome (sharing is caring).

No support provided for these scripts nor Synergy by me. Please use Google or learn basics of Linux/bash.

I'm not affiliated in anyway with Synergy or Symless. I just use their software.
