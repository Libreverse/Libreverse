
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `account_active_session_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_active_session_keys` (
  `account_id` bigint NOT NULL,
  `session_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `last_use` datetime(6) NOT NULL,
  UNIQUE KEY `index_account_active_session_keys_on_account_id_and_session_id` (`account_id`,`session_id`),
  UNIQUE KEY `index_account_active_session_keys_on_session_id` (`session_id`),
  CONSTRAINT `fk_rails_cdedf5be2c` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `account_login_change_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_login_change_keys` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `login` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deadline` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `fk_rails_18962144a4` FOREIGN KEY (`id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `account_password_reset_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_password_reset_keys` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deadline` datetime(6) NOT NULL,
  `email_last_sent` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `fk_rails_ccaeb37cea` FOREIGN KEY (`id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `account_remember_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_remember_keys` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deadline` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `fk_rails_9b2f6d8501` FOREIGN KEY (`id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `account_verification_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_verification_keys` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requested_at` datetime(6) NOT NULL,
  `email_last_sent` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `fk_rails_2e3b612008` FOREIGN KEY (`id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `status` int NOT NULL DEFAULT '1',
  `username` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `password_changed_at` datetime(6) DEFAULT NULL,
  `guest` tinyint(1) DEFAULT '0',
  `admin` tinyint(1) NOT NULL DEFAULT '0',
  `federated_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `provider` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `provider_uid` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_accounts_on_username` (`username`),
  KEY `index_accounts_on_admin` (`admin`),
  KEY `index_accounts_on_federated_id` (`federated_id`),
  UNIQUE KEY `index_accounts_on_provider_and_provider_uid` (`provider`,`provider_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30001;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `action_mailbox_inbound_emails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `action_mailbox_inbound_emails` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `status` int NOT NULL DEFAULT '0',
  `message_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message_checksum` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_action_mailbox_inbound_emails_uniqueness` (`message_id`,`message_checksum`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_hashcash_stamps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_hashcash_stamps` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `version` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bits` int NOT NULL,
  `date` date NOT NULL,
  `resource` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ext` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rand` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `counter` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `request_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `context` json DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_active_hashcash_stamps_on_ip_address_and_created_at` (`ip_address`,`created_at`),
  UNIQUE KEY `index_active_hashcash_stamps_unique` (`counter`,`rand`,`date`,`resource`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_attachments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_id` bigint NOT NULL,
  `blob_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_active_storage_attachments_on_blob_id` (`blob_id`),
  UNIQUE KEY `index_active_storage_attachments_uniqueness` (`record_type`,`record_id`,`name`,`blob_id`),
  CONSTRAINT `fk_rails_c3b3935057` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_blobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_blobs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `filename` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metadata` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `service_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `byte_size` bigint NOT NULL,
  `checksum` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_active_storage_blobs_on_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_variant_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_variant_records` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `blob_id` bigint NOT NULL,
  `variation_digest` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_active_storage_variant_records_uniqueness` (`blob_id`,`variation_digest`),
  CONSTRAINT `fk_rails_993965df05` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocked_domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_domains` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `blocked_at` datetime(6) NOT NULL,
  `blocked_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_blocked_domains_on_domain` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocked_experiences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_experiences` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `activitypub_uri` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `blocked_at` datetime(6) NOT NULL,
  `blocked_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_blocked_experiences_on_activitypub_uri` (`activitypub_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `experience_vectors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `experience_vectors` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `experience_id` bigint NOT NULL,
  `vector_data` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `vector_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `generated_at` datetime(6) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_experience_vectors_on_experience_id` (`experience_id`),
  KEY `index_experience_vectors_on_vector_hash` (`vector_hash`),
  KEY `index_experience_vectors_on_generated_at` (`generated_at`),
  CONSTRAINT `fk_rails_d6a6d7b366` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `experiences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `experiences` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `account_id` bigint NOT NULL,
  `approved` tinyint(1) NOT NULL DEFAULT '0',
  `federate` tinyint(1) NOT NULL DEFAULT '1',
  `federated_blocked` tinyint(1) NOT NULL DEFAULT '0',
  `offline_available` tinyint(1) NOT NULL DEFAULT '0',
  `source_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user_created',
  `indexed_content_id` bigint DEFAULT NULL,
  `metaverse_platform` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metaverse_coordinates` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metaverse_metadata` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_experiences_on_account_id` (`account_id`),
  KEY `index_experiences_on_account_id_and_created_at` (`account_id`,`created_at`),
  KEY `index_experiences_on_approved` (`approved`),
  KEY `index_experiences_on_indexed_content_id` (`indexed_content_id`),
  KEY `index_experiences_on_source_type` (`source_type`),
  KEY `index_experiences_on_metaverse_platform` (`metaverse_platform`),
  KEY `index_experiences_on_source_type_and_metaverse_platform` (`source_type`,`metaverse_platform`),
  CONSTRAINT `fk_rails_3898738ded` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_rails_1c00bb2e1b` FOREIGN KEY (`indexed_content_id`) REFERENCES `indexed_contents` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federails_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federails_activities` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `entity_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` bigint NOT NULL,
  `action` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_federails_activities_on_entity` (`entity_type`,`entity_id`),
  KEY `index_federails_activities_on_actor_id` (`actor_id`),
  UNIQUE KEY `index_federails_activities_on_uuid` (`uuid`),
  CONSTRAINT `fk_rails_85ef6259df` FOREIGN KEY (`actor_id`) REFERENCES `federails_actors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federails_actors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federails_actors` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `federated_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `username` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `server` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inbox_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `outbox_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `followers_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `followings_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entity_id` int DEFAULT NULL,
  `entity_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public_key` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `private_key` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `extensions` json DEFAULT NULL,
  `local` tinyint(1) NOT NULL DEFAULT '0',
  `actor_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tombstoned_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_federails_actors_on_federated_url` (`federated_url`),
  UNIQUE KEY `index_federails_actors_on_entity` (`entity_type`,`entity_id`),
  UNIQUE KEY `index_federails_actors_on_uuid` (`uuid`),
  KEY `index_federails_actors_on_tombstoned_at` (`tombstoned_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federails_followings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federails_followings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `actor_id` bigint NOT NULL,
  `target_actor_id` bigint NOT NULL,
  `status` int NOT NULL DEFAULT '0',
  `federated_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_federails_followings_on_actor_id` (`actor_id`),
  KEY `index_federails_followings_on_target_actor_id` (`target_actor_id`),
  UNIQUE KEY `index_federails_followings_on_actor_id_and_target_actor_id` (`actor_id`,`target_actor_id`),
  UNIQUE KEY `index_federails_followings_on_uuid` (`uuid`),
  CONSTRAINT `fk_rails_2e62338faa` FOREIGN KEY (`actor_id`) REFERENCES `federails_actors` (`id`),
  CONSTRAINT `fk_rails_4a2870c181` FOREIGN KEY (`target_actor_id`) REFERENCES `federails_actors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federails_moderation_domain_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federails_moderation_domain_blocks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_federails_moderation_domain_blocks_on_domain` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federails_moderation_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federails_moderation_reports` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `federated_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `federails_actor_id` bigint DEFAULT NULL,
  `object_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `object_id` bigint DEFAULT NULL,
  `resolved_at` datetime(6) DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolution` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_federails_moderation_reports_on_federails_actor_id` (`federails_actor_id`),
  KEY `index_federails_moderation_reports_on_object` (`object_type`,`object_id`),
  CONSTRAINT `fk_rails_a5cda24d4c` FOREIGN KEY (`federails_actor_id`) REFERENCES `federails_actors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `federated_announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `federated_announcements` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `activitypub_uri` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_domain` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `announced_at` datetime(6) NOT NULL,
  `experience_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_federated_announcements_on_activitypub_uri` (`activitypub_uri`),
  KEY `index_federated_announcements_on_source_domain` (`source_domain`),
  KEY `index_federated_announcements_on_announced_at` (`announced_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `indexed_content_vectors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indexed_content_vectors` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `indexed_content_id` bigint NOT NULL,
  `vector_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `generated_at` datetime(6) NOT NULL,
  `content_hash` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `vector_data` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_indexed_content_vectors_on_indexed_content_id` (`indexed_content_id`),
  KEY `index_indexed_content_vectors_on_vector_hash` (`vector_hash`),
  KEY `index_indexed_content_vectors_on_generated_at` (`generated_at`),
  CONSTRAINT `fk_rails_c0de21107e` FOREIGN KEY (`indexed_content_id`) REFERENCES `indexed_contents` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `indexed_contents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indexed_contents` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `source_platform` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `external_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metadata` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coordinates` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_indexed_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_indexed_contents_on_source_platform_and_external_id` (`source_platform`,`external_id`),
  KEY `index_indexed_contents_on_content_type` (`content_type`),
  KEY `index_indexed_contents_on_last_indexed_at` (`last_indexed_at`),
  KEY `index_indexed_contents_on_source_platform` (`source_platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `indexing_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indexing_runs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `indexer_class` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` int NOT NULL DEFAULT '0',
  `configuration` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `items_processed` int DEFAULT '0',
  `items_failed` int DEFAULT '0',
  `started_at` datetime(6) DEFAULT NULL,
  `completed_at` datetime(6) DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_details` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_indexing_runs_on_indexer_class` (`indexer_class`),
  KEY `index_indexing_runs_on_status` (`status`),
  KEY `index_indexing_runs_on_started_at` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `instance_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instance_settings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_instance_settings_on_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `moderation_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moderation_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `field` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `account_id` bigint DEFAULT NULL,
  `violations_data` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_moderation_logs_on_account_id` (`account_id`),
  CONSTRAINT `fk_rails_846bca589a` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `oauth_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_applications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `account_id` bigint DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `homepage_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `redirect_uri` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `client_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `client_secret` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_access_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scopes` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `token_endpoint_auth_method` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grant_types` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `response_types` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `client_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logo_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tos_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `policy_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jwks_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jwks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contacts` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `software_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `software_version` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sector_identifier_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `application_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `initiate_login_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_token_signed_response_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_token_encrypted_response_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_token_encrypted_response_enc` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userinfo_signed_response_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userinfo_encrypted_response_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userinfo_encrypted_response_enc` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_object_signing_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_object_encryption_alg` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_object_encryption_enc` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_uris` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `require_signed_request_object` tinyint(1) DEFAULT NULL,
  `require_pushed_authorization_requests` tinyint(1) NOT NULL DEFAULT '0',
  `dpop_bound_access_tokens` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_auth_subject_dn` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_auth_san_dns` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_auth_san_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_auth_san_ip` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_auth_san_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tls_client_certificate_bound_access_tokens` tinyint(1) DEFAULT '0',
  `post_logout_redirect_uris` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `frontchannel_logout_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `frontchannel_logout_session_required` tinyint(1) DEFAULT '0',
  `backchannel_logout_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `backchannel_logout_session_required` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_oauth_applications_on_client_id` (`client_id`),
  UNIQUE KEY `index_oauth_applications_on_client_secret` (`client_secret`),
  KEY `fk_rails_211c1cecac` (`account_id`),
  CONSTRAINT `fk_rails_211c1cecac` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `oauth_dpop_proofs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_dpop_proofs` (
  `jti` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_use` datetime(6) NOT NULL,
  PRIMARY KEY (`jti`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `oauth_grants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_grants` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `account_id` bigint DEFAULT NULL,
  `oauth_application_id` bigint DEFAULT NULL,
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `refresh_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_in` datetime(6) NOT NULL,
  `redirect_uri` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `revoked_at` datetime(6) DEFAULT NULL,
  `scopes` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `access_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'offline',
  `dpop_jwk` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `code_challenge` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `code_challenge_method` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_code` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_polled_at` datetime(6) DEFAULT NULL,
  `certificate_thumbprint` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resource` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nonce` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `acr` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `claims_locales` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `claims` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dpop_jkt` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_oauth_grants_on_oauth_application_id_and_code` (`oauth_application_id`,`code`),
  UNIQUE KEY `index_oauth_grants_on_token` (`token`),
  UNIQUE KEY `index_oauth_grants_on_refresh_token` (`refresh_token`),
  UNIQUE KEY `index_oauth_grants_on_user_code` (`user_code`),
  KEY `fk_rails_3e095b0b7e` (`account_id`),
  CONSTRAINT `fk_rails_3e095b0b7e` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_rails_d5addd7cc9` FOREIGN KEY (`oauth_application_id`) REFERENCES `oauth_applications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `oauth_pushed_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_pushed_requests` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `oauth_application_id` bigint DEFAULT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `params` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_in` datetime(6) NOT NULL,
  `dpop_jkt` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_oauth_pushed_requests_on_code` (`code`),
  UNIQUE KEY `index_oauth_pushed_requests_on_oauth_application_id_and_code` (`oauth_application_id`,`code`),
  CONSTRAINT `fk_rails_c46eab5056` FOREIGN KEY (`oauth_application_id`) REFERENCES `oauth_applications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `oauth_saml_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_saml_settings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `oauth_application_id` bigint DEFAULT NULL,
  `idp_cert` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idp_cert_fingerprint` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idp_cert_fingerprint_algorithm` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `check_idp_cert_expiration` tinyint(1) DEFAULT NULL,
  `name_identifier_format` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `audience` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issuer` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_oauth_saml_settings_on_issuer` (`issuer`),
  KEY `fk_rails_73255239bb` (`oauth_application_id`),
  CONSTRAINT `fk_rails_73255239bb` FOREIGN KEY (`oauth_application_id`) REFERENCES `oauth_applications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`version`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_cable_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_cable_messages` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `channel` varbinary(1024) NOT NULL,
  `payload` longblob NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `channel_hash` bigint NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_cable_messages_on_channel` (`channel`),
  KEY `index_solid_cable_messages_on_channel_hash` (`channel_hash`),
  KEY `index_solid_cable_messages_on_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_cache_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_cache_entries` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varbinary(1024) NOT NULL,
  `value` longblob NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `key_hash` bigint NOT NULL,
  `byte_size` int NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_cache_entries_on_byte_size` (`byte_size`),
  KEY `index_solid_cache_entries_on_key_hash_and_byte_size` (`key_hash`,`byte_size`),
  UNIQUE KEY `index_solid_cache_entries_on_key_hash` (`key_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_blocked_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_blocked_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `concurrency_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_queue_blocked_executions_for_release` (`concurrency_key`,`priority`,`job_id`),
  KEY `index_solid_queue_blocked_executions_for_maintenance` (`expires_at`,`concurrency_key`),
  UNIQUE KEY `index_solid_queue_blocked_executions_on_job_id` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_claimed_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_claimed_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `process_id` bigint DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_claimed_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_claimed_executions_on_process_id_and_job_id` (`process_id`,`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_failed_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_failed_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_jobs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `arguments` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `active_job_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scheduled_at` datetime(6) DEFAULT NULL,
  `finished_at` datetime(6) DEFAULT NULL,
  `concurrency_key` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_queue_jobs_on_active_job_id` (`active_job_id`),
  KEY `index_solid_queue_jobs_on_class_name` (`class_name`),
  KEY `index_solid_queue_jobs_on_finished_at` (`finished_at`),
  KEY `index_solid_queue_jobs_for_filtering` (`queue_name`,`finished_at`),
  KEY `index_solid_queue_jobs_for_alerting` (`scheduled_at`,`finished_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_pauses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_pauses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_pauses_on_queue_name` (`queue_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_processes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_processes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `kind` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_heartbeat_at` datetime(6) NOT NULL,
  `supervisor_id` bigint DEFAULT NULL,
  `pid` int NOT NULL,
  `hostname` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metadata` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_queue_processes_on_last_heartbeat_at` (`last_heartbeat_at`),
  UNIQUE KEY `index_solid_queue_processes_on_name_and_supervisor_id` (`name`,`supervisor_id`),
  KEY `index_solid_queue_processes_on_supervisor_id` (`supervisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_ready_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_ready_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_ready_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_poll_all` (`priority`,`job_id`),
  KEY `index_solid_queue_poll_by_queue` (`queue_name`,`priority`,`job_id`),
  CONSTRAINT `fk_rails_81fcbd66af` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_recurring_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_recurring_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `task_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `run_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_recurring_executions_on_job_id` (`job_id`),
  UNIQUE KEY `index_solid_queue_recurring_executions_on_task_key_and_run_at` (`task_key`,`run_at`),
  CONSTRAINT `fk_rails_318a5533ed` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_recurring_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_recurring_tasks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `schedule` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `command` varchar(2048) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `arguments` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `priority` int DEFAULT '0',
  `static` tinyint(1) NOT NULL DEFAULT '1',
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_recurring_tasks_on_key` (`key`),
  KEY `index_solid_queue_recurring_tasks_on_static` (`static`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_scheduled_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_scheduled_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `scheduled_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `index_solid_queue_scheduled_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_dispatch_all` (`scheduled_at`,`priority`,`job_id`),
  CONSTRAINT `fk_rails_c4316f352d` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_semaphores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solid_queue_semaphores` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` int NOT NULL DEFAULT '1',
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_solid_queue_semaphores_on_expires_at` (`expires_at`),
  KEY `index_solid_queue_semaphores_on_key_and_value` (`key`,`value`),
  UNIQUE KEY `index_solid_queue_semaphores_on_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_preferences` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `account_id` bigint NOT NULL,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `value_ciphertext` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `index_user_preferences_on_account_id` (`account_id`),
  UNIQUE KEY `index_user_preferences_on_account_id_and_key` (`account_id`,`key`),
  CONSTRAINT `fk_rails_d3b54c2dba` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('20250726123059'),
('20250724010255'),
('20250724010131'),
('20250724002442'),
('20250723180119'),
('20250723180105'),
('20250722224142'),
('20250617190409'),
('20250617182526'),
('20250615160437'),
('20250614124224'),
('20250614113146'),
('20250614112410'),
('20250613175424'),
('20250613174038'),
('20250613174030'),
('20250613160722'),
('20250613134458'),
('20250613134013'),
('20250613134012'),
('20250613134011'),
('20250613134010'),
('20250613134009'),
('20250613134008'),
('20250613134007'),
('20250613134006'),
('20250613134005'),
('20250613134004'),
('20250613134003'),
('20250611142704'),
('20250528175828'),
('20250525235723'),
('20250429160000'),
('20250429153606'),
('20250429150127'),
('20250429145201'),
('20250429144245'),
('20250429144224'),
('20250427194000'),
('20250421231000'),
('20250420154000'),
('20250420003000'),
('20250412165601'),
('20250412120542'),
('20250405190936'),
('20250405190931'),
('20250328202000'),
('20250328010000'),
('20250328000000'),
('20250322095911'),
('20250319000000'),
('20250311223708'),
('20250311221942'),
('20250307195147'),
('20241219205719'),
('20241219205559'),
('20241219005940'),
('20241215205232'),
('20241025005517'),
('20240428153817');

