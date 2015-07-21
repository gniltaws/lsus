<?php
include '../lib/db_config.php';
$client_key = filter_input(INPUT_SERVER, 'HTTP_X_CLIENT_KEY');
$client_check_sql = "SELECT `id`,`server_name` FROM `servers` WHERE `client_key` = '$client_key' AND `trusted`=1 LIMIT 1;";
$the_url = "";
$urgency = "";
$os = "";
$link = mysql_connect(DB_HOST, DB_USER, DB_PASS);
mysql_select_db(DB_NAME, $link);
$client_check_res = mysql_query($client_check_sql);

function getDebUrgencyandURL($debRelease, $pkgName, $pkgVersion ) {
	$curlopt_url = "https://packages.debian.org/".$debRelease."/".$pkgName;

	//Get the package's webpage in order to get the URL for its changelog
	$curl = curl_init();
	curl_setopt ($curl, CURLOPT_URL, $curlopt_url );
	curl_setopt($curl, CURLOPT_PROXY, "webcache.vassar.edu:3128");
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true);		
	
	$result = curl_exec ($curl);
	curl_close ($curl);

	//Now search the page for the changelog url
	preg_match_all ( '/http.*Debian Changelog/' , $result , $chlogmatches );
	$explodedmatches = explode( '"', $chlogmatches[0][0]);

	$chlogurl = $explodedmatches[0];

	//Using the changelog url from above, get the changelog, and look up the priority of the 
	$curl = curl_init();
	curl_setopt($curl, CURLOPT_URL, $chlogurl );
	curl_setopt($curl, CURLOPT_PROXY, "webcache.vassar.edu:3128");
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true);

	$result = curl_exec ($curl);
	curl_close ($curl);

	//Now search the changelog for the line with the version in question
	$pattern="/.*".preg_quote($pkgVersion).".*urgency=.*/"; 
	preg_match_all ( $pattern , $result , $urgencymatches );

	$explodedurgency = explode( 'urgency=', $urgencymatches[0][0]);
	$explodedsrcpkg = explode( ' ', $urgencymatches[0][0]);
	
	$urgency = $explodedurgency[1];
	$srcpkg = $explodedsrcpkg[0];
	$the_url = "https://security-tracker.debian.org/tracker/source-package/".$srcpkg;
	
	return array ($explodedurgency[1], "https://security-tracker.debian.org/tracker/source-package/".$explodedsrcpkg[0]);
}

if (mysql_num_rows($client_check_res) == 1) {
    $row = mysql_fetch_array($client_check_res);
    $server_name = $row['server_name'];
    $data = file_get_contents("php://input");
    mysql_query("DELETE FROM `patches` WHERE `server_name`='$server_name';");
    $package_array = explode("\n", $data);
    $suppression_sql = "SELECT * from `supressed` WHERE `server_name` IN('$server_name',0);";
    $suppression_res = mysql_query($suppression_sql);
    if (mysql_num_rows($suppression_res) == 0){
        $suppression_array = array("NO_SUPPRESSED_PACKAGES_FOUND");
    }
    else{
        while ($suppression_row = mysql_fetch_assoc($suppression_res)){
            $suppression_array[] = $suppression_row['package_name'];
        }
    }
    foreach ($package_array as $val) {
        $tmp_array = explode(":::", $val);
        $package_name = $tmp_array[0];
        $package_from = $tmp_array[1];
        $package_to = $tmp_array[2];
        
        if ( !empty($tmp_array[3])) {
	        $os = $tmp_array[3];        
        }
        if ( !empty($tmp_array[4])) {
    	    $release = $tmp_array[4];
    	}
        
        //Only Oracle Linux is set up to send these values, so we're checking if they exist first
        if (!empty($tmp_array[5])) {
        	$urgency = $tmp_array[5];
        }
        if (!empty($tmp_array[6])) {
        	$the_url = $tmp_array[6];
        }        
        
        if ( $os == "Ubuntu" ) {
			$bug_curl = shell_exec("bash -c \"curl -s http://www.ubuntuupdates.org/bugs?package_name=$package_name|grep '<td>' 2>/dev/null|head -1\"");
			$url = str_replace("<td><a href='", "", $bug_curl);
			$url_array = explode("'", $url);
			$the_url = $url_array[0];
			$urgency_curl = shell_exec("bash -c \"curl -s http://www.ubuntuupdates.org/package/core/precise/main/updates/$package_name|grep '$package_to'|grep 'urgency='\"");
			if (stristr($urgency_curl, "emergency")) {
				$urgency = "emergency";
			} elseif (stristr($urgency_curl, "high")) {
				$urgency = "high";
			} elseif (stristr($urgency_curl, "medium")) {
				$urgency = "medium";
			} elseif (stristr($urgency_curl, "low")) {
				$urgency = "low";
			} else {
				$urgency = "unknown".$urgency_curl;
			}
		}
		elseif ( $os == "Debian" ) {
			
			$urgandURL = getDebUrgencyandURL($release, $package_name, $package_to);
			$urgency = $urgandURL[0];
			$the_url = $urgandURL[1];
			
			// If the urgency has not been found, try a different release name
			if ( strlen($urgency) < 2 ) {
				$urgandURL = getDebUrgencyandURL($release."-updates", $package_name, $package_to);
				$urgency = $urgandURL[0];
				$the_url = $urgandURL[1];
			}
			
		}
        if (!in_array($package_name, $suppression_array)) {
            $sql = "INSERT INTO patches(server_name,package_name,current,new,urgency,bug_url) VALUES('$server_name','$package_name','$package_from','$package_to','$urgency','$the_url');";
            mysql_query($sql);
        }
    }
}
mysql_close();
