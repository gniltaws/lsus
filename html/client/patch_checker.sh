#!/bin/bash

# generated installation key and server URI from install
auth_key="__SERVER_AUTHKEY_SET_ME__"
server_uri="__SERVER_URI_SET_ME__"
submit_patch_uri="${server_uri}client/send_patches.php"
# set client_path
if [[ -d /opt/patch_client ]]; then
        client_path="/opt/patch_client/"
else
        client_path="/opt/patch_manager/"
fi
# if $client_path does not exist
if [[ ! -f "${client_path}.patchrc" ]]; then
	echo "Please run ${client_path}check-in.sh as root (sudo) before trying to run this manually"
	exit 0
fi
# load the file
. ${client_path}.patchrc
rm -rf /tmp/patch_$client_key > /dev/null 2>&1
if [[ -f /etc/lsb-release && -f /etc/debian_version ]]; then
        os=$(lsb_release -s -d|head -1|awk {'print $1'})
elif [[ -f /etc/debian_version ]]; then
        os="$(cat /etc/issue|head -n 1|awk {'print $1'})"
elif [[ -f /etc/oracle-release ]]; then
		os="Oracle"
elif [[ -f /etc/redhat-release ]]; then
        os=$(cat /etc/redhat-release|head -1|awk {'print $1'})
        if [[ "$os" = "Red" && $(grep -i enterprise /etc/redhat-release) != "" ]]; then
                os="RHEL"
        elif [[ "$os" = "Red" ]]; then
                os="RHEL"
        fi
else
	os=$(uname -s -r|head -1|awk {'print $1'})
fi
# remove any special characters
os=$(echo $os|sed -e 's/[^a-zA-Z0-9]//g')
# begin update checks
if [[ "$os" = "Oracle" ]]; then
	need_patched="true"

	osver=`awk '{print $5}' /etc/oracle-release`

	updateinfo="/tmp/updateinfo.txt"
	checkupdate="/tmp/check-update.txt"
	severityfile="/tmp/severity_sorted.txt"

	baseurl="https://linux.oracle.com/errata/"

	#Get list of all updates with severity
    #first command is OL6 compatible, second uncommented command is OL5 & OL6 compatible
	#yum updateinfo list | awk '$1 ~/EL/ {print}' > $updateinfo
	yum list-security | awk '$1 ~/EL/ {print}' > $updateinfo

	#Sort the list by severity
    ## OL5 still uses up2date primarily and an old version of yum.
    ## Consequently, it doesn't get into granularity of security updates.
	grep 'security' $updateinfo | sort -r > $severityfile
	grep 'Critical/Sec.' $updateinfo | sort -r | sed 's:Critical/Sec.:Critical:g' >> $severityfile
	grep 'Important/Sec.' $updateinfo | sort -r | sed 's:Important/Sec.:Important:g' >> $severityfile
	grep 'Moderate/Sec.' $updateinfo | sort -r | sed 's:Moderate/Sec.:Moderate:g' >> $severityfile
	grep 'Low/Sec.' $updateinfo | sort -r | sed 's:Low/Sec.:Low:g' >> $severityfile
	grep 'bugfix' $updateinfo | sort -r >> $severityfile
	grep 'enhancement' $updateinfo | sort -r >> $severityfile

	#Gets the list of the latest updates
	yum -q check-update | awk '$3 ~/^o|el/ {print}' > $checkupdate

	while read line
	do
		pkg=`echo $line | awk -F. '{print $1}'`
		instver=`rpm -q $pkg --qf '%{VERSION}-%{RELEASE}'`

		oldIFS=$IFS
		IFS=$(echo -en "\n\b")

  		for updateline in `grep " $pkg-[0-9]" $severityfile`
		do
			updver=`echo $updateline | awk '{print $3}' | sed "s/$pkg-//g" | awk -F. 'sub(FS $NF,x)'`
			severity=`echo $updateline | awk '{print $2}'`
			advisory=`echo $updateline | awk '{print $1}'`

			echo "$pkg:::$instver:::$updver:::$os:::$osver:::$severity:::$baseurl$advisory" >> /tmp/patch_$client_key
		done
  		IFS=$oldIFS
	done < $checkupdate

	#Clean up text files
	rm -rf $updateinfo $checkupdate $severityfile
elif [[ "$os" = "CentOS" ]] || [[ "$os" = "Fedora" ]] || [[ "$os" = "RHEL" ]]; then
	need_patched="true"
        yum -q check-update| while read i
        do
                i=$(echo $i) #this strips off yum's irritating use of whitespace
                if [[ "${i}x" != "x" ]]
                then
                        UVERSION=${i#*\ }
                        UVERSION=${UVERSION%\ *}
                        PNAME=${i%%\ *}
                        PNAME=${PNAME%.*}
                        #echo $(rpm -q "${PNAME}" --qf '%{NAME}:::%{VERSION}:::')${UVERSION}
                        patches_to_install=$(echo $(rpm -q "${PNAME}" --qf '%{NAME}:::%{VERSION}-%{RELEASE}:::')${UVERSION})
                        echo "$patches_to_install" >> /tmp/patch_$client_key
                fi
        done
elif [[ "$os" = "Ubuntu" ]] || [[ "$os" = "Debian" ]]; then
        need_patched="true"
        #apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1:::$2:::$3\n"}'
		apt-get -qq update
        patches_to_install=$(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1:::$2:::$3\n"}')
	extrainfo=$(lsb_release -s -d | awk '{gsub( "[\(\)]","" ); print ":::"$1":::"$4}')
	echo "$patches_to_install" >> /tmp/patch_$client_key
	sed -i 's/$/'$extrainfo'/g' /tmp/patch_$client_key
elif [[ "$os" = "Linux" ]]; then
        echo "unspecified $os not supported"
        exit 0
fi
if [[ "$need_patched" == "true" ]] && [ -f /tmp/patch_$client_key ] ; then
        patch_list=$(cat /tmp/patch_$client_key)
        curl -L -s -H "X-CLIENT-KEY: $client_key" $submit_patch_uri -d "$patch_list"
        rm -rf /tmp/patch_$client_key > /dev/null 2>&1
fi

