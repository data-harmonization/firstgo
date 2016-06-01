-- +migrate Up
CREATE TABLE IF NOT EXISTS `myservice`.`template`(
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL,
  `body` text NOT NULL,
  
  `created_by` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP(),

  PRIMARY KEY(`id`),
  UNIQUE KEY `uuid_UNIQUE` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- +migrate Down
DROP TABLE `myservice`.`template`;
