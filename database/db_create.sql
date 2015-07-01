CREATE TABLE `patch_allpackages` (
  `server_name` varchar(128) NOT NULL,
  `package_name` varchar(60) NOT NULL,
  `package_version` varchar(60) NOT NULL,
  PRIMARY KEY (`server_name`,`package_name`),
  KEY `ix_server_name` (`server_name`),
  KEY `ix_package_name` (`package_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `servers` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `server_name` varchar(128) NOT NULL,
  `server_alias` varchar(128) NOT NULL,
  `server_group` varchar(128) DEFAULT NULL,
  `distro_id` mediumint(8) NOT NULL,
  `server_ip` varchar(60) NOT NULL,
  `distro_version` mediumint(8) NOT NULL,
  `client_key` varchar(255) DEFAULT NULL,
  `trusted` tinyint(1) NOT NULL DEFAULT '0',
  `last_seen` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `last_checked` datetime NOT NULL DEFAULT '2001-01-01 00:00:00',
  `reboot_cmd_sent` tinyint(1) NOT NULL DEFAULT '0',
  `needs_restart` varchar(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_key` (`client_key`),
  KEY `ix_server_name` (`server_name`(128)),
  KEY `ix_server_alias` (`server_alias`(128)),
  KEY `ix_server_ip` (`server_ip`),
  KEY `ix_client_key` (`client_key`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `supressed` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `package_name` varchar(40) NOT NULL,
  `server_name` varchar(128) NOT NULL, /* 0 for global */
  PRIMARY KEY (`id`),
  KEY `ix_package_name` (`package_name`),
  KEY `ix_server_name` (`server_name`(255))
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `distro` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `distro_name` varchar(20) NOT NULL,
  `icon_path` varchar(255) NOT NULL,
  `upgrade_command` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_distro_name` (`distro_name`),
  KEY `ix_icon_path` (`icon_path`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `distro` (`id`, `distro_name`, `icon_path`, `upgrade_command`) VALUES
(1, 'Ubuntu', 'img/icon/ubuntu.png', 'apt-get -y install'),
(2, 'Debian', 'img/icon/debian.png', 'apt-get -y install'),
(3, 'Fedora', 'img/icon/fedora.png', 'yum -y install'),
(4, 'CentOS', 'img/icon/centos.png', 'yum -y install'),
(5, 'RHEL', 'img/icon/rhel.png', 'yum -y install'),
(6, 'Oracle', 'img/icon/oracle.png', 'yum -y install');

CREATE TABLE `distro_version` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `version_num` varchar(20) NOT NULL,
  `distro_id` mediumint(8) NOT NULL,
  `eol_date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_version_num` (`version_num`),
  KEY `ix_distro_id` (`distro_id`),
  KEY `ix_eol_date` (`eol_date`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `distro_version` (`id`, `version_num`, `distro_id`, `eol_date`) VALUES
(1, '10.04_Desktop', 1, '2013-05-31 00:00:00'),
(2, '10.04_Server', 1, '2015-04-30 00:00:00'),
(3, '12.04_Desktop', 1, '2017-04-30 00:00:00'),
(4, '12.04_Server', 1, '2017-04-30 00:00:00'),
(5, '14.04_Desktop', 1, '2019-04-30 00:00:00'),
(6, '14.04_Server', 1, '2019-04-30 00:00:00'),
(7, '6', 2, '2016-02-28 00:00:00'),
(8, '7', 2, '2024-07-26 00:00:00'),
(9, '15', 3, '2012-06-26 00:00:00'),
(10, '16', 3, '2013-02-12 00:00:00'),
(11, '17', 3, '2013-07-30 00:00:00'),
(12, '18', 3, '2014-01-14 00:00:00'),
(13, '19', 3, '2014-07-26 00:00:00'),
(14, '20', 3, '2015-01-26 00:00:00'),
(15, '5', 4, '2017-03-31 00:00:00'),
(16, '6', 4, '2020-11-30 00:00:00'),
(17, '5', 5, '2017-03-31 00:00:00'),
(18, '6', 5, '2020-11-30 00:00:00'),
(19, '7', 5, '2024-06-30 00:00:00'),
(20, '5', 6, '2017-03-31 00:00:00'),
(21, '6', 6, '2020-11-30 00:00:00'),
(22, '7', 6, '2024-06-30 00:00:00'),
(23, '7', 6, '2024-06-30 00:00:00');

CREATE TABLE `patches` (
  `server_name` varchar(128) NOT NULL,
  `package_name` varchar(60) NOT NULL,
  `current` varchar(60) NOT NULL,
  `new` varchar(60) NOT NULL,
  `urgency` varchar(20) DEFAULT NULL,
  `bug_url` varchar(512) DEFAULT NULL,
  `distro` mediumint(8) DEFAULT NULL,
  `to_upgrade` tinyint(1) NOT NULL DEFAULT '0',
  `upgraded` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`server_name`,`package_name`,`new`),
  KEY `server_name` (`server_name`),
  KEY `ix_package_name` (`package_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(40) NOT NULL,
  `email` varchar(80) NOT NULL,
  `admin` tinyint(1) NOT NULL DEFAULT '0',
  `display_name` varchar(50) DEFAULT NULL,
  `password` varchar(512) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `last_seen` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `receive_alerts` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `ix_password` (`password`(255)),
  KEY `ix_user_id` (`user_id`),
  KEY `ix_receive_alerts` (`receive_alerts`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `company` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `display_name` varchar(50) NOT NULL,
  `install_key` varchar(512) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `plugins` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `disabled` tinyint(1) NOT NULL DEFAULT '1',
  `installed` tinyint(1) NOT NULL DEFAULT '0',
  `is_admin` tinyint(1) NOT NULL DEFAULT '1',
  `glyph` char(30) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `ix_name` (`name`),
  KEY `ix_glyph` (`glyph`),
  KEY `ix_disabled` (`disabled`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `plugins` (`id`, `name`, `disabled`, `installed`, `is_admin`, `glyph`) VALUES
(1, 'main', 0, 1, 0, 'glyphicon-home'),
(2, 'admin', 0, 1, 1, 'glyphicon-wrench');

CREATE TABLE `page_maps` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `page_name` varchar(40) NOT NULL,
  `real_file` varchar(40) NOT NULL,
  `plugin_parent` tinyint(4) NOT NULL,
  `on_navbar` tinyint(1) NOT NULL DEFAULT '0',
  `glyph` char(30) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `page_name` (`page_name`),
  KEY `ix_on_navbar` (`on_navbar`),
  KEY `ix_glyph` (`glyph`),
  KEY `ix_page_name` (`page_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `page_maps` (`id`, `page_name`, `real_file`, `plugin_parent`, `on_navbar`, `glyph`) VALUES
(1, 'patches', 'patches.inc.php', 1, 1, 'glyphicon-warning-sign'),
(2, 'patch_list', 'patch_list.inc.php', 1, 0, ''),
(3, 'packages', 'packages.inc.php', 1, 0, ''),
(4, 'search', 'search.inc.php', 1, 0, ''),
(5, 'deactivate_server', 'deactivate_server.inc.php', 2, 0, ''),
(6, 'deactivate_user', 'deactivate_user.inc.php', 2, 0, ''),
(7, 'delete_server', 'delete_server.inc.php', 2, 0, ''),
(8, 'delete_user', 'delete_user.inc.php', 2, 0, ''),
(9, 'edit_server', 'edit_server.inc.php', 2, 0, ''),
(10, 'edit_user', 'edit_user.inc.php', 2, 0, ''),
(11, 'manage_users', 'manage_users.inc.php', 2, 1, 'glyphicon-star'),
(12, 'manage_servers', 'manage_servers.inc.php', 2, 1, 'glyphicon-hdd'),
(13, 'add_user', 'add_user.inc.php', 2, 1, 'glyphicon-eye-open'),
(14, 'manage_suppressions', 'manage_suppressions.inc.php', 2, 1, 'glyphicon-minus-sign'),
(15, 'add_server', 'add_server.inc.php', 2, 1, 'glyphicon-question-sign');
-- CREATE TABLE `wsus_data` (
-- ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
