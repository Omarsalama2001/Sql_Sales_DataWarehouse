
USE master ;
GO
-- Drop and recreate the 'DataWarehouse' database if it already exist
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE; -- this allows you to delete the db if db used by 
    DROP DATABASE DataWarehouse;
END;

GO
-- create the dataWarehouse
create database DataWarehouse ;
Go
use DataWarehouse;
GO

-- create schemas 
create schema bronze;
GO
create schema silver;
GO
create schema gold;