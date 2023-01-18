#!/bin/sh

# sudo /etc/init.d/ssh restart
/etc/NX/nxserver --startup

# start logging (essential to run the server, even in detached mode)
sudo tail -f /usr/NX/var/log/nxserver.log
sudo tail -f /tmp/nxserver.log

