#
# Regular cron jobs for the lmt-gui package
#
0 4	* * *	root	[ -x /usr/bin/lmt-gui_maintenance ] && /usr/bin/lmt-gui_maintenance
