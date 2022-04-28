-- *****************************************************************************
--
-- GMNG v2
--
-- *****************************************************************************

SET character_set_client = utf8;

CREATE DATABASE IF NOt EXISTS `gmng`;
USE `gmng`;

--
-- Table structure for table `cmd_status_codes`
--
CREATE TABLE IF NOT EXISTS `cmd_status_codes` (
  `op_status` tinyint(3) unsigned NOT NULL,
  `description` enum('CMD_PROCESSED','CMD_PULLED','CMD_OK','CMD_FAIL','CMD_TIMEOUT') NOT NULL,
  PRIMARY KEY  USING BTREE (`op_status`)
);

--
-- Table structure for table `db_info`
--
CREATE TABLE IF NOT EXISTS `db_info` (
  `version` int(4) unsigned NOT NULL auto_increment,
  PRIMARY KEY  USING BTREE (`version`)
);

--
-- Table structure for table `dev_types`
--
CREATE TABLE IF NOT EXISTS `dev_types` (
  `type` tinyint(3) unsigned zerofill NOT NULL auto_increment,
  `description` varchar(45) NOT NULL,
  `default_port` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY  USING BTREE (`type`)
);

--
-- Table structure for table `dev_info`
--
CREATE TABLE IF NOT EXISTS`dev_info` (
  `dev_id` varchar(32) NOT NULL,
  `type` tinyint(3) unsigned NOT NULL COMMENT 'Device type according to dev_types.type',
  `nav_data_validity` tinyint(3) unsigned NOT NULL default '30' COMMENT 'Navigation data validity (in days)',
  `port_num` smallint(5) unsigned NOT NULL default '0' COMMENT '0 mean to use default port',
  `timeout` int(10) unsigned NOT NULL default '1' COMMENT 'Timeout between command sending and any followed response (in minutes)',
  PRIMARY KEY  USING BTREE (`dev_id`),
  KEY `FK_type` (`type`),
  CONSTRAINT `FK_type` FOREIGN KEY (`type`) REFERENCES `dev_types` (`type`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Each device information data ';

--
-- Table structure for table `init_string`
--
CREATE TABLE IF NOT EXISTS `init_string` (
  `dev_id` varchar(32) NOT NULL,
  `str` varchar(128) NOT NULL,
  PRIMARY KEY  USING BTREE (`dev_id`),
  CONSTRAINT `dev_id_fk` FOREIGN KEY (`dev_id`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Initialization string for those device which is mandatory needs it';

--
-- Table structure for table `terminal_accounts`
--
CREATE TABLE IF NOT EXISTS `terminal_accounts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `login` varchar(32) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `login_idx` (`login`)
) COMMENT='Terminal account names (generally identifies each client)';

--
-- Table structure for table `login_map`
--
CREATE TABLE IF NOT EXISTS `login_map` (
  `dev_id` varchar(32) NOT NULL,
  `login` varchar(32) NOT NULL COMMENT 'SQL terminal account name. Terminal name must exist in terminal_accounts table first',
  PRIMARY KEY  USING BTREE (`login`,`dev_id`),
  KEY `devid_idx` USING BTREE (`dev_id`),
  CONSTRAINT `devid_fk` FOREIGN KEY (`dev_id`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `login_fk` FOREIGN KEY (`login`) REFERENCES `terminal_accounts` (`login`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='SQL terminal login mappped to device id which is owned by client';

--
-- Table structure for table `nav_data`
--
CREATE TABLE IF NOT EXISTS `nav_data` (
  `rec_num` bigint(20) unsigned NOT NULL auto_increment,
  `dev_id` varchar(32) NOT NULL,
  `insertion_time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `nav_time` timestamp NOT NULL default '1970-01-01 00:00:01',
  `nd_data` tinyblob NOT NULL,
  `source_ip` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  USING BTREE (`rec_num`),
  KEY `devid_idx` (`dev_id`),
  KEY `recnum_devid_idx` (`rec_num`,`dev_id`),
  CONSTRAINT `nav_data_devid_fk` FOREIGN KEY (`dev_id`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Navigation data table' ROW_FORMAT=DYNAMIC;

--
-- Table structure for table `req`
--
CREATE TABLE IF NOT EXISTS `req` (
  `rec_num` int(10) unsigned NOT NULL auto_increment,
  `dev_id` varchar(32) NOT NULL,
  `insertion_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `cmd_id` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param1` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param2` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param3` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param4` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param5` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `param6` int(11) NOT NULL COMMENT 'Param from MSSQL',
  `str1` varchar(128) NOT NULL COMMENT 'Param from MSSQL',
  `str2` varchar(128) NOT NULL COMMENT 'Param from MSSQL',
  `datetime1` int(10) unsigned NOT NULL COMMENT 'Param from MSSQL',
  `datetime2` int(10) unsigned NOT NULL COMMENT 'Param from MSSQL',
  `cmd_guid` char(38) NOT NULL COMMENT 'SQL terminal purpose',
  `trm_guid` char(38) NOT NULL COMMENT 'SQL terminal purpose',
  PRIMARY KEY  USING BTREE (`rec_num`),
  KEY `devid_idx` (`dev_id`),
  KEY `trm_guid_idx` USING BTREE (`trm_guid`),
  CONSTRAINT `req_devid_fk` FOREIGN KEY (`dev_id`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Command request table';

--
-- Table structure for table `req_in`
--
CREATE TABLE IF NOT EXISTS `req_in` (
  `rec_num` int(10) unsigned NOT NULL auto_increment COMMENT 'Command number refered to req table ',
  PRIMARY KEY  USING BTREE (`rec_num`),
  CONSTRAINT `rec_num_fk` FOREIGN KEY (`rec_num`) REFERENCES `req` (`rec_num`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Command request table visible to proto parser';

--
-- Table structure for table `req_serviced`
--
CREATE TABLE IF NOT EXISTS `req_serviced` (
  `rec_num` int(10) unsigned NOT NULL auto_increment,
  PRIMARY KEY  USING BTREE (`rec_num`),
  CONSTRAINT `req_serviced_recnum_fk` FOREIGN KEY (`rec_num`) REFERENCES `req` (`rec_num`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Successfully proccesed or failed to process command id';

--
-- Table structure for table `req_status`
--
CREATE TABLE IF NOT EXISTS `req_status` (
  `op_status` tinyint(3) unsigned NOT NULL default '0',
  `insertion_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `rec_num` int(10) unsigned NOT NULL default '0' COMMENT 'Command number referred to req table',
  `row_num` bigint(20) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`row_num`),
  KEY `opstatus_idx` USING BTREE(`op_status`),
  KEY `rec_num_idx` USING BTREE (`rec_num`),
  CONSTRAINT `req_status_recnum_fk` FOREIGN KEY (`rec_num`) REFERENCES `req` (`rec_num`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `req_status_opstatus_fk` FOREIGN KEY (`op_status`) REFERENCES `cmd_status_codes` (`op_status`) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Command execution progress (in status codes of table cmd_status_codes)';

--
-- Table structure for table `dev_activity`
--
CREATE TABLE IF NOT EXISTS `dev_activity` (
  `dev_id` varchar(32) NOT NULL,
  `last_up_time` DATETIME,
  `last_nav_time` DATETIME,
  `last_reg_ip` int(10) unsigned,
  `last_data_ip` int(10) unsigned,
  PRIMARY KEY  (`dev_id`)
);

DROP PROCEDURE IF EXISTS `select_live_point_nav_time`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_live_point_nav_time`(IN `point_date` TIMESTAMP)
BEGIN
    SELECT
        ND.rec_num AS rec_num
    FROM
        login_map AS MAP
    JOIN
        nav_data AS ND USING (dev_id)
     WHERE
        MAP.login=substring(user(),1,locate('@',user())-1)
     AND
       -- Need to cast point_date from GMT to localtime
        ND.nav_time >= ADDTIME(point_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
    ORDER BY
        nav_time,rec_num LIMIT 1;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `select_last_live_point_by_nav_time`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`PROCEDURE `select_last_live_point_by_nav_time`(IN `point_date` TIMESTAMP)
BEGIN
    SELECT
        ND.rec_num AS rec_num
    FROM
        login_map AS MAP
    JOIN
        nav_data AS ND USING (dev_id)
     WHERE
         MAP.login=substring(user(),1,locate('@',user())-1)
     AND
       -- Need to cast point_date from GMT to localtime
        ND.nav_time <= ADDTIME(point_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
    ORDER BY
        nav_time DESC, rec_num  LIMIT 1;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `select_live_point_ins_time`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_live_point_ins_time`(IN point_date TIMESTAMP)
BEGIN
 SELECT ND.rec_num
 FROM nav_data AS ND JOIN login_map AS MAP USING (dev_id)
 JOIN dev_info AS DI USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.insertion_time >= point_date
 ORDER BY insertion_time ASC, ND.rec_num LIMIT 1;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `get_activ_dev_count`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost`PROCEDURE `get_activ_dev_count`(IN timeinterval INTEGER)
BEGIN
 SELECT description,qall,IF(ISNULL(qa),0,qa)AS qactiv
 FROM (  SELECT count(*) AS qa,devi.dev_id,type,last_nav_time,last_up_time
 FROM  dev_info AS devi JOIN login_map AS map USING (dev_id)
 LEFT JOIN dev_activity AS deva ON (devi.dev_id=deva.dev_id)
 WHERE map.login=substring(user(),1,locate('@',user())-1) AND last_up_time>NOW()-INTERVAL timeinterval SECOND
 GROUP BY (type))AS t1
 RIGHT JOIN (  SELECT count(*) AS qall,type
 FROM dev_info AS devi JOIN login_map AS map USING (dev_id)
 WHERE map.login=substring(user(),1,locate('@',user())-1)
 GROUP BY (type)) AS t2
 USING (type)
 JOIN dev_types
 USING (type);
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `get_activ_dev`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_activ_dev`(IN activinterval INTEGER,IN activnavinterval INTEGER)
BEGIN
SELECT devi.dev_id,devt.description,deva.last_up_time,deva.last_nav_time,
                                  IF(last_up_time>NOW()-INTERVAL activinterval SECOND,
                                  IF(last_nav_time>NOW()-INTERVAL activnavinterval SECOND,2,1),0) AS activ,
				  inits.str AS init_string
	  ,IF(devi.port_num=0,devt.default_port,devi.port_num) AS port,
          deva.last_reg_ip,deva.last_data_ip,
          map.login
FROM dev_info AS devi JOIN login_map AS map USING (dev_id)
		LEFT JOIN init_string AS inits ON (devi.dev_id=inits.dev_id)
            	LEFT JOIN dev_activity AS deva ON (deva.dev_id=devi.dev_id)
            	JOIN dev_types AS devt ON (devt.type=devi.type)
            WHERE   map.login=substring(user(),1,locate('@',user())-1);
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `insert_req`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_req`(devid VARCHAR(32), cmdid INTEGER, cmdguid CHAR(38), trmguid CHAR(38), intparam1 INTEGER, intparam2 INTEGER, intparam3 INTEGER, intparam4 INTEGER, intparam5 INTEGER, intparam6 INTEGER, strparam1 VARCHAR(128), strparam2 VARCHAR(128), dtparam1 INT UNSIGNED, dtparam2 INT UNSIGNED)
BEGIN
 START TRANSACTION;
 INSERT INTO req (dev_id, cmd_id, cmd_guid, trm_guid, param1, param2, param3, param4, param5, param6, str1, str2, datetime1, datetime2) VALUES (devid, cmdid, cmdguid, trmguid,    intparam1, intparam2, intparam3, intparam4, intparam5, intparam6, strparam1, strparam2, dtparam1, dtparam2);
 INSERT INTO req_in(rec_num) VALUES (LAST_INSERT_ID());
 COMMIT;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `select_data_by_range`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_data_by_range`(IN begin_row INTEGER, IN end_row INTEGER)
BEGIN
 SELECT ND.* FROM login_map AS MAP JOIN nav_data AS ND USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.rec_num>=begin_row AND ND.rec_num<end_row
 ORDER BY ND.rec_num
 LIMIT 10000;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `select_data_from`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_data_from`(IN from_row INTEGER)
BEGIN
 SELECT ND.* FROM login_map AS MAP JOIN nav_data AS ND USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.rec_num>=from_row
 ORDER BY ND.rec_num
 LIMIT 10000;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `select_live_point`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_live_point`(IN point_date TIMESTAMP)
BEGIN
 SELECT
  -- MAX(ND.rec_num)
  ND.rec_num rec_num
 FROM nav_data ND USE INDEX (PRIMARY)
 JOIN login_map MAP USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.insertion_time<=point_date
 ORDER BY rec_num DESC
 LIMIT 1;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `status_req`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `status_req`(IN from_row INTEGER, trmguid CHAR(38))
BEGIN
 SELECT
  req_status.row_num AS rec_num,
  req.dev_id,
  req.insertion_time,
  req.cmd_id,
  req.param1,
  req.param2,
  req.param3,
  req.param4,
  req.param5,
  req.param6,
  req.str1,
  req.str2,
  req.datetime1,
  req.datetime2,
  req.cmd_guid,
  req.trm_guid,
  req_status.op_status,
  req_status.insertion_date AS status_ins_date
 FROM req_status
 JOIN req USING (rec_num)
 WHERE req_status.row_num >= from_row AND req.trm_guid = trmguid
 ORDER BY req_status.row_num;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `version`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `version`()
BEGIN
 SELECT MAX(version) AS version
 FROM db_info;
END $$
DELIMITER ;

--
-- ACTIVITY PROC.
--
DROP PROCEDURE IF EXISTS `show_active_devs`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `show_active_devs`(IN threshold INT UNSIGNED) SQL SECURITY INVOKER
BEGIN
 SELECT dev_id, dt.description AS type, last_up_time,
        last_nav_time, NOW() AS cur_time,
        INET_NTOA(last_reg_ip) AS last_reg_ip,
        INET_NTOA(last_data_ip) AS last_data_ip
 FROM dev_activity da
 JOIN dev_info di USING (dev_id)
 JOIN dev_types dt USING (type)
 WHERE ADDTIME(last_up_time, threshold) >= NOW();
END $$
DELIMITER ;

--
-- Final view structure for view `nav_data_v`
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER
VIEW `nav_data_v` AS
 SELECT `nav_data`.`dev_id` AS `dev_id`,
        `nav_data`.`nav_time` AS `nav_time`,
        `nav_data`.`nd_data` AS `nd_data`,
        `nav_data`.`source_ip` AS `source_ip`
 FROM `nav_data`;

--
-- Final view structure for view `req_in_v`
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER
VIEW `req_in_v` AS
 SELECT `req_in`.`rec_num` AS `rec_num`,
        `req`.`dev_id` AS `dev_id`,
        `req`.`insertion_time` AS `insertion_time`,
        `req`.`cmd_id` AS `cmd_id`,
        `req`.`param1` AS `param1`,
        `req`.`param2` AS `param2`,
        `req`.`param3` AS `param3`,
        `req`.`param4` AS `param4`,
        `req`.`param5` AS `param5`,
        `req`.`param6` AS `param6`,
        `req`.`str1` AS `str1`,
        `req`.`str2` AS `str2`,
        `req`.`datetime1` AS `date1`,
        `req`.`datetime2` AS `date2`
 FROM (`req_in` JOIN `req` ON((`req_in`.`rec_num` = `req`.`rec_num`)));

START TRANSACTION;
INSERT INTO `cmd_status_codes` VALUES (0, 'CMD_PROCESSED') ON DUPLICATE KEY UPDATE op_status=0;
INSERT INTO `cmd_status_codes` VALUES (1, 'CMD_PULLED') ON DUPLICATE KEY UPDATE op_status=1;
INSERT INTO `cmd_status_codes` VALUES (2, 'CMD_OK') ON DUPLICATE KEY UPDATE op_status=2;
INSERT INTO `cmd_status_codes` VALUES (3, 'CMD_FAIL') ON DUPLICATE KEY UPDATE op_status=3;
INSERT INTO `cmd_status_codes` VALUES (4, 'CMD_TIMEOUT') ON DUPLICATE KEY UPDATE op_status=4;
COMMIT;

-- backup user role
CREATE USER IF NOT EXISTS 'bak_user'@'localhost';
GRANT SELECT, LOCK TABLES, EVENT, SHOW VIEW ON gmng.* TO 'bak_user'@'localhost';
-- logrotate script needs this
GRANT RELOAD ON *.* to 'bak_user'@'localhost';

START TRANSACTION;
TRUNCATE `db_info`;
INSERT INTO `db_info`(`version`) VALUES (2);
COMMIT;

-- *****************************************************************************
--
-- GMNG v3
--
-- *****************************************************************************
DROP PROCEDURE IF EXISTS `tmp_drop_dev_activity_devid_fk`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_drop_dev_activity_devid_fk`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_NAME = 'dev_activity_devid_fk') THEN
   ALTER TABLE `dev_activity` DROP FOREIGN KEY dev_activity_devid_fk;
 END IF;
END $$
DELIMITER ;
CALL `tmp_drop_dev_activity_devid_fk`();
DROP PROCEDURE IF EXISTS `tmp_drop_dev_activity_devid_fk`;

DROP PROCEDURE IF EXISTS `show_active_devs_total`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `show_active_devs_total`(IN `threshold` INT UNSIGNED) SQL SECURITY INVOKER
BEGIN
SELECT COUNT(*) total
 FROM dev_activity
   JOIN dev_info USING (dev_id)
     JOIN dev_types USING (type)
       WHERE TIMESTAMPDIFF(SECOND, last_up_time, CURRENT_TIMESTAMP) <= threshold;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `show_active_types`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `show_active_types`(IN `threshold` INT UNSIGNED) SQL SECURITY INVOKER
BEGIN
SELECT description type, COUNT(description) cnt
  FROM dev_activity JOIN dev_info USING (dev_id) JOIN dev_types USING (type)
    WHERE TIMESTAMPDIFF(SECOND, last_up_time, CURRENT_TIMESTAMP) <= threshold
      GROUP BY description
        ORDER BY cnt DESC;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `read_by_date_range_from`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `read_by_date_range_from`(IN `from_date` TIMESTAMP,IN `to_date` TIMESTAMP)
BEGIN
    SELECT
        MIN(ND.rec_num) rec_num
    FROM
        login_map MAP
    JOIN
        nav_data  ND USING (dev_id)
    WHERE
        MAP.login=substring(user(),1,locate('@',user())-1)
    AND
        ND.nav_time
 	BETWEEN ADDTIME(from_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
        AND ADDTIME(to_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
    AND
        ND.nav_time <= insertion_time;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `read_by_date_range_to`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `read_by_date_range_to`(IN `from_date` timestamp,IN `to_date` timestamp)
BEGIN
    SELECT
        MAX(ND.rec_num) rec_num
    FROM
        login_map MAP
    JOIN
        nav_data ND USING (dev_id)
    WHERE
        MAP.login=substring(user(),1,locate('@',user())-1)
    AND
        ND.nav_time
        BETWEEN ADDTIME(from_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
        AND ADDTIME(to_date,TIMEDIFF(CURRENT_TIMESTAMP(),UTC_TIMESTAMP()))
    AND
        ND.nav_time <= insertion_time;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `get_users`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_users`()
BEGIN
  SELECT DISTINCT `User` FROM `mysql`.`user` mu JOIN `terminal_accounts` ta ON mu.User=ta.login;
END $$
DELIMITER ;

-- Change Rowtype for table nav_data to DYNAMIC
DROP PROCEDURE IF EXISTS `tmp_set_navdata_rowtype_dynamic`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_set_navdata_rowtype_dynamic`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'nav_data'
   AND UPPER(ROW_FORMAT) <> 'DYNAMIC') THEN
    ALTER TABLE `nav_data` ROW_FORMAT=DYNAMIC;
 END IF;
END $$
DELIMITER ;
CALL `tmp_set_navdata_rowtype_dynamic`();
DROP PROCEDURE IF EXISTS `tmp_set_navdata_rowtype_dynamic`;

-- Change Engine for table dev_activity to MEMORY
DROP PROCEDURE IF EXISTS `tmp_set_devactivity_engine_memory`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_set_devactivity_engine_memory`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'nav_data'
   AND UPPER(ENGINE) <> 'MEMORY') THEN
    ALTER TABLE `dev_activity` ENGINE=MEMORY;
 END IF;
END $$
DELIMITER ;
CALL `tmp_set_devactivity_engine_memory`();
DROP PROCEDURE IF EXISTS `tmp_set_devactivity_engine_memory`;

-- Change Column type for last_up_time,last_nav_time fields of table dev_activity to timestamp
DROP PROCEDURE IF EXISTS `tmp_set_devactivity_lut_lnt_timestamp`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_set_devactivity_lut_lnt_timestamp`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'dev_activity'
   AND COLUMN_NAME = 'last_up_time'
   AND LOWER(DATA_TYPE) <> 'timestamp') THEN
    ALTER TABLE `dev_activity` MODIFY COLUMN `last_up_time` TIMESTAMP NULL DEFAULT NULL AFTER `dev_id`;
 END IF;
 IF EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'dev_activity'
   AND COLUMN_NAME = 'last_nav_time'
   AND LOWER(DATA_TYPE) <> 'timestamp') THEN
    ALTER TABLE `dev_activity` MODIFY COLUMN `last_nav_time` TIMESTAMP NULL DEFAULT NULL AFTER `last_up_time`;
 END IF;
END $$
DELIMITER ;
CALL `tmp_set_devactivity_lut_lnt_timestamp`();
DROP PROCEDURE IF EXISTS `tmp_set_devactivity_lut_lnt_timestamp`;

DROP TRIGGER IF EXISTS `da_insert_trx`;
DELIMITER $$
CREATE TRIGGER `da_insert_trx` BEFORE INSERT ON `dev_activity` FOR EACH ROW BEGIN
 IF NEW.dev_id NOT IN (SELECT dev_id FROM dev_info) THEN
--    SIGNAL SQLSTATE '45000';
    CALL raise_error;
 END IF;
END $$
DELIMITER ;

-- Triggers that prevents violating of login name across mysql.user.
DROP TRIGGER IF EXISTS `terminal_accounts_insert_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_insert_trx` BEFORE INSERT ON `terminal_accounts` FOR EACH ROW BEGIN
  DECLARE cnt  INT;
  SELECT  COUNT(*)  FROM  mysql.user WHERE User = NEW.login  INTO cnt;
  IF cnt IS NULL OR cnt = 0 THEN
--    SIGNAL SQLSTATE '45000';
    CALL raise_error;
   END IF;
 END $$
DELIMITER ;

DROP TRIGGER IF EXISTS `terminal_accounts_update_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_update_trx` BEFORE UPDATE ON `terminal_accounts` FOR EACH ROW BEGIN
  DECLARE cnt  INT;
  SELECT  COUNT(*)  FROM  mysql.user WHERE User = NEW.login INTO cnt;
  IF cnt IS NULL OR cnt = 0 THEN
--    SIGNAL SQLSTATE '45000';
    CALL raise_error;
   END IF;
 END $$
DELIMITER ;

DROP EVENT IF EXISTS `clean_base_event`;
DROP EVENT IF EXISTS `gmng_cleanup_evt`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` EVENT `gmng_cleanup_evt` ON SCHEDULE EVERY 1 DAY STARTS '2012-01-01 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
 DELETE FROM gmng.nav_data WHERE ADDDATE( DATE(insertion_time), INTERVAL 21 DAY) < CURDATE();
 DELETE FROM gmng.req WHERE ADDDATE(DATE(insertion_time), INTERVAL 21 DAY) < CURDATE();
END $$
DELIMITER ;

DROP USER IF EXISTS `bak_user`@`localhost`;
CREATE USER IF NOT EXISTS `bak_user`@`localhost`;
GRANT SELECT, LOCK TABLES, EVENT, SHOW VIEW ON `gmng`.* TO `bak_user`@`localhost`;
GRANT SELECT, LOCK TABLES, EVENT, SHOW VIEW ON `mysql`.* TO `bak_user`@`localhost`;

-- Remove autoinc from version field of db_info
DROP PROCEDURE IF EXISTS `tmp_drop_db_info_version_autoinc`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_drop_db_info_version_autoinc`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'db_info'
   AND COLUMN_NAME = 'version'
   AND EXTRA = 'auto_increment') THEN
    ALTER TABLE `db_info` MODIFY COLUMN `version` int(4) UNSIGNED NOT NULL FIRST;
 END IF;
END $$
DELIMITER ;
CALL `tmp_drop_db_info_version_autoinc`();
DROP PROCEDURE IF EXISTS `tmp_drop_db_info_version_autoinc`;

DROP PROCEDURE IF EXISTS `tmp_set_navdata_nddata_to_medium_blob`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_set_navdata_nddata_to_medium_blob`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'nav_data'
   AND COLUMN_NAME = 'nd_data'
   AND DATA_TYPE = 'tinyblob') THEN
    ALTER TABLE `nav_data` MODIFY COLUMN `nd_data` mediumblob NOT NULL AFTER `nav_time`;
 END IF;
END $$
DELIMITER ;
CALL `tmp_set_navdata_nddata_to_medium_blob`();
DROP PROCEDURE IF EXISTS `tmp_set_navdata_nddata_to_medium_blob`;

DROP PROCEDURE IF EXISTS `tmp_add_dbinfo_id_modtime_fields`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_add_dbinfo_id_modtime_fields`() SQL SECURITY INVOKER
BEGIN
 IF NOT EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'db_info'
   AND COLUMN_NAME = 'id'
   AND DATA_TYPE = 'int') THEN
    ALTER TABLE `db_info`ADD COLUMN `id` int UNSIGNED NOT NULL AUTO_INCREMENT FIRST,
    DROP PRIMARY KEY,
    ADD PRIMARY KEY (`id`);
 END IF;
 IF NOT EXISTS (SELECT NULL FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'db_info'
   AND COLUMN_NAME = 'mtime'
   AND DATA_TYPE = 'timestamp') THEN
    ALTER TABLE `db_info` ADD COLUMN `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `version`;
 END IF;
END $$
DELIMITER ;
CALL `tmp_add_dbinfo_id_modtime_fields`();
DROP PROCEDURE IF EXISTS `tmp_add_dbinfo_id_modtime_fields`;

-- Change Rowtype for table db_info to COMPRESSED
DROP PROCEDURE IF EXISTS `tmp_set_dbinfo_rowtype_compressed`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_set_dbinfo_rowtype_compressed`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'db_info'
   AND UPPER(ROW_FORMAT) <> 'DYNAMIC') THEN
    ALTER TABLE `db_info` ROW_FORMAT=COMPRESSED;
 END IF;
END $$
DELIMITER ;
CALL `tmp_set_dbinfo_rowtype_compressed`();
DROP PROCEDURE IF EXISTS `tmp_set_dbinfo_rowtype_compressed`;

DROP PROCEDURE IF EXISTS `version`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `version`()
BEGIN
 SELECT version FROM db_info ORDER BY id DESC LIMIT 1;
END $$
DELIMITER ;

START TRANSACTION;
INSERT INTO `db_info`(version) VALUES (3);
COMMIT;

-- *****************************************************************************
--
-- GMNG v4
--
-- *****************************************************************************

DROP VIEW IF EXISTS nav_data_v;

START TRANSACTION;
 INSERT INTO `db_info`(version) VALUES (4);
COMMIT;

-- *****************************************************************************
--
-- GMNG v5
--
-- *****************************************************************************

-- Create table for Audit purpose.
CREATE TABLE IF NOT EXISTS `audit_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(255) NOT NULL,
  `action` enum('insert','update','delete') NOT NULL,
  `affected_table` varchar(20) NOT NULL,
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `comment` varchar(255) NULL,
  PRIMARY KEY (`id`) USING BTREE
) ROW_FORMAT=COMPRESSED;

-- Audit trxs for table dev_types.
DROP TRIGGER IF EXISTS `dev_types_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `dev_types_after_insert_trx` AFTER INSERT ON `dev_types` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'dev_types', CONCAT('add new device type=', NEW.description));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `dev_types_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `dev_types_after_update_trx` AFTER UPDATE ON `dev_types` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'dev_types', CONCAT('update device old type=', OLD.type, ', old description=', OLD.description, ',  old default_port=', OLD.default_port, ' to new  type=', NEW.type, ', new description=', NEW.description, ', new default_port=', NEW.default_port));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `dev_types_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `dev_types_after_delete_trx` AFTER DELETE ON `dev_types` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'dev_types', CONCAT('delete device type=', OLD.description));
END $$
DELIMITER ;

-- Audit trxs for table dev_info.
DROP TRIGGER IF EXISTS `dev_info_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `dev_info_after_insert_trx` AFTER INSERT ON `dev_info` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'dev_info', CONCAT('add object id=', NEW.dev_id));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `dev_info_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `dev_info_after_update_trx` AFTER UPDATE ON `dev_info` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'dev_info', CONCAT('update object old id=', OLD.dev_id, ', old type=', OLD.type, ', old nav_data_validity=', OLD.nav_data_validity, ', old port_num=', OLD.port_num,', old  timeout=', OLD.timeout, ' to new id=', NEW.dev_id, ', new type=', NEW.type,', new nav_data_validity=', NEW.nav_data_validity, ', new port_num=', NEW.port_num, ', new timeout=', NEW.timeout));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `dev_info_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `dev_info_after_delete_trx` AFTER DELETE ON `dev_info` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'dev_info', CONCAT('delete object id=', OLD.dev_id));
END $$
DELIMITER ;

-- Audit trxs for table terminal_accounts.
DROP TRIGGER IF EXISTS `terminal_accounts_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_after_insert_trx` AFTER INSERT ON `terminal_accounts` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'terminal_accounts', CONCAT('add terminal login=', NEW.login));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `terminal_accounts_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_after_update_trx` AFTER UPDATE ON `terminal_accounts` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'terminal_accounts', CONCAT('update terminal old login=', OLD.login, ' to new login=', NEW.login));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `terminal_accounts_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_after_delete_trx` AFTER DELETE ON `terminal_accounts` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'terminal_accounts', CONCAT('delete terminal login=', OLD.login));
END $$
DELIMITER ;

-- Audit trxs for table login_map.
DROP TRIGGER IF EXISTS `login_map_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `login_map_after_insert_trx` AFTER INSERT ON `login_map` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'login_map', CONCAT('add mapping for id=', NEW.dev_id, ' to login=', NEW.login));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `login_map_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `login_map_after_update_trx` AFTER UPDATE ON `login_map` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'login_map', CONCAT('update mapping for old id=', OLD.dev_id, ', old login=', OLD.login, ' to new id=', NEW.dev_id, ', new login=', NEW.login));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `login_map_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `login_map_after_delete_trx` AFTER DELETE ON `login_map` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'login_map', CONCAT('delete mapping for id=', OLD.dev_id, ' to login=', OLD.login));
END $$
DELIMITER ;

-- Audit trxs for table init_string.
DROP TRIGGER IF EXISTS `init_string_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `init_string_after_insert_trx` AFTER INSERT ON `init_string` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'init_string', CONCAT('add init for id=', NEW.dev_id, ' to string=', NEW.str));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `init_string_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `init_string_after_update_trx` AFTER UPDATE ON `init_string` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'init_string', CONCAT('update init, for old id=', OLD.dev_id, ', old string=', OLD.str, ' to new id=', NEW.dev_id, ', new string=', NEW.str));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `init_string_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `init_string_after_delete_trx` AFTER DELETE ON `init_string` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'init_string', CONCAT('delete init for id', OLD.dev_id, ' with string=', OLD.str));
END $$
DELIMITER ;

-- Check and update foreign key constaint for cmd_status_codes.op_status on req_status table
DROP PROCEDURE IF EXISTS `tmp_add_cmd_status_codes_ondelete_cascade`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_add_cmd_status_codes_ondelete_cascade`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.REFERENTIAL_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
   AND  CONSTRAINT_NAME = 'req_status_opstatus_fk'
   AND  TABLE_NAME = 'req_status'
   AND UPPER(DELETE_RULE) <> 'CASCADE') THEN
    ALTER TABLE `req_status` DROP FOREIGN KEY `req_status_opstatus_fk`;
    ALTER TABLE `req_status` ADD CONSTRAINT `req_status_opstatus_fk` FOREIGN KEY (`op_status`) REFERENCES `cmd_status_codes` (`op_status`) ON DELETE CASCADE ON UPDATE CASCADE;
 END IF;
END $$
DELIMITER ;
CALL `tmp_add_cmd_status_codes_ondelete_cascade`();
DROP PROCEDURE IF EXISTS `tmp_add_cmd_status_codes_ondelete_cascade`;

--
DROP PROCEDURE IF EXISTS `tmp_add_uniq_index_on_description_for_cmd_status_codes`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_add_uniq_index_on_description_for_cmd_status_codes`() SQL SECURITY INVOKER
BEGIN
 IF NOT EXISTS (SELECT NULL FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'cmd_status_codes'
   AND INDEX_NAME =  'description_cmd_status_codes_idx'
   AND COLUMN_NAME = 'description'
   AND NON_UNIQUE = 0) THEN
   ALTER TABLE `cmd_status_codes` ADD UNIQUE INDEX `description_cmd_status_codes_idx` (`description`) ;
 END IF;
END $$
DELIMITER ;
CALL `tmp_add_uniq_index_on_description_for_cmd_status_codes`();
DROP PROCEDURE IF EXISTS `tmp_add_uniq_index_on_description_for_cmd_status_codes`;

START TRANSACTION;
 INSERT INTO `db_info`(version) VALUES (5);
COMMIT;

-- *****************************************************************************
--
-- GMNG v6
--
-- *****************************************************************************
DROP EVENT IF EXISTS `gmng_cleanup_evt`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` EVENT `gmng_cleanup_evt` ON SCHEDULE EVERY 1 DAY STARTS '2012-01-01 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
  DECLARE rows_to_delete INTEGER;
  DECLARE rows_deleted INTEGER;

  SET rows_deleted = 0;

  SELECT count(*) INTO rows_to_delete FROM nav_data WHERE ADDDATE( DATE(insertion_time), INTERVAL 14 DAY) < CURDATE();

  label1: LOOP
    IF rows_deleted >= rows_to_delete THEN
        LEAVE label1;
    ELSE
      DELETE FROM nav_data WHERE ADDDATE( DATE(insertion_time), INTERVAL 14 DAY) < CURDATE() LIMIT 100000;
      SET rows_deleted = rows_deleted + 100000;
    END IF;
  END LOOP label1;

  DELETE FROM gmng.req WHERE ADDDATE(DATE(insertion_time), INTERVAL 14 DAY) < CURDATE();
END $$
DELIMITER ;

-- Remove nav_data_recnum_devid_idx
DROP PROCEDURE IF EXISTS `tmp_drop_nav_data_recnum_devid_idx`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_drop_nav_data_recnum_devid_idx`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'nav_data'
   AND INDEX_NAME = 'recnum_devid_idx') THEN
    ALTER TABLE `nav_data` DROP INDEX `recnum_devid_idx`;
 END IF;
