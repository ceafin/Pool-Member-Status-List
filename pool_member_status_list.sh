#!/bin/bash

# Create the new external data group file
# tmsh create /sys file data-group <nameOfExtDataGroupFile> source-path file:<linuxDirectPathToDataFile> type string
# tmsh create /sys file data-group pool_member_status_list source-path file:/var/tmp/pool_member_status_list.class type string

# Create the external data group reference to the file
# tmsh create /ltm data-group external <labelForExtDataGroup> external-file-name <nameOfExtDataGroupFile>
# tmsh create /ltm data-group external pool_member_status_list external-file-name file:/var/tmp/pool_member_status_list.class

# Send syslog for script initializing
logger -p local3.notice -t POOLMEMBERSTATUS "Initializing..."

# Check for class file to exist, if not were the initial creation and reference steps taken?
if [ ! -e /var/tmp/pool_member_status_list.class ]
then
	logger -p local3.notice -t POOLMEMBERSTATUS "Data-group class file does not pre-exist. Touching /var/tmp/pool_member_status_list.class"
	touch /var/tmp/pool_member_status_list.class
	echo "1" > /var/tmp/pool_member_status_list.class
	logger -p local3.notice -t POOLMEMBERSTATUS "Creating and associating data-group and external-file link through TMSH."
	tmsh create /sys file data-group pool_member_status_list source-path file:/var/tmp/pool_member_status_list.class type string >> pool_member_status_list.log 2>&1
	tmsh create /ltm data-group external pool_member_status_list external-file-name file:/var/tmp/pool_member_status_list.class >> pool_member_status_list.log 2>&1
fi

# Clean up old pool member list build if still hanging around
rm -f /var/tmp/pool_member_status_list.build

# Build pool member list file
nodeList=`tmsh show ltm pool detail field-fmt | grep "ltm pool" | sed -n 's/ltm pool \(\S*\) {/\1/p'`
for i in $nodeList; do
        # $i == list of pools by name
        # memberList=`tmsh show ltm pool $i members detail field-fmt | grep : | sed 's/ //;s/{//p'`
		memberPort=`tmsh show ltm pool $i members detail field-fmt | grep -m1 : | sed -n 's/\S*:\(\S*\) {/\1/p' | awk '{print $1}'`
		memberList=`tmsh show ltm pool $i members detail field-fmt | grep "addr" | awk '/addr /{print $2}'`
        for n in $memberList; do
                # $n == list of members in given pool name by $i
                echo -e "\"$i/$n\:$memberPort\"," >> /var/tmp/pool_member_status_list.build       # Write data pairs to file
        done
done

# Check for any changes to the 
if cmp -s /var/tmp/pool_member_status_list.class /var/tmp/pool_member_status_list.build >/dev/null
then	# Same
	rm -f /var/tmp/pool_member_status_list.build 	# Remove pool member list build before leaving
	logger -p local3.notice -t POOLMEMBERSTATUS "No new members detected. No action taken."
else	# Different
	rm -f /var/tmp/pool_member_status_list.class 	# Remove previous pool member list file
	cp -f /var/tmp/pool_member_status_list.build /var/tmp/pool_member_status_list.class 	# Copy pool list build to external data group class target
	logger -p local3.notice -t POOLMEMBERSTATUS "New pool members found. Modifying /sys file data-group"
	# Modify the existing data-group in the F5 to the updated information.
	# tmsh modify /sys file data-group <nameOfExtDataGroupFile> source-path file:<linuxDirectPathToDataFile>
	tmsh modify /sys file data-group pool_member_status_list source-path file:/var/tmp/pool_member_status_list.class
fi

# Send syslog for script initializing
logger -p local3.notice -t POOLMEMBERSTATUS "Complete!"

exit 0
