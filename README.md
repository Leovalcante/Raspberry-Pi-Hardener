# Raspberry-Pi-Hardener

Remove useless software from Raspberry Pi and go headless

Raspberry Pi Hardner is a collection of useful resources found on the web.
The goal is to remove anything useless for a headless installation, hence reducing a possible attack surface.

These are the resources used to implement this script:

- https://github.com/dumbo25/unsed_rpi/ - Useless programs; fail2ban and ufw
- https://plone.lucidsolutions.co.nz/hardware/raspberry-pi/3/disable-unwanted-raspbian-services - Useless services
- https://gist.github.com/semicolonsnet/10a64241079787cdbbacc0ea7144d924 - Useless program and services

## !!! DISCLAIMER !!!

You can launch the script as is to remove any unwanted programs and disable the desktop environment. Otherwise, you can comment the actions you don't want to perform in the `main` function. At the moment the functions are:

- `removeBloatware`: removes default extra installed software
- `disableServices`: disables services like Bluetooth and other not useful for a headless environment
- `removeDesktopEnvironment`: removes the actual desktop environment
- `installSecurity`: installs and configures `ufw` and `fail2ban`

## Contributions

If you have any ideas, advice, or improvement, feel free to open an issue. Pull requests are welcome!