END $$
DELIMITER ;
CALL `tmp_drop_nav_data_recnum_devid_idx`();
DROP PROCEDURE IF EXISTS `tmp_drop_nav_data_recnum_devid_idx`;

START TRANSACTION;
 INSERT INTO `db_info`(version) VALUES (6);
COMMIT;

-- *****************************************************************************
--
-- GMNG v7
--
-- *****************************************************************************

DROP PROCEDURE IF EXISTS `select_live_point`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_live_point`(IN point_date TIMESTAMP)
BEGIN
 SELECT MAX(ND.rec_num) rec_num
 FROM nav_data ND
 JOIN login_map MAP
 USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.insertion_time<=point_date;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS `select_live_point_ex`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `select_live_point_ex`(`last_livepoint` bigint unsigned) RETURNS bigint(20) unsigned READS SQL DATA
BEGIN
 DECLARE is_login_empty INT;
 DECLARE livepoint BIGINT UNSIGNED;
 DECLARE ilivepoint BIGINT UNSIGNED;

 SELECT count(*)
 INTO is_login_empty
 FROM login_map
 WHERE
 login = substring(user(),1,locate('@',user())-1) ;

 SELECT MAX(rec_num) INTO ilivepoint FROM nav_data;

 IF is_login_empty = 0 THEN
   SET livepoint = ilivepoint;
 ELSE
  SELECT MAX(ND.rec_num) rec_num INTO livepoint
  FROM nav_data ND
  JOIN login_map MAP USING (dev_id)
  WHERE
  rec_num > last_livepoint
  AND
  MAP.login=substring(user(),1,locate('@',user())-1);
  IF livepoint IS NULL OR livepoint <= last_livepoint THEN
   SET livepoint = ilivepoint;
  ELSE
   RETURN livepoint;
  END IF;
 END IF;
 RETURN livepoint;
END $$
DELIMITER ;

START TRANSACTION;
INSERT INTO `db_info`(version) VALUES (7);
COMMIT;

-- *****************************************************************************
--
-- GMNG v8
--
-- *****************************************************************************
ALTER TABLE `cmd_status_codes`
MODIFY COLUMN `description`  enum('CMD_PROCESSED','CMD_PULLED','CMD_OK','CMD_FAIL','CMD_TIMEOUT','CMD_CANCEL','CMD_FAIL_PASS_TO_CALLBACK','CMD_RECEIVED') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL AFTER `op_status`;
INSERT INTO cmd_status_codes (op_status, description) VALUES (5, 'CMD_CANCEL');
INSERT INTO cmd_status_codes (op_status, description) VALUES (6, 'CMD_FAIL_PASS_TO_CALLBACK');
INSERT INTO cmd_status_codes (op_status, description) VALUES (7, 'CMD_RECEIVED');

DROP TABLE IF EXISTS req_serviced;

DROP PROCEDURE IF EXISTS `insert_req`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_req`(devid VARCHAR(32), cmdid INTEGER, cmdguid CHAR(38), trmguid CHAR(38), intparam1 INTEGER, intparam2 INTEGER, intparam3 INTEGER, intparam4 INTEGER, intparam5 INTEGER, intparam6 INTEGER, strparam1 VARCHAR(128), strparam2 VARCHAR(128), dtparam1 INT UNSIGNED, dtparam2 INT UNSIGNED)
proc_label: BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE recnum INT UNSIGNED;
DECLARE active_requests INT;

