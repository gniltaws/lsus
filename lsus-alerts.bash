#!/bin/bash
# Written by Todd Swatling todd.swatling@gmail.com
# This script notifies LSUS users of available updates.
# It is probably best to run this just after your servers check in with their patch lists.  Put this in cron:
#* 6,14 * * * /root/lsus-alerts.bash 2>&1 /dev/null


## Set variables
lsuspath='/var/www/patch_manager'
tmpfile='/root/alert.tmp'

url=`awk -F'=' '$1 ~/server_uri/ {print $2}' $lsuspath/client/package_checker.sh | tr -d '"'`
dbname=`awk -F "\'" '$2 ~/DB_NAME/ {print $4}' $lsuspath/lib/db_config.php`
dbuser=`awk -F "\'" '$2 ~/DB_USER/ {print $4}' $lsuspath/lib/db_config.php`
dbpass=`awk -F "\'" '$2 ~/DB_PASS/ {print $4}' $lsuspath/lib/db_config.php`

## Generate body of email
echo "For more info see <a href=$url>$url</a><br><br>" > $tmpfile
mysql -u $dbname -p$dbpass --html -e "USE $dbname;
SELECT urgency AS 'Patch Urgency', COUNT(*) AS 'Count'
  FROM patches
  GROUP BY urgency
  ORDER BY FIELD(urgency,'Critical','high','Important','Moderate','medium','Low','low','bugfix','enhancement');

SELECT COUNT(needs_restart) AS 'Servers needing Service/OS restart'
  FROM servers
  WHERE trusted = 1 AND needs_restart > 0;

SELECT server_name AS 'Servers with errors detecting if they need restarting'
  FROM servers
  WHERE trusted = 1 AND needs_restart < 0;

SELECT package_name AS 'Supressed Packages', server_name AS 'Server'
  FROM supressed
  ORDER BY server_name;
" >> $tmpfile

## Get email addresses
emails=`mysql -N -u $dbname -p$dbpass -e "USE $dbname; SELECT DISTINCT(email) FROM users WHERE receive_alerts = 1;" | paste -s -d " "`

## Insert a blank line between the tables and send it out.
## Your server must me configured to properly send mail with something like sendmail or exim.
sed 's/TABLE><TABLE/TABLE><BR><TABLE/' $tmpfile | mail -a "MIME-Version: 1.0" -a "Content-Type: text/html" -s "LSUS" $emails
