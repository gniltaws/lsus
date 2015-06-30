<?php
/*
 * Fail-safe check. Ensures that they go through the main page (and are authenticated to use this page
 */
if (!isset($index_check) || $index_check != "active"){
    exit();
}
$patch_list_sql = "SELECT count(*) as total_found FROM `patches` p LEFT JOIN servers s on s.server_name = p.server_name WHERE s.trusted = 1 and p.upgraded=0 and p.package_name !='';";
$patch_list_link = mysql_connect(DB_HOST,DB_USER,DB_PASS);
mysql_select_db(DB_NAME,$patch_list_link);
$patch_list_res = mysql_query($patch_list_sql);
$patch_list_row = mysql_fetch_array($patch_list_res);
$patches_to_apply_count = $patch_list_row['total_found'];

//Count number of high urgency security patches
$high_urg_sql = "SELECT server_name, package_name, urgency FROM patches WHERE urgency = 'high' OR urgency = 'Critical' OR urgency = 'Important' OR urgency = 'emergency';";
$high_urg_res = mysql_query($high_urg_sql);
while($row = mysql_fetch_array($high_urg_res)){
	$high_urg_arr_name[] = $row['server_name'];
	$high_urg_arr[] = $row['package_name'];
}
$high_urg_count = $high_urg = $high_urg_pct = 0;
if ( !empty($high_urg_arr_name) && !empty($high_urg_arr) ){
	$high_urg = count(array_unique($high_urg_arr_name));
	$high_urg_count = count($high_urg_arr);
	$high_urg_pct =  ( $high_urg_count / $patches_to_apply_count ) * 100;
}
//Count number of medium urgency security patches
$med_urg_sql = "SELECT server_name, package_name FROM patches WHERE urgency = 'medium' OR urgency = 'Moderate';";
$med_urg_res = mysql_query($med_urg_sql);
while($row = mysql_fetch_array($med_urg_res)){
	$med_urg_arr_name[] = $row['server_name'];
	$med_urg_arr[] = $row['package_name'];
}
$med_urg_count = $med_urg = $med_urg_pct = 0;
if ( !empty($med_urg_arr_name) && !empty($med_urg_arr) ){
	$med_urg = count(array_unique($med_urg_arr_name));
	$med_urg_count = count($med_urg_arr);
	$med_urg_pct = ( $med_urg_count / $patches_to_apply_count ) * 100;
}

//Count number of low urgency security patches
$low_urg_sql = "SELECT server_name, package_name FROM patches WHERE urgency = 'low' OR urgency = 'Low';";
$low_urg_res = mysql_query($low_urg_sql);
while($row = mysql_fetch_array($low_urg_res)){
	$low_urg_arr_name[] = $row['server_name'];
	$low_urg_arr[] = $row['package_name'];
}
$low_urg_count = $low_urg = $low_urg_pct = 0;
if ( !empty($low_urg_arr_name) && !empty($low_urg_arr) ){
	$low_urg = count(array_unique($low_urg_arr_name));
	$low_urg_count = count($low_urg_arr);
	$low_urg_pct = ( $low_urg_count / $patches_to_apply_count ) * 100;
}

//Count number of bugfix and enhancement patches
$bug_urg_sql = "SELECT server_name, package_name FROM patches WHERE urgency = 'bugfix' OR urgency = 'enhancement';";
$bug_urg_res = mysql_query($bug_urg_sql);
while($row = mysql_fetch_array($bug_urg_res)){
	$bug_urg_arr_name[] = $row['server_name'];
	$bug_urg_arr[] = $row['package_name'];
}
$bug_urg_count = $bug_urg = $bug_urg_pct = 0;
if ( !empty($bug_urg_arr_name) && !empty($bug_urg_arr) ){
	$bug_urg = count(array_unique($bug_urg_arr_name));
	$bug_urg_count = count($bug_urg_arr);
	$bug_urg_pct = ( $bug_urg_count / $patches_to_apply_count ) * 100;
}

