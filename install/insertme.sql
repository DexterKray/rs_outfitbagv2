CREATE TABLE IF NOT EXISTS `user_outfits` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `skin` LONGTEXT NOT NULL,
    PRIMARY KEY (`id`)
);