DECLARE cur1 CURSOR FOR
 SELECT rqiv.rec_num FROM req_in_v  rqiv JOIN login_map lm USING (dev_id)
  WHERE lm.login=substring(user(),1,locate('@',user())-1)
    AND rqiv.dev_id =  devid
    AND rqiv.rec_num NOT IN (SELECT DISTINCT rec_num FROM req_status);

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;

 IF (cmdid = 490) THEN
   OPEN cur1;

   read_loop: LOOP
     FETCH cur1 INTO recnum;

     IF done THEN
       LEAVE read_loop;
     END IF;

     INSERT INTO req_status (rec_num, op_status) VALUES (recnum, 5);
     DELETE FROM req_in WHERE rec_num = recnum;
   END LOOP;

   CLOSE cur1;

   SELECT COUNT(rqiv.rec_num) INTO active_requests FROM req_in_v rqiv JOIN login_map lm USING (dev_id)
     WHERE lm.login=substring(user(),1,locate('@',user())-1) AND rqiv.dev_id =  devid;

   IF (active_requests = 0) THEN
     IF EXISTS (SELECT NULL FROM login_map WHERE login = substring(user(),1,locate('@',user())-1) AND dev_id =  devid) THEN
       INSERT INTO req (dev_id, cmd_id, cmd_guid, trm_guid, param1, param2, param3, param4, param5, param6, str1, str2, datetime1, datetime2)
         VALUES (devid, cmdid, cmdguid, trmguid,    intparam1, intparam2, intparam3, intparam4, intparam5, intparam6, strparam1, strparam2, dtparam1, dtparam2);
       INSERT INTO req_status(rec_num, op_status) VALUES (LAST_INSERT_ID(),7);
     ELSE
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unathorized req post detected';
     END IF;
     COMMIT;
     LEAVE proc_label;
   END IF;
 END IF; -- cmdid

 IF EXISTS (SELECT NULL FROM login_map WHERE login = substring(user(),1,locate('@',user())-1) AND dev_id =  devid) THEN
   INSERT INTO req (dev_id, cmd_id, cmd_guid, trm_guid, param1, param2, param3, param4, param5, param6, str1, str2, datetime1, datetime2)
     VALUES (devid, cmdid, cmdguid, trmguid,    intparam1, intparam2, intparam3, intparam4, intparam5, intparam6, strparam1, strparam2, dtparam1, dtparam2);
   INSERT INTO req_in(rec_num) VALUES (LAST_INSERT_ID());
   INSERT INTO req_status(rec_num, op_status) VALUES (LAST_INSERT_ID(),7);
 ELSE
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unathorized req post detected';
 END IF;