mysql_close($patch_list_link);
$data = "";
foreach ($navbar_array as $key=>$val){
    $plugin2 = $key;
    $plugin2_glyph = $val["glyph"];
    $plugin_name = ucwords($plugin2);
            $data .= "<div class='panel panel-default'>
                    <div class='panel-heading'>
                        <h4 class='panel-title'>
                            <a data-toggle='collapse' data-parent='#accordion' href='#collapse$plugin2'><span class='glyphicon $plugin2_glyph'>
                            &nbsp;&nbsp;</span>$plugin_name</a>
                        </h4>
                    </div>
                    <div id='collapse$plugin2' class='panel-collapse collapse in'>
                        <div class='panel-body'>
                            <table class='table'>";
    foreach ($val['page_and_glyph'] as $val2){
        $tmp_array = explode(",",$val2);
        $page_string = $tmp_array[0];
        $page_words = ucwords(str_replace("_"," ",$page_string));
        if (isset($tmp_array[1])){
            $page_glyph = "<span class=\"glyphicon ".$tmp_array[1]." text-primary\"></span>&nbsp;&nbsp;";
        }
        else{
            $page_glyph = "";
        }
        /*
         * Badge code:
         * <span class=\"badge\">42</span>
         * TODO: work the badge code in dynamically with patche count
         */
        if ($page_string == "patches"){
            $badge_code = "&nbsp;&nbsp;<span class=\"label label-default\">$patches_to_apply_count Total</span> &nbsp;&nbsp; 
				<br><br>
                <div class=\"progress\">
				  <div class=\"progress-bar progress-bar-primary\" style=\"width: $bug_urg_pct%\">$bug_urg_count Bug</div>
				  <div class=\"progress-bar progress-bar-info\" style=\"width: $low_urg_pct%\">$low_urg_count Low</div>
  				  <div class=\"progress-bar progress-bar-warning\" style=\"width: $med_urg_pct%\">$med_urg_count Med</div>
				  <div class=\"progress-bar progress-bar-danger\" style=\"width: $high_urg_pct%\">$high_urg_count High</div>
				</div>
				Servers:
				<br>
                <span class=\"label label-primary\">$bug_urg Bug</span>
                <span class=\"label label-info\">$low_urg Low</span>
                <span class=\"label label-warning\">$med_urg Med</span> 
                <span class=\"label label-danger\">$high_urg High</span>  
                ";
        }
        else{
            $badge_code = "";
        }
        $data .= "                                <tr>
                                    <td>
                                        $page_glyph<a href=\"".BASE_PATH."$page_string\">$page_words</a>$badge_code
                                    </td>
                                </tr>";
    }
        $data .= "</table>
                        </div>
                    </div>
                </div>";
}
if (!isset($_SESSION['error_notice'])){
    $error_html = "";
}
else{
    $error_message = $_SESSION['error_notice'];
    $error_html = "<div class='bs-example'><div class='alert alert-error'>
        <a href='#' class='close' data-dismiss='alert'>&times;</a>
        <strong>Error! </strong> $error_message
    </div></div>";
    unset($_SESSION['error_notice']);
    unset($error_message);
}

if (!isset($_SESSION['good_notice'])){
    $good_html = "";
}
else{
    $good_message = $_SESSION['good_notice'];
    $good_html = "<div class='container'><div class='row'><div class='span4'><div class='alert alert-success'>
        <a href='#' class='close' data-dismiss='alert'>&times;</a>
        <strong>Notice: </strong> $good_message
    </div></div></div></div>";
    unset($_SESSION['good_notice']);
    unset($good_message);
}

if (!isset($_SESSION['warning_notice'])){
    $warning_html = "";
}
else{
    $warning_message = $_SESSION['warning_notice'];
    $warning_html = "<div class='bs-example'><div class='alert alert-warning'>
        <a href='#' class='close' data-dismiss='alert'>&times;</a>
        <strong>Warning: </strong> $warning_message
    </div></div>";
    unset($_SESSION['warning_notice']);
    unset($warning_message);
}
$all_messages_to_send = "${warning_html}${good_html}${error_html}";
?>
    <div class="container-fluid">
<?php echo $all_messages_to_send;unset($all_messages_to_send);?>
      <div class="row">
        <div class="col-sm-3 col-md-3">
            <div class="panel-group" id="accordion">
                <?php echo $data;?>
            </div>
        </div>
