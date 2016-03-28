CREATE DATABASE `gateway`;
use gateway;
DROP TABLE IF EXISTS `servers`;
CREATE TABLE `servers` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`area_id` TINYINT(2) NOT NULL,
	`plat_id` TINYINT(2) NOT NULL,
	`partition` SMALLINT(4) NOT NULL,
	`name` VARCHAR(255) DEFAULT NULL,
	`ip` VARCHAR(50) NOT NULL,
	`port` int(11) NOT NULL,
	`db_host` VARCHAR(50) NOT NULL,
	`db_port` INT(11) NOT NULL DEFAULT '3306',
	`db_name` VARCHAR(50) NOT NULL,
	`db_user` VARCHAR(50) DEFAULT NULL,
	`db_pass` VARCHAR(50) DEFAULT NULL,
	`open_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
	`status` smallint(4) NOT NULL DEFAULT '0',
	`ref_id` VARCHAR(20) DEFAULT NULL,
	`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY idx_server (`area_id`, `plat_id`, `partition`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;