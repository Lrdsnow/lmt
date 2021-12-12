#
# Regular cron jobs for the lmt package
#
0 4	* * *	root	[ -x /usr/bin/lmt_maintenance ] && /usr/bin/lmt_maintenance
