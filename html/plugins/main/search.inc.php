<?php
/*
 * Fail-safe check. Ensures that they go through the main page (and are authenticated to use this page
 */
if (!isset($index_check) || $index_check != "active"){
    exit();
}
 include 'inc/supressed_patches.inc.php';
 $link = mysql_connect(DB_HOST,DB_USER,DB_PASS);
 mysql_select_db(DB_NAME,$link);
 $package = filter_var($_GET['package'],FILTER_SANITIZE_MAGIC_QUOTES);
 $count = 0;
 if (isset($_GET['exact']) && $_GET['exact'] == "true"){
	$sql1 = "SELECT * FROM patch_allpackages where package_name = '$package';";
	$searchagain_link = BASE_PATH."search/".basename($_SERVER['REQUEST_URI']);
	$searchagain_txt = "Fuzzy";
 }
 else{
	$sql1 = "select * from patch_allpackages where package_name like '%$package%';";
	$searchagain_link = BASE_PATH."search/exact/".basename($_SERVER['REQUEST_URI']);
	$searchagain_txt = "Exact";
 }
 $res1 = mysql_query($sql1);
 $base_path = BASE_PATH;
 while ($row1 = mysql_fetch_assoc($res1)){
     $count++;
     $package_name = $row1['package_name'];
     $package_version = $row1['package_version'];
     $server_name = $row1['server_name'];
     $table .= "                <tr>
		  <td><a href='${base_path}patches/server/$server_name' style='color:black'>$server_name</a></td>
                  <td><a href='${base_path}search/exact/$package_name' style='color:green'>$package_name</a></td>
		  <td>$package_version</td>
                </tr>
";
}
?>
          <h1 class="page-header">Search</h1>
          <div class="sub-header">
	          <h3 >Results for search "<?php echo $package;?>" (<?php echo $count;?> found)</h3>
	          <a href="<?php echo $searchagain_link; ?>">Try <?php echo $searchagain_txt; ?> Search</a>
          </div>
        <div class="container">
          <div class="table-responsive">
            <table class="table table-striped">
             <thead>
                <tr>
                  <th>Server Name</th>
                  <th>Package Name</th>
                  <th>Package Version</th>
                </tr>
              </thead>
              <tbody>
<?php echo $table;?>
              </tbody>
            </table>
          </div>
        </div>
