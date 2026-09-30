/*=============================================================
  Supply Chain Ontology — Step 1: Database, Schema & Tags
  =============================================================*/

USE ROLE ACCOUNTADMIN;

-- Database & Schema
CREATE DATABASE IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY;
CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY.CORE;

USE DATABASE SUPPLY_CHAIN_ONTOLOGY;
USE SCHEMA CORE;

-- Governance Tags
CREATE OR REPLACE TAG DATA_DOMAIN
  ALLOWED_VALUES 'Supply Chain', 'Finance', 'Operations', 'Master Data'
  COMMENT = 'Classifies the business domain of the object';

CREATE OR REPLACE TAG ONTOLOGY_ENTITY
  ALLOWED_VALUES 'Core Entity', 'Bridge Table', 'Time Series', 'Transaction'
  COMMENT = 'Ontology classification within the supply chain model';

CREATE OR REPLACE TAG SENSITIVITY
  ALLOWED_VALUES 'Public', 'Internal', 'Confidential', 'Restricted'
  COMMENT = 'Data sensitivity classification';
