--DROP DATABASE app;
CREATE DATABASE IF NOT EXISTS app;
USE app;

-- Stores Transactions 
CREATE TABLE IF NOT EXISTS transaction (
	aggregate_id BINARY(16) NOT NULL,
	transaction_id BINARY(16) PRIMARY KEY,
	next_transaction_id BINARY(16) UNIQUE NOT NULL,
	last_transaction_id BINARY(16),
	creation_time VARCHAR(25) NOT NULL,
	version INTEGER NOT NULL,
	data JSON
);

-- Stores Aggregate State at particular time
CREATE TABLE IF NOT EXISTS aggregate_cache (
	aggregate_id BINARY(16) PRIMARY KEY,
	version INTEGER NOT NULL,
	transaction_id BINARY(16) UNIQUE,
	creation_time VARCHAR(25) NOT NULL,
	data JSON
);

-- Stores View Model Types
CREATE TABLE IF NOT EXISTS vm_type (
	vm_type_id BINARY(16) PRIMARY KEY,
	name varchar(64) UNIQUE NOT NULL,
	description varchar(512) NOT NULL,
	INDEX (name)
);

-- Stores view model instances determined by query objects
CREATE TABLE IF NOT EXISTS vm (
	vm_id BINARY(16) PRIMARY KEY,
	vm_type_id BINARY(16) NOT NULL,
	vm_query_object_id BINARY(16) NOT NULL,
	INDEX(vm_type_id, vm_query_object_id)
);

-- Stores the transactions associated with a view model
CREATE TABLE IF NOT EXISTS vm_transaction (
	vm_id BINARY(16),
	transaction_id BINARY(16),
	INDEX( vm_id, transaction_id )
);

-- Stores snapshots of viewmodels at a particular time
CREATE TABLE IF NOT EXISTS vm_cache (
	vm_instance_id BINARY(16),
	creation_time TIMESTAMP,
	data JSON,
	INDEX(vm_instance_id)
);

-- Store vm query objects
CREATE TABLE IF NOT EXISTS vm_query_object (
	vm_query_object_id BINARY(16) PRIMARY KEY
);

-- Stores key information for key value pairs
CREATE TABLE IF NOT EXISTS map_key (
	map_key_id binary(16) PRIMARY KEY,
	name varchar(64) NOT NULL,
	description varchar(256),
	INDEX (name(16))
);

-- A key value pair
CREATE TABLE IF NOT EXISTS kv_pair(
	kv_pair_id binary(16) primary key,
	map_key_id binary(16) not null,
	value varchar(64),
	INDEX (value(16))
);

-- Use to associate a query object with multiple key-value pairs
CREATE TABLE IF NOT EXISTS vm_query_object_kv_pair (
	vm_query_object_id binary(16) not null,
	kv_pair_id binary(16) not null,
	INDEX (
		vm_query_object_id,
		kv_pair_id
	)
);

--
-- Setup initial conditions
--

-- Create a VM for accounts
INSERT INTO vm_type
(
	vm_type_id,
	name,
	description
)
VALUES
(
	uuid_to_bin('a8b7179d-fc63-4ff2-a5b4-65b0d2ba5414'),
	'account-v1b1',
	'v1b1 experiment for account viewmodel'
);

-- Create a map key for aggregate ids
insert into map_key
(
	map_key_id,
	name,
	description
)
values
(
	uuid_to_bin('ce70c90f-8449-4f7d-b1a8-dd139e9c3a55'),
	'aggregate_id',
	'an aggregate id'
);


--
-- Example CQRS Usage
--



--
-- Fake Account Created
--
INSERT INTO transaction 
(
	aggregate_id,
	transaction_id,
	next_transaction_id,
	last_transaction_id,
	creation_time,
	version,
	data
)
VALUES
(
	uuid_to_bin('f96e46fb-0425-49bb-973c-a0e0c446af41'),
	uuid_to_bin('b0a8c834-7e77-4782-be73-6d950729e795'),
	uuid_to_bin('60a39e17-1ccf-4c81-9377-d2e41fa49709'),
	null,
	'2018-10-01T00:00:00+00:00',
	1,
	'{
		"aggregate_id": "f96e46fb-0425-49bb-973c-a0e0c446af41",
		"transaction_id": "b0a8c834-7e77-4782-be73-6d950729e795",
		"next_transaction_id": "60a39e17-1ccf-4c81-9377-d2e41fa49709",
		"last_transaction_id": null,
		"creation_time": "2018-10-01T11:12:11+00:00",
		"version": "1",
		"type": "ACCOUNT_CREATED",
		"data": {
			"username": "john.doe",
			"email": "john.doe@nowhere.com",
			"password": "Qwerty!234"
		}
	}'
);

-- Create query object for new account
INSERT INTO vm_query_object
(
	vm_query_object_id
)
VALUES
(
	uuid_to_bin('51c662f5-7b8e-4ddd-88de-c68f8ce2f7a7')
);

-- Create key-value pair for the account aggregate root
INSERT INTO kv_pair
(
	kv_pair_id,
	map_key_id,
	value
)
VALUES
(
	uuid_to_bin('d9d80bde-0c2a-4e61-94c6-20a4bbd5d63b'),
	uuid_to_bin('ce70c90f-8449-4f7d-b1a8-dd139e9c3a55'),
	"f96e46fb-0425-49bb-973c-a0e0c446af41"
);

