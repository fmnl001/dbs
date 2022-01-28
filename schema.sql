-- v.1 Initial
CREATE TABLE IF NOT EXISTS relay_schema_version (
`version` int NOT NULL,
`description` varchar(128),
`mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`version`) USING BTREE
) ENGINE=InnoDB;

CREATE TABLE `egts_repl_endpoints` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `endpoint_addr` varchar(255) NOT NULL,
  `endpoint_port` int(10) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `endpoint_joint_idx` (`endpoint_addr`,`endpoint_port`) USING BTREE
) ENGINE=InnoDB;

CREATE TABLE `egts_repl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `active` int(1) NOT NULL,
  `id4relay` varchar(32) DEFAULT NULL,
  `id2relay` varchar(32) DEFAULT NULL,
  `relay2addr` int(10) unsigned NOT NULL,
  `relay_position` bigint(20) unsigned DEFAULT NULL,
  `mtime` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dev_id` (`id4relay`,`relay2addr`),
  KEY `egts_repl_relay2addr_fk` (`relay2addr`),
  CONSTRAINT `egts_repl_devid_fk` FOREIGN KEY (`id4relay`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `egts_repl_relay2addr_fk` FOREIGN KEY (`relay2addr`) REFERENCES `egts_repl_endpoints` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `wips_repl_endpoints` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `endpoint_addr` varchar(255) NOT NULL,
  `endpoint_port` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `endpoint_joint_idx` (`endpoint_addr`,`endpoint_port`) USING BTREE
) ENGINE=InnoDB;

CREATE TABLE `wips_repl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `active` int(11) NOT NULL,
  `id4relay` varchar(32) NOT NULL,
  `id2relay` varchar(32) NOT NULL,
  `relay2addr` int(10) unsigned NOT NULL,
  `relay_position` bigint(20) unsigned DEFAULT NULL,
  `mtime` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dev_id` (`id4relay`,`relay2addr`),
  KEY `wips_repl_relay2addr_fk` (`relay2addr`),
  CONSTRAINT `wips_repl_devid_fk` FOREIGN KEY (`id4relay`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `wips_repl_relay2addr_fk` FOREIGN KEY (`relay2addr`) REFERENCES `wips_repl_endpoints` (`id`)
) ENGINE=InnoDB;

CREATE USER 'egtsrelay'@'%' IDENTIFIED WITH 'mysql_native_password' AS '*793DE35932225778FCC3BB264FEDA72369717BE4';
GRANT USAGE ON *.* TO 'egtsrelay'@'%';
GRANT SELECT ON `gmng`.`dev_info` TO 'egtsrelay'@'%';
GRANT SELECT, UPDATE ON `gmng`.`egts_repl` TO 'egtsrelay'@'%';
GRANT SELECT ON `gmng`.`egts_repl_endpoints` TO 'egtsrelay'@'%';
GRANT SELECT ON `gmng`.`nav_data` TO 'egtsrelay'@'%';

CREATE USER 'wipsrelay'@'%' IDENTIFIED WITH 'mysql_native_password' AS '*D413FAF3703F59A28CDDD580D4D29B3F06403A84';
GRANT USAGE ON *.* TO 'wipsrelay'@'%';
GRANT SELECT ON `gmng`.`dev_info` TO 'wipsrelay'@'%';
GRANT SELECT, UPDATE ON `gmng`.`wips_repl` TO 'wipsrelay'@'%';
GRANT SELECT ON `gmng`.`wips_repl_endpoints` TO 'wipsrelay'@'%';
GRANT SELECT ON `gmng`.`nav_data` TO 'wipsrelay'@'%';

INSERT INTO relay_schema_version(version, description) VALUES (1, 'initial creation');

-- v.2 Transient to normalized
alter table egts_repl add column id_map int(11) not null after id2relay;
alter table wips_repl add column id_map int(11) not null after id2relay;

CREATE TABLE `relay_id_map` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id4relay` varchar(32) NOT NULL,
  `id2relay` varchar(32) NOT NULL,
  `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rim_id_map_key` (`id4relay`,`id2relay`),
  CONSTRAINT `rim_devid_fk` FOREIGN KEY (`id4relay`) REFERENCES `dev_info` (`dev_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

ALTER TABLE `egts_repl` ADD CONSTRAINT `egts_repl_id_map_fk` FOREIGN KEY (`id_map`) REFERENCES `relay_id_map` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `wips_repl` ADD CONSTRAINT `wips_repl_id_map_fk` FOREIGN KEY (`id_map`) REFERENCES `relay_id_map` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

GRANT SELECT ON relay_id_map to egtsrelay;
GRANT SELECT ON relay_id_map to wipsrelay;

GRANT SELECT ON `gmng`.`relay_id_map` TO 'egtsrelay'@'%';
GRANT SELECT ON `gmng`.`relay_id_map` TO 'wipsrelay'@'%';

INSERT INTO relay_schema_version(version, description) values (2, 'transient to normalize id relation');

-- v.3 Normalized
ALTER TABLE `egts_repl` DROP FOREIGN KEY `egts_repl_devid_fk`;
ALTER TABLE `egts_repl` DROP KEY `dev_id`;
ALTER TABLE `egts_repl` DROP COLUMN `id4relay`;
ALTER TABLE `egts_repl` DROP COLUMN `id2relay`;
CREATE UNIQUE INDEX idmap_relay2addr_idx ON egts_repl(id_map, relay2addr);

ALTER TABLE `wips_repl` DROP FOREIGN KEY `wips_repl_devid_fk`;
ALTER TABLE `wips_repl` DROP KEY `dev_id`;
ALTER TABLE `wips_repl` DROP COLUMN `id4relay`;
ALTER TABLE `wips_repl` DROP COLUMN `id2relay`;

CREATE UNIQUE INDEX wips_idmap_relay2addr_idx ON wips_repl(id_map, relay2addr);

alter table egts_repl alter active set default 1;
alter table wips_repl alter active set default 1;

delimiter $$
create procedure `create_egts_relay` (
 IN `id4` VARCHAR(255),
 IN `id2` VARCHAR(255),
 IN `relay_ep_id` INT,
 IN `only_actual` TINYINT(1))
begin
declare id_map INT(11);
declare relay_pos bigint(20) unsigned;

set relay_pos = NULL;
set only_actual = IFNULL(only_actual, 0);

select id into id_map from relay_id_map where id4relay = id4 and id2relay = id2;
if (id_map is null) then
  insert into relay_id_map (id4relay, id2relay) values (id4, id2);
  select LAST_INSERT_ID() into id_map;
end if;

if only_actual <> 0 then
  select max(rec_num) into relay_pos from nav_data where dev_id = id4;
end if;

if (relay_pos is null) then
  insert into egts_repl (id_map,  relay2addr) values (id_map, relay_ep_id);
else 
  insert into egts_repl (id_map,  relay2addr, relay_position) values (id_map, relay_ep_id, relay_pos);
end if;
end $$
delimiter ;


delimiter $$
create procedure `create_wips_relay` (
 IN `id4` VARCHAR(255),
 IN `id2` VARCHAR(255),
 IN `relay_ep_id` INT,
 IN `only_actual` TINYINT(1))
begin
declare id_map INT(11);
declare relay_pos bigint(20) unsigned;

set relay_pos = NULL;
set only_actual = IFNULL(only_actual, 0);

select id into id_map from relay_id_map where id4relay = id4 and id2relay = id2;
if (id_map is null) then
  insert into relay_id_map (id4relay, id2relay) values (id4, id2);
  select LAST_INSERT_ID() into id_map;
end if;  

if only_actual <> 0 then
  select max(rec_num) into relay_pos from nav_data where dev_id = id4;
end if;

if (relay_pos is null) then
  insert into wips_repl (id_map,  relay2addr) values (id_map, relay_ep_id);
else 
  insert into wips_repl (id_map,  relay2addr, relay_position) values (id_map, relay_ep_id, relay_pos);
end if;
end $$
delimiter ;

alter table `egts_repl` modify column `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
alter table `wips_repl` modify column `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

alter table egts_repl_endpoints add skip_auth TINYINT(1) AFTER endpoint_port;
alter table egts_repl_endpoints add  column `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER skip_auth;
alter table wips_repl_endpoints add  column `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER endpoint_port;

create table egts_repl_config (
  `id` int(11) NOT NULL ,
  `skip_auth` TINYINT(1) default 0,
   CONSTRAINT `egts_repl_config_id_fk` FOREIGN KEY (`id`) REFERENCES `egts_repl` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Audit trxs for table egts_repl_endpoints
DROP TRIGGER IF EXISTS `egts_repl_endpoints_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_endpoints_after_insert_trx` AFTER INSERT ON `egts_repl_endpoints` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'egts_repl',
	 CONCAT('add replication endpoint: endpoint_addr=',NEW.endpoint_addr,', endpoint_port=',NEW.endpoint_port,', description=',NEW.description));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `egts_repl_endpoints_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_endpoints_after_update_trx` AFTER UPDATE ON `egts_repl_endpoints` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'egts_repl',
	 CONCAT('update replication endpoint: old endpoint_addr=',OLD.endpoint_addr,', new endpoint_addr=',NEW.endpoint_addr,', old endpoint_port=',OLD.endpoint_port,', new endpoint_port=',NEW.endpoint_port,', old description=',OLD.description,', new description=',NEW.description));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `egts_repl_endpoints_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_endpoints_after_delete_trx` AFTER DELETE ON `egts_repl_endpoints` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'egts_repl',
	 CONCAT('delete replication endpoint: endpoint_addr=',OLD.endpoint_addr,', endpoint_port=',OLD.endpoint_port,', description=',OLD.description));
END $$
DELIMITER ;

-- Audit trxs for table egts_repl
DROP TRIGGER IF EXISTS `egts_repl_after_insert_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_after_insert_trx` AFTER INSERT ON `egts_repl` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'insert', 'egts_repl',
	 CONCAT('add replication object: id4relay=',NEW.id4relay,', id2relay=',NEW.id2relay,', relay2addr=',NEW.relay2addr,', relay_position=',NEW.relay_position,', active=',NEW.active));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `egts_repl_after_update_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_after_update_trx` AFTER UPDATE ON `egts_repl` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'update', 'egts_repl',
	 CONCAT('update replication object: old id4relay=',OLD.id4relay,', new id4relay=',NEW.id4relay,', old id2relay=',OLD.id2relay,', new id2relay=',NEW.id2relay,', old relay2addr=',OLD.relay2addr,', new relay2addr=',NEW.relay2addr,', old relay_position=',OLD.relay_position,', new relay_position=',NEW.relay_position,', old active=',OLD.active,', new active=',NEW.active));
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS `egts_repl_after_delete_trx`;
DELIMITER $$
CREATE TRIGGER `egts_repl_after_delete_trx` AFTER DELETE ON `egts_repl` FOR EACH ROW BEGIN
  INSERT INTO audit_log (`login`, `action`, `affected_table`, `comment`)
  VALUES (USER(), 'delete', 'egts_repl',
	 CONCAT('delete replication object: id4relay=',OLD.id4relay,', id2relay=',OLD.id2relay,', relay2addr=',OLD.relay2addr,', relay_position=',OLD.relay_position,', active=',OLD.active));
END $$
DELIMITER ;

INSERT INTO `relay_schema_version` (version, description) VALUES (3, 'normalized id relation');

-- v.4 Unified
CREATE TABLE `relay_out_type` (
  `type` int(11) NOT NULL AUTO_INCREMENT,
  `description` ENUM ('EGTS,WIPS') NOT NULL,  
  `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`type`)
) ENGINE=InnoDB;

INSERT INTO `relay_schema_version` (version, description) VALUES (4, 'unify');
