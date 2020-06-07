# Dropbox Autostart on Ubuntu 20.04 LTS

Will need `sudo`:

    # cat <<EOF > /usr/lib/systemd/user/dropbox.service
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


Reload systemd files

    # systemctl --user daemon-reload

Check if new service is there:

    # systemctl --user list-unit-files -t service | grep dropbox
    dropbox.service                     disabled  enabled

Enable and start service:

    # systemctl --user enable dropbox
    Created symlink /home/rosstimson/.config/systemd/user/multi-user.target.wants/dropbox.service → /usr/lib/systemd/user/dropbox.service.

    # systemctl --user start dropbox

Check all is well:

    # systemctl --user status dropbox
    ● dropbox.service - Dropbox file sync service
         Loaded: loaded (/usr/lib/systemd/user/dropbox.service; enabled; vendor preset: enabled)
         Active: active (running) since Sun 2020-05-17 15:10:31 BST; 7s ago
        Process: 70518 ExecStart=/usr/bin/dropbox start (code=exited, status=0/SUCCESS)
       Main PID: 70519 (dropbox)
         CGroup: /user.slice/user-1000.slice/user@1000.service/dropbox.service
                 └─70519 /home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/dropbox

    May 17 15:10:30 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/tornado.speedups.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/wrapt._wrappers.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/PyQt5.QtWidgets.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/PyQt5.QtCore.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/PyQt5.QtGui.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/PyQt5.QtNetwork.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70519]: dropbox: load fq extension '/home/rosstimson/.dropbox-dist/dropbox-lnx.x86_64-97.4.467/PyQt5.QtDBus.cpython-37m-x86_64-linux-gnu.so'
    May 17 15:10:31 REM-RT-29641 dropbox[70518]: Dropbox isn't running!
    May 17 15:10:31 REM-RT-29641 dropbox[70518]: Done!
    May 17 15:10:31 REM-RT-29641 systemd[1284]: Started Dropbox file sync service.

    # dropbox status
    Up to date
