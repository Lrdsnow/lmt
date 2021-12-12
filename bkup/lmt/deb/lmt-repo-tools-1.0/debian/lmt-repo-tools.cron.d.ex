#
# Regular cron jobs for the lmt-repo-tools package
#
0 4	* * *	root	[ -x /usr/bin/lmt-repo-tools_maintenance ] && /usr/bin/lmt-repo-tools_maintenance
