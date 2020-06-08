# Dropbox Autostart on Ubuntu 20.04 LTS

The Dropbox tool has a `dropbox autostart` command that claims to
automatically start the Dropbox service at login, it doesn't work for
me[^autostart] so this is how to achieve the same aim with Systemd.

_As an aside, I highly recommend you check out
[Syncthing](https://syncthing.net) as a lightweight self--hosted
Dropbox alternative if you are not tied to Dropbox for some reason._

Create a new Systemd user service, note that this will need `sudo`:

    $ cat <<EOF > /usr/lib/systemd/user/dropbox.service
    [Unit]
    Description=Dropbox file sync service
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/bin/dropbox start
    ExecStop=/usr/bin/dropbox stop

    [Install]
    WantedBy=multi-user.target
    EOF

Reload Systemd files:

    $ systemctl --user daemon-reload

Check if the new service is there:

    $ systemctl --user list-unit-files -t service | grep dropbox
    dropbox.service                     disabled  enabled

Enable and start the new service:

    $ systemctl --user enable dropbox
    Created symlink /home/rosstimson/.config/systemd/user/multi-user.target.wants/dropbox.service → /usr/lib/systemd/user/dropbox.service.

    $ systemctl --user start dropbox

Check all is well:

    systemctl --user status dropbox
    ● dropbox.service - Dropbox file sync service
         Loaded: loaded (/usr/lib/systemd/user/dropbox.service; enabled; vendor preset: enabled)
         Active: active (running) since Mon 2020-06-08 19:35:03 BST; 1h 50min ago
        Process: 1821571 ExecStart=/usr/bin/dropbox start (code=exited, status=0/SUCCESS)
       Main PID: 1821572 (dropbox)
         CGroup: /user.slice/user-1000.slice/user@1000.service/dropbox.service
                 └─1821572 /home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-98.4.158/dropbox

    Jun 08 19:35:02 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:02 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821572]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-l>
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821571]: Dropbox isn't running!
    Jun 08 19:35:03 REM-RT-29641 dropbox[1821571]: Done!
    Jun 08 19:35:03 REM-RT-29641 systemd[1780]: Started Dropbox file sync service.

    $ dropbox status
    Up to date

## Footnotes

[^autostart]:
    Maybe the built-in `autostart` works for the default GNOME desktop
    environment but I run a more minimal setup.