COMMIT;
END $$
DELIMITER ;

-- Triggers that prevents violating of login name across mysql.user.
DROP TRIGGER IF EXISTS `terminal_accounts_insert_trx`;
DELIMITER $$
CREATE TRIGGER `terminal_accounts_insert_trx` BEFORE INSERT ON `terminal_accounts` FOR EACH ROW BEGIN
  DECLARE cnt  INT;
  SELECT  COUNT(*)  FROM  mysql.user WHERE User = NEW.login  INTO cnt;
  IF cnt IS NULL OR cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Wrong or unknown sql terminal login name specified';
  END IF;
 END $$
DELIMITER ;

START TRANSACTION;
INSERT INTO `db_info`(version) VALUES (8);
COMMIT;

-- *****************************************************************************
--
-- GMNG v9
--
-- *****************************************************************************

-- drop order by clause due to default ascending order of primary key
DROP PROCEDURE IF EXISTS `select_data_from`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_data_from`(IN from_row BIGINT unsigned)
BEGIN
 SELECT ND.* FROM nav_data ND JOIN login_map MAP USING (dev_id)
 WHERE
 MAP.login=substring(user(),1,locate('@',user())-1) AND
 ND.rec_num>=from_row
 LIMIT 10000;
END $$
DELIMITER ;

CREATE INDEX nd_instime_idx ON nav_data(dev_id,insertion_time);

DROP INDEX devid_idx ON nav_data;

START TRANSACTION;
INSERT INTO `db_info`(version) VALUES (9);
COMMIT;

DELIMITER ;


-- *****************************************************************************
--
-- GMNG v10
--
-- *****************************************************************************

-- restore devid foreign key on nav_data table
ALTER TABLE nav_data DROP foreign key nav_data_devid_fk;
DROP INDEX nd_instime_idx ON nav_data;
ALTER TABLE nav_data ADD CONSTRAINT `nav_data_devid_fk` FOREIGN KEY (`dev_id`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE;

DROP PROCEDURE IF EXISTS `gmng_cleanup_utl`;
delimiter //
CREATE procedure `gmng_cleanup_utl` (IN retaindays INTEGER, IN rows2del INTEGER) MODIFIES SQL DATA SQL SECURITY INVOKER
BEGIN
  DECLARE row_count INTEGER;
  DECLARE rows_deleted INTEGER;

  SET rows_deleted = 0;
  SET row_count = 0;

--  select concat("** ", rows_to_delete) AS '** DEBUG:';

  label1: LOOP
    DELETE FROM `nav_data` WHERE ADDDATE( DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE() order by insertion_time LIMIT rows2del;
    IF ROW_COUNT() = 0 THEN
      LEAVE label1;
    END IF;
  END LOOP label1;

  label2: LOOP
    DELETE FROM `req` WHERE ADDDATE(DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE() order by insertion_time LIMIT rows2del; 
    IF ROW_COUNT() = 0 THEN
      LEAVE label2;
    END IF;
  END LOOP label2;
END //
delimiter ;

DROP event if EXISTS `gmng_cleanup_evt`;
delimiter //
CREATE event `gmng_cleanup_evt` ON SCHEDULE EVERY 1 DAY ENABLE DO
begin
  call `gmng_cleanup_utl`(7, 300000);  
END //
delimiter ;

CREATE INDEX nd_itime_idx ON nav_data(insertion_time);

START TRANSACTION;
INSERT INTO `db_info`(version) VALUES (10);
COMMIT;

-- *****************************************************************************
--
-- GMNG v11
--
-- *****************************************************************************
START TRANSACTION;
-- Remove nd_itime_idx
DROP PROCEDURE IF EXISTS `tmp_drop_nd_itime_idx`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_drop_nd_itime_idx`() SQL SECURITY INVOKER
BEGIN
 IF EXISTS (SELECT NULL FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'nav_data'
   AND INDEX_NAME = 'nd_itime_idx') THEN
    ALTER TABLE `nav_data` DROP INDEX `nd_itime_idx`;
 END IF;
