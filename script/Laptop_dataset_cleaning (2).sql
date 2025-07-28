# Drop database

DROP DATABASE sql_cx_live;

# Create the database
CREATE DATABASE sql_cx_live;

# Switch to the created database
USE sql_cx_live;

# View data from laptops table (if it already exists)
SELECT * FROM sql_cx_live.laptops;

# Shortcut view
SELECT * FROM laptops;

# Create a backup of laptops table
CREATE TABLE laptops_backup LIKE laptops;

# Insert data into backup table
INSERT INTO laptops_backup
SELECT * FROM laptops;

# Check data size of the laptops table in KB
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'sql_cx_live'
AND TABLE_NAME = 'laptops';

# View data
SELECT * FROM laptops;

# Drop unnecessary column
ALTER TABLE laptops DROP COLUMN `Unnamed: 0`;

# View data again
SELECT * FROM laptops;

# View table schema
DESCRIBE laptops;

# Disable safe updates to allow DELETE without WHERE with key
SET SQL_SAFE_UPDATES = 0;

# Delete rows where all fields are NULL
DELETE FROM laptops
WHERE Company IS NULL
  AND TypeName IS NULL
  AND Inches IS NULL
  AND ScreenResolution IS NULL
  AND Cpu IS NULL
  AND Ram IS NULL
  AND Memory IS NULL
  AND Gpu IS NULL
  AND OpSys IS NULL
  AND Weight IS NULL
  AND Price IS NULL;

# Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;

# Convert Inches column to decimal
ALTER TABLE laptops MODIFY COLUMN Inches DECIMAL(10,1);

# View data
SELECT * FROM laptops;

# Remove 'GB' from Ram column (1st approach)
SET SQL_SAFE_UPDATES = 0;

UPDATE laptops
SET Ram = REPLACE(Ram, 'GB', '')
WHERE Ram LIKE '%GB%';

# View updated Ram
SELECT * FROM laptops;

# Clean up Ram column again (2nd approach)
UPDATE laptops
SET Ram = TRIM(REPLACE(Ram, 'GB', ''))
WHERE Ram LIKE '%GB%';

# Convert Ram column to integer
ALTER TABLE laptops MODIFY COLUMN Ram INTEGER;

# View final Ram column
SELECT * FROM laptops;

# Check size again after cleanup
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'sql_cx_live'
AND TABLE_NAME = 'laptops';

# Clean Weight column (remove 'kg')
UPDATE laptops l1
SET Weight = (SELECT REPLACE(Weight,'kg','') 
              FROM laptops l2 WHERE l2.index = l1.index);

# View updated Weight
SELECT * FROM laptops;

# Round price values
UPDATE laptops
SET Price = ROUND(Price)
WHERE Price != ROUND(Price);

# Convert Price to integer
ALTER TABLE laptops MODIFY COLUMN Price INTEGER;

# View table
SELECT * FROM laptops;

# View distinct OS values
SELECT DISTINCT OpSys FROM laptops;

# Categorize OS types
SELECT OpSys,
CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys = 'No OS' THEN 'N/A'
    ELSE 'other'
END AS 'os_brand'
FROM laptops;

# Update OS column to standardized values
UPDATE laptops
SET OpSys = 
CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys = 'No OS' THEN 'N/A'
    ELSE 'other'
END;

# View changes
SELECT * FROM laptops;

# Add GPU brand and GPU name columns
ALTER TABLE laptops
ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

# View table
SELECT * FROM laptops;

# Extract GPU brand
UPDATE laptops
SET gpu_brand = SUBSTRING_INDEX(Gpu, ' ', 1)
WHERE gpu_brand IS NULL OR gpu_brand = '';

# Extract GPU name
UPDATE laptops
SET gpu_name = TRIM(REPLACE(Gpu, gpu_brand, ''))
WHERE gpu_name IS NULL OR gpu_name = '';

# View updated data
SELECT * FROM laptops;

# Remove original Gpu column
ALTER TABLE laptops DROP COLUMN Gpu;

# View updated table
SELECT * FROM laptops;

# Add CPU brand, name, and speed columns
ALTER TABLE laptops
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;

# View table
SELECT * FROM laptops;

# Extract CPU brand
UPDATE laptops
SET cpu_brand = SUBSTRING_INDEX(Cpu, ' ', 1)
WHERE cpu_brand IS NULL OR cpu_brand = '';

# Extract CPU speed using regex
UPDATE laptops
SET cpu_speed = CAST(
    REGEXP_SUBSTR(Cpu, '[0-9]+\\.?[0-9]*') AS DECIMAL(10,2)
)
WHERE cpu_speed IS NULL;

# Extract CPU name
UPDATE laptops
SET cpu_name = TRIM(
    REPLACE(
        REPLACE(Cpu, cpu_brand, ''),
        SUBSTRING_INDEX(REPLACE(Cpu, cpu_brand, ''), ' ', -1),
        ''
    )
);

# View final result
SELECT * FROM laptops;

# Drop original Cpu column
ALTER TABLE laptops DROP COLUMN Cpu;

# Extract screen resolution width & height
SELECT ScreenResolution,
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1)
FROM laptops;

# Add resolution columns
ALTER TABLE laptops 
ADD COLUMN resolution_width INTEGER AFTER ScreenResolution,
ADD COLUMN resolution_height INTEGER AFTER resolution_width;

# View data
SELECT * FROM laptops;

# Update resolution columns
UPDATE laptops
SET resolution_width = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
    resolution_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1);

# Add touchscreen column
ALTER TABLE laptops 
ADD COLUMN touchscreen INTEGER AFTER resolution_height;

# View data
SELECT * FROM laptops;

# Identify touchscreen rows
SELECT ScreenResolution LIKE '%Touch%' FROM laptops;

# Update touchscreen column
UPDATE laptops
SET touchscreen = ScreenResolution LIKE '%Touch%';

# View data
SELECT * FROM laptops;

# Remove ScreenResolution column
ALTER TABLE laptops
DROP COLUMN ScreenResolution;

# View data
SELECT * FROM laptops;

# Trim CPU name to first two words
SELECT cpu_name,
SUBSTRING_INDEX(TRIM(cpu_name),' ',2)
FROM laptops;

# Update cpu_name to simplified version
UPDATE laptops
SET cpu_name = SUBSTRING_INDEX(TRIM(cpu_name),' ',2);

# View distinct cpu_name
SELECT DISTINCT cpu_name FROM laptops;

# View Memory column
SELECT Memory FROM laptops;

# Add memory detail columns
ALTER TABLE laptops
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_storage INTEGER AFTER memory_type,
ADD COLUMN secondary_storage INTEGER AFTER primary_storage;

# Determine memory type
SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptops;

# Update memory_type
UPDATE laptops
SET memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END;

# Extract storage sizes
SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END
FROM laptops;

# Update primary and secondary storage
UPDATE laptops
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
    secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END;

# Convert TB to GB (e.g., 1=1024 if value <= 2)
SELECT 
primary_storage,
CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage,
CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END
FROM laptops;

# Update storage sizes in GB
UPDATE laptops
SET primary_storage = CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
    secondary_storage = CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END;

# View final table
SELECT * FROM laptops;

# Drop GPU name (already split earlier)
ALTER TABLE laptops DROP COLUMN gpu_name;

# Final result
SELECT * FROM laptops;



SHOW VARIABLES LIKE 'secure_file_priv';
SELECT * 
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cleaned_laptops.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM laptops;