-- Associate the key-value pair with the query object
INSERT INTO vm_query_object_kv_pair
(
	vm_query_object_id,
	kv_pair_id
)
VALUES
(
	uuid_to_bin('51c662f5-7b8e-4ddd-88de-c68f8ce2f7a7'),
	uuid_to_bin('d9d80bde-0c2a-4e61-94c6-20a4bbd5d63b')
);

-- Associate the query object with view model
INSERT INTO vm
(
	vm_id,
	vm_type_id,
	vm_query_object_id
)
VALUES
(
	uuid_to_bin('8bed7c03-b101-4c88-823b-26f8afa0fead'),
	uuid_to_bin('a8b7179d-fc63-4ff2-a5b4-65b0d2ba5414'),
	uuid_to_bin('51c662f5-7b8e-4ddd-88de-c68f8ce2f7a7')
);

-- Associate the view model with the transaction
INSERT INTO vm_transaction
(
	vm_id,
	transaction_id
)
VALUES
(
	uuid_to_bin('8bed7c03-b101-4c88-823b-26f8afa0fead'),
	uuid_to_bin('b0a8c834-7e77-4782-be73-6d950729e795')
);

-- 
-- Password Changed on Fake Account
--
INSERT INTO transaction 
(
	aggregate_id,
	transaction_id,
	next_transaction_id,
	last_transaction_id,
	creation_time,
	version,
	data
)
VALUES
(
	uuid_to_bin('f96e46fb-0425-49bb-973c-a0e0c446af41'),
	uuid_to_bin('60a39e17-1ccf-4c81-9377-d2e41fa49709'),
	uuid_to_bin('7a2828e3-6ef0-40f6-8bdf-415d11dc43f2'),
	uuid_to_bin('b0a8c834-7e77-4782-be73-6d950729e795'),
	'2018-10-02T00:00:00+00:00',
	2,
	'{
		"aggregate_id": "f96e46fb-0425-49bb-973c-a0e0c446af41",
		"transaction_id": "60a39e17-1ccf-4c81-9377-d2e41fa49709",
		"next_transaction_id": "7a2828e3-6ef0-40f6-8bdf-415d11dc43f2",
		"last_transaction_id": "b0a8c834-7e77-4782-be73-6d950729e795",
		"creation_time": "2018-10-01T11:12:11+00:00",
		"version": "2",
		"type": "PASSWORD_CHANGED",
		"data": {
			"password": "WeakPassword"
		}
	}'
);

-- Associate the viewmodel with the transaction
INSERT INTO vm_transaction
(
	vm_id,
	transaction_id
)
VALUES
(
	uuid_to_bin('8bed7c03-b101-4c88-823b-26f8afa0fead'),
	uuid_to_bin('60a39e17-1ccf-4c81-9377-d2e41fa49709')
);


--
-- Sample Queries
-- 

-- Get all transactions
SELECT
	bin_to_uuid(aggregate_id),
	bin_to_uuid(transaction_id),
	bin_to_uuid(next_transaction_id),
	bin_to_uuid(last_transaction_id),
	creation_time,
	version,
	data
FROM transaction;

-- Get all transactions for a particular view model
SELECT
	transaction.data	
FROM map_key
	INNER JOIN kv_pair
		ON map_key.map_key_id = kv_pair.map_key_id
	INNER JOIN vm_query_object_kv_pair
		ON vm_query_object_kv_pair.kv_pair_id = kv_pair.kv_pair_id
	INNER JOIN vm_query_object
		ON vm_query_object.vm_query_object_id = vm_query_object_kv_pair.vm_query_object_id	
	INNER JOIN vm
		ON vm.vm_query_object_id = vm_query_object.vm_query_object_id
	INNER JOIN vm_type
		ON vm_type.vm_type_id = vm.vm_type_id
	INNER JOIN vm_transaction
		ON vm_transaction.vm_id = vm.vm_id
	INNER JOIN transaction
		ON transaction.transaction_id = vm_transaction.transaction_id
WHERE kv_pair.value = 'f96e46fb-0425-49bb-973c-a0e0c446af41'
	AND map_key.name = 'aggregate_id'
	AND vm_type.name = 'account-v1b1'
ORDER BY transaction.creation_time ASC;

-- Find view model id for a query object
SELECT
	bin_to_uuid(vm.vm_id)
FROM map_key
	INNER JOIN kv_pair
		ON map_key.map_key_id = kv_pair.map_key_id
	INNER JOIN vm_query_object_kv_pair
		ON vm_query_object_kv_pair.kv_pair_id = kv_pair.kv_pair_id
	INNER JOIN vm_query_object
		ON vm_query_object.vm_query_object_id = vm_query_object_kv_pair.vm_query_object_id	
	INNER JOIN vm
		ON vm.vm_query_object_id = vm_query_object.vm_query_object_id
	INNER JOIN vm_type
		ON vm_type.vm_type_id = vm.vm_type_id
WHERE kv_pair.value = 'f96e46fb-0425-49bb-973c-a0e0c446af41'
	AND map_key.name = 'aggregate_id'
	AND vm_type.name = 'account-v1b1';