END $$
DELIMITER ;
CALL `tmp_drop_nd_itime_idx`();
DROP PROCEDURE IF EXISTS `tmp_drop_nd_itime_idx`;

CREATE INDEX nd_did_itime_idx ON nav_data(dev_id,insertion_time);
CREATE INDEX nd_ntime_idx ON nav_data(nav_time);  

-- recreate select_data_by_range to be sure it not contains any explicit references to an indexes
DROP PROCEDURE IF EXISTS `select_data_by_range`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_data_by_range`(IN begin_row BIGINT UNSIGNED, IN end_row BIGINT UNSIGNED)
BEGIN
 SELECT ND.*  FROM nav_data ND JOIN login_map MAP USING (dev_id)
 WHERE MAP.login=substring(user(),1,locate('@',user())-1)
 AND ND.rec_num>=begin_row 
 AND ND.rec_num<end_row
 ORDER BY ND.rec_num
 LIMIT 10000;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `read_by_date_range_from`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `read_by_date_range_from`(IN `from_date` DATETIME,IN `to_date` DATETIME)
BEGIN
SELECT MIN(ND.rec_num) rec_num
FROM nav_data ND
JOIN login_map MAP USING (dev_id)
WHERE MAP.login=substring(user(),1,locate('@',user())-1)
AND ND.nav_time BETWEEN from_date AND to_date
AND ND.nav_time <= insertion_time;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `read_by_date_range_to`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `read_by_date_range_to`(IN `from_date` DATETIME,IN `to_date` DATETIME)
BEGIN
SELECT MAX(ND.rec_num) rec_num
FROM nav_data ND
JOIN login_map MAP USING (dev_id)
WHERE MAP.login=substring(user(),1,locate('@',user())-1)
AND ND.nav_time BETWEEN from_date AND to_date
AND ND.nav_time <= insertion_time;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS `gmng_cleanup_utl`;
delimiter //
CREATE procedure `gmng_cleanup_utl` (IN retaindays INTEGER, IN rows2del INTEGER)
MODIFIES SQL DATA
SQL SECURITY INVOKER
BEGIN
  DECLARE row_count INTEGER;
  DECLARE rows_deleted INTEGER;

  SET rows_deleted = 0;
  SET row_count = 0;

--  select concat("** ", rows_to_delete) AS '** DEBUG:';

  label1: LOOP
    DELETE FROM `nav_data` WHERE ADDDATE(DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE() LIMIT rows2del;
    IF ROW_COUNT() = 0 THEN
      LEAVE label1;
    END IF;
  END LOOP label1;

  label2: LOOP
    DELETE FROM `req` WHERE ADDDATE(DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE() LIMIT rows2del; 
    IF ROW_COUNT() = 0 THEN
      LEAVE label2;
    END IF;
  END LOOP label2;
END //
delimiter ;

INSERT INTO `db_info`(version) VALUES (11);

COMMIT;

-- *****************************************************************************
--
-- GMNG v12
--
-- *****************************************************************************
START TRANSACTION;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `gmng_cleanup_utl`(IN retaindays INTEGER, IN rows2del INTEGER)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
  DECLARE row_count INTEGER;
  DECLARE rows_deleted INTEGER;
  DECLARE pos bigint unsigned;

  SET rows_deleted = 0;
  SET row_count = 0;
  
  SELECT max(rec_num) INTO pos FROM `nav_data` WHERE ADDDATE( DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE();

  label1: LOOP
    DELETE FROM `nav_data` WHERE ADDDATE( DATE(nav_time), INTERVAL retaindays DAY) < CURDATE()
    AND rec_num <= pos LIMIT rows2del;
    IF ROW_COUNT() = 0 THEN
      LEAVE label1;
    END IF;
  END LOOP label1;

  label2: LOOP
    DELETE FROM `req` WHERE ADDDATE(DATE(insertion_time), INTERVAL retaindays DAY) < CURDATE() LIMIT rows2del; 
    IF ROW_COUNT() = 0 THEN
      LEAVE label2;
    END IF;
  END LOOP label2;
END $$
DELIMITER ;

ALTER event gmng_cleanup_evt ON SCHEDULE EVERY 1 DAY STARTS '2022-04-28 00:00:00' ENABLE DO call `gmng_cleanup_utl`(20, 300000);
DROP PROCEDURE IF EXISTS select_data_from;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `select_data_from`(IN from_row BIGINT unsigned)
BEGIN
 SELECT
   ND.* FROM nav_data ND USE INDEX (PRIMARY) 
 JOIN
   login_map MAP USING (dev_id)
 WHERE
   MAP.login=substring(user(),1,locate('@',user())-1) 
   AND ND.rec_num>=from_row
 ORDER BY
   ND.rec_num
 LIMIT
  10000;
END $$
DELIMITER ;

INSERT INTO `db_info`(version) VALUES (12);
COMMIT;

-- *****************************************************************************
--
-- GMNG v13 (MySQL 8.x and later)
--
-- *****************************************************************************
-- create predefined roles
-- START TRANSACTION;
-- CREATE role IF NOT EXISTS sql_terminal_role;
-- GRANT EXECUTE ON gmng.* TO sql_terminal_role;

-- CREATE role IF NOT EXISTS parser_role;
-- GRANT INSERT ON gmng.nav_data TO parser_role;
-- GRANT SELECT ON gmng.* TO parser_role;
-- GRANT DELETE ON gmng.req_in TO parser_role;
-- GRANT INSERT ON gmng.req_status TO parser_role;
-- GRANT SELECT,INSERT,UPDATE ON gmng.dev_activity TO parser_role;
-- COMMIT;

-- START TRANSACTION;
-- INSERT INTO `db_info`(version) VALUES (12);
-- COMMIT;

-- TODO: Change int parameters type to bigint unsigned to prevent nav_data primary key overflow

-- =============================================================================
-- ========================== CLEANUP STAGE ====================================
-- =============================================================================
-- Tmp proc. cleanup stage.
SET group_concat_max_len = 1024 * 1024 * 10;
DROP PROCEDURE IF EXISTS `tmp_cleanup`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_cleanup`() SQL SECURITY INVOKER
BEGIN
 SELECT CONCAT('DROP TABLE IF EXISTS ',GROUP_CONCAT(CONCAT(table_schema,'.',table_name)),';')
  INTO @dropcmd FROM information_schema.tables
  WHERE table_schema=DATABASE()
  AND table_name LIKE 'tmp_%';
  IF @dropcmd IS NOT NULL THEN
   PREPARE query FROM @dropcmd;
   EXECUTE query;
   DEALLOCATE PREPARE query;
  END IF;
END $$
DELIMITER ;
CALL `tmp_cleanup`();
DROP PROCEDURE IF EXISTS `tmp_cleanup`;
