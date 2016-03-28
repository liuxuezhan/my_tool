/*
Navicat MySQL Data Transfer

Source Server         : 125.64.93.90
Source Server Version : 50173
Source Host           : localhost:3306
Source Database       : server1

Target Server Type    : MYSQL
Target Server Version : 50173
File Encoding         : 65001

Date: 2015-05-26 16:45:41
*/

SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for `player_distance`
-- ----------------------------
DROP TABLE IF EXISTS `player_distance`;
CREATE TABLE `player_distance` (
  `player_id` int(6) NOT NULL COMMENT 'player_distance',
  `distance` int(4) NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_id`),
  KEY `distance_idx` (`distance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of player_distance
-- ----------------------------
INSERT INTO `player_distance` VALUES ('10001', '5000', '0000-00-00 00:00:00');

-- ----------------------------
-- Table structure for `player_equip`
-- ----------------------------
DROP TABLE IF EXISTS `player_equip`;
CREATE TABLE `player_equip` (
  `player_id` int(6) NOT NULL COMMENT 'player_distance',
  `save` varchar(2000) NOT NULL,
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of player_equip
-- ----------------------------

-- ----------------------------
-- Table structure for `player_log`
-- ----------------------------
DROP TABLE IF EXISTS `player_log`;
CREATE TABLE `player_log` (
  `player_id` int(6) NOT NULL COMMENT 'player_distance',
  `time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `save` varchar(2000) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of player_log
-- ----------------------------

-- ----------------------------
-- Table structure for `player_other`
-- ----------------------------
DROP TABLE IF EXISTS `player_other`;
CREATE TABLE `player_other` (
  `player_id` int(6) NOT NULL COMMENT 'player_distance',
  `save` varchar(2000) NOT NULL,
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of player_other
-- ----------------------------
INSERT INTO `player_other` VALUES ('10001', 'local tmp={money=4000,diamond=3000,chaper=4,} return tmp');

-- ----------------------------
-- Table structure for `reg_info`
-- ----------------------------
DROP TABLE IF EXISTS `reg_info`;
CREATE TABLE `reg_info` (
  `player_id` int(11) NOT NULL COMMENT '主索引查询比第二索引快，但统计数量第二索引快',
  `name` varchar(51) NOT NULL DEFAULT '',
  `pwd` varchar(11) NOT NULL COMMENT '密码',
  `distance` int(4) NOT NULL,
  `login_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP COMMENT '最近登录时间  (频繁写表，可能去掉或分表 )',
  `is_system_user` tinyint(3) unsigned NOT NULL COMMENT '是否系统用户',
  PRIMARY KEY (`player_id`,`name`),
  UNIQUE KEY `reg_user_id_idx` (`player_id`) USING BTREE,
  UNIQUE KEY `reg_nick_name_idx` (`name`) USING BTREE,
  KEY `login_time_idx` (`login_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Records of reg_info
-- ----------------------------
INSERT INTO `reg_info` VALUES ('10001', 'test', 'pswd', '1', '0000-00-00 00:00:00', '0');
