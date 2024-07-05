-- MySQL dump 10.13  Distrib 8.4.0, for Linux (x86_64)
--
-- Host: localhost    Database: mydb
-- ------------------------------------------------------
-- Server version	8.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `machines`
--

DROP TABLE IF EXISTS `machines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `machines` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ownerUser` varchar(255) DEFAULT NULL,
  `lastUpdate` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `machineType` varchar(255) DEFAULT NULL,
  `machineID` varchar(255) DEFAULT NULL,
  `devirmeYuruyusSecim` varchar(255) DEFAULT NULL,
  `calismaSekli` varchar(255) DEFAULT NULL,
  `emniyetCercevesi` varchar(255) DEFAULT NULL,
  `yavaslamaLimit` varchar(255) DEFAULT NULL,
  `altLimit` varchar(255) DEFAULT NULL,
  `kapiTablaAcKonum` varchar(255) DEFAULT NULL,
  `basincSalteri` varchar(255) DEFAULT NULL,
  `kapiSecimler` varchar(255) DEFAULT NULL,
  `kapiAcTipi` varchar(255) DEFAULT NULL,
  `kapi1Tip` varchar(255) DEFAULT NULL,
  `kapi1AcSure` varchar(255) DEFAULT NULL,
  `kapi2Tip` varchar(255) DEFAULT NULL,
  `kapi2AcSure` varchar(255) DEFAULT NULL,
  `kapitablaTip` varchar(255) DEFAULT NULL,
  `kapiTablaAcSure` varchar(255) DEFAULT NULL,
  `yukariYavasLimit` varchar(255) DEFAULT NULL,
  `devirmeYukariIleriLimit` varchar(255) DEFAULT NULL,
  `devirmeAsagiGeriLimit` varchar(255) DEFAULT NULL,
  `devirmeSilindirTipi` varchar(255) DEFAULT NULL,
  `platformSilindirTipi` varchar(255) DEFAULT NULL,
  `yukariValfTmr` varchar(255) DEFAULT NULL,
  `asagiValfTmr` varchar(255) DEFAULT NULL,
  `devirmeYukariIleriTmr` varchar(255) DEFAULT NULL,
  `devirmeAsagiGeriTmr` varchar(255) DEFAULT NULL,
  `makineCalismaTmr` varchar(255) DEFAULT NULL,
  `buzzer` varchar(255) DEFAULT NULL,
  `demoMode` varchar(255) DEFAULT NULL,
  `calismaSayisi1` varchar(255) DEFAULT NULL,
  `calismaSayisi10` varchar(255) DEFAULT NULL,
  `calismaSayisi100` varchar(255) DEFAULT NULL,
  `calismaSayisi10000` varchar(255) DEFAULT NULL,
  `dilSecim` varchar(255) DEFAULT NULL,
  `eepromData38` varchar(255) DEFAULT NULL,
  `eepromData39` varchar(255) DEFAULT NULL,
  `eepromData40` varchar(255) DEFAULT NULL,
  `eepromData41` varchar(255) DEFAULT NULL,
  `eepromData42` varchar(255) DEFAULT NULL,
  `eepromData43` varchar(255) DEFAULT NULL,
  `eepromData44` varchar(255) DEFAULT NULL,
  `eepromData45` varchar(255) DEFAULT NULL,
  `eepromData46` varchar(255) DEFAULT NULL,
  `eepromData47` varchar(255) DEFAULT NULL,
  `lcdBacklightSure` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `maintenances`
--

DROP TABLE IF EXISTS `maintenances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `maintenances` (
  `maintenanceID` int NOT NULL AUTO_INCREMENT,
  `machineID` int NOT NULL,
  `technician` varchar(255) NOT NULL,
  `maintenanceDate` datetime NOT NULL,
  `kontrol11` varchar(255) NOT NULL,
  `kontrol12` varchar(255) DEFAULT NULL,
  `kontrol13` varchar(255) DEFAULT NULL,
  `kontrol14` varchar(255) DEFAULT NULL,
  `kontrol21` varchar(255) DEFAULT NULL,
  `kontrol22` varchar(255) DEFAULT NULL,
  `kontrol23` varchar(255) DEFAULT NULL,
  `kontrol24` varchar(255) DEFAULT NULL,
  `kontrol31` varchar(255) DEFAULT NULL,
  `kontrol32` varchar(255) DEFAULT NULL,
  `kontrol33` varchar(255) DEFAULT NULL,
  `kontrol34` varchar(255) DEFAULT NULL,
  `kontrol35` varchar(255) DEFAULT NULL,
  `kontrol36` varchar(255) DEFAULT NULL,
  `kontrol41` varchar(255) DEFAULT NULL,
  `kontrol42` varchar(255) DEFAULT NULL,
  `kontrol43` varchar(255) DEFAULT NULL,
  `kontrol44` varchar(255) DEFAULT NULL,
  `kontrol45` varchar(255) DEFAULT NULL,
  `kontrol46` varchar(255) DEFAULT NULL,
  `kontrol51` varchar(255) DEFAULT NULL,
  `kontrol52` varchar(255) DEFAULT NULL,
  `kontrol53` varchar(255) DEFAULT NULL,
  `kontrol54` varchar(255) DEFAULT NULL,
  `kontrol55` varchar(255) DEFAULT NULL,
  `kontrol61` varchar(255) DEFAULT NULL,
  `kontrol62` varchar(255) DEFAULT NULL,
  `kontrol63` varchar(255) DEFAULT NULL,
  `kontrol71` varchar(255) DEFAULT NULL,
  `kontrol72` varchar(255) DEFAULT NULL,
  `kontrol81` varchar(255) DEFAULT NULL,
  `kontrol82` varchar(255) DEFAULT NULL,
  `kontrol83` varchar(255) DEFAULT NULL,
  `kontrol91` varchar(255) DEFAULT NULL,
  `kontrol92` varchar(255) DEFAULT NULL,
  `kontrol93` varchar(255) DEFAULT NULL,
  `kontrol94` varchar(255) DEFAULT NULL,
  `kontrol95` varchar(255) DEFAULT NULL,
  `kontrol96` varchar(255) DEFAULT NULL,
  `kontrol97` varchar(255) DEFAULT NULL,
  `kontrol98` varchar(255) DEFAULT NULL,
  `kontrol99` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`maintenanceID`),
  KEY `machineID` (`machineID`),
  CONSTRAINT `maintenances_ibfk_1` FOREIGN KEY (`machineID`) REFERENCES `machines` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-06-28 14:44:16
