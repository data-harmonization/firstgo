SET SQL_SAFE_UPDATES = 0; -- you need this to delete without WHERE clause
ALTER TABLE `template` AUTO_INCREMENT = 1;

DELETE FROM `template`;

-- core attribute keys
INSERT INTO `template` VALUES (1,'3418826a-267b-11e6-8c65-0242ac120003','Basic Email','Message: {{.Message}}','jbelfort@acc.schubergphilis.com',now(),now());
