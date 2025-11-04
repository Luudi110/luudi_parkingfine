-- Opret tabel til lagring af parkeringsbøder
CREATE TABLE IF NOT EXISTS `luudi_parkingfines` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL COMMENT 'Target spillerens identifier (steam:xxxxx)',
    `issuer` VARCHAR(64) NOT NULL COMMENT 'Politi-betjentens identifier',
    `issuer_name` VARCHAR(128) DEFAULT NULL COMMENT 'Politi-betjentens navn',
    `vehicle_plate` VARCHAR(16) DEFAULT NULL COMMENT 'Køretøjets nummerplade',
    `amount` INT NOT NULL COMMENT 'Bødebeløb',
    `reason` TEXT DEFAULT NULL COMMENT 'Årsag til bøden',
    `paid` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0 = ubetalt, 1 = betalt',
    `auto_deducted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0 = manuel betaling, 1 = auto-trukket',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tidspunkt for udstedelse',
    `paid_at` DATETIME DEFAULT NULL COMMENT 'Tidspunkt for betaling',
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
