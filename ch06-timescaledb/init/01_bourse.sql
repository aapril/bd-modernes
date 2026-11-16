-- Crée la base bourse et les extensions utilisées au chapitre 6.
CREATE DATABASE bourse;
\c bourse
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
