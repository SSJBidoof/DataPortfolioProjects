-- Cleaning Our Data in SQL Queries

SELECT *
FROM NashvilleHousing

---------------------------------------------------------------------

-- Standardize Date Format

/*
SELECT 
	SaleDate,
	CONVERT(Date, SaleDate)
FROM NashvilleHousing
*/

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)


--- If update/set does not work here is an alternative involving adding a new column

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

---------------------------------------------------------------------

-- Populate Property Address date

SELECT 
	*
FROM 
	NashvilleHousing
WHERE 
	PropertyAddress is NULL
ORDER BY
	ParcelID
	

-- Populating missing addressing using matching ParcelIDs

SELECT 
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
	NashvilleHousing AS a
JOIN 
	NashvilleHousing AS b
ON
	a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE 
	a.PropertyAddress is NULL

-- Updating Table
-- When updating using a JOIN you must use the alias

UPDATE a
SET 
	PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
	NashvilleHousing AS a
JOIN 
	NashvilleHousing AS b
ON
	a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE 
	a.PropertyAddress is NULL

---------------------------------------------------------------------

-- Breaking out Address into individual Columns (Adress, City, State)

SELECT 
	PropertyAddress
FROM 
	NashvilleHousing

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
FROM 
	NashvilleHousing


-- Adding them to the Table
ALTER TABLE NashvilleHousing
ADD PropterySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing


--- Owner Address

SELECT 
	OwnerAddress
FROM 
	NashvilleHousing


SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddressNumber,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM 
	NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerAddressNumber Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerCity Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerState Nvarchar(255);

Update NashvilleHousing
SET OwnerAddressNumber = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
Update NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
Update NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM NashvilleHousing


---------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT 
	DISTINCT(SoldAsVacant),
	COUNT(SoldASVacant)
FROM 
	NashvilleHousing
GROUP BY
	SoldAsVacant
ORDER BY
	2


SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM 
	NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END


---------------------------------------------------------------------
-- Remove Duplicates
-- *Typically not done in SQL but good to know
-- *Typically duplicates are not deleted but are removed in a temp table, for this project I'll delete them

WITH temp AS(
SELECT 
	*,
	ROW_NUMBER() OVER 
		(PARTITION BY 
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY
			UniqueID) AS row_num
FROM 
	NashvilleHousing
)

-- Deleting
DELETE 
FROM 
	temp
WHERE 
	row_num LIKE 2


-- Deleting Columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT *
FROM NashvilleHousing
ORDER BY SaleDateConverted


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville 
--Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


-----------------------------------------------------------------------------------------------
-- For Visualization

WITH NashvilleCTE AS(
SELECT 
	SaleDateConverted,
	DATEPART(MONTH, SaleDateConverted) AS SaleMonth,
	DATEPART(YEAR, SaleDateConverted) AS SaleYear,
	SoldAsVacant,
	Acreage,
	SalePrice,
	TotalValue,
	YearBuilt,
	Bedrooms,
	FullBath,
	HalfBath,
	PropertySplitCity
FROM 
	NashvilleHousing
	)

--------------------------------------

-- Average Sale Price by Year
SELECT
	SaleYear,
	ROUND(AVG(SalePrice),0) AS AvgSalePrice
FROM
	NashvilleCTE
GROUP BY
	SaleYear


-- Sales By Month
SELECT 
	SaleMonth,
	SaleYear,
	COUNT(*) AS TotalSales
FROM
	NashvilleCTE
GROUP BY
	SaleMonth, SaleYear
ORDER BY
	SaleYear, SaleMonth


-- Count of houses for sale by area
SELECT
	PropertySplitCity,
	COUNT(PropertySplitCity)
FROM 
	NashvilleCTE
GROUP BY
	PropertySplitCity

-- Average Age of Home
SELECT
	2019 - ROUND(SUM(YearBuilt)/COUNT(YearBuilt),0) AS AverageAgeOfHome
FROM 
	NashvilleCTE


-- Number of Bedroom Count
SELECT
	Bedrooms,
	COUNT(Bedrooms) AS AmountOfProperties
FROM
	NashvilleCTE
WHERE
	Bedrooms is not NULL
GROUP BY
	Bedrooms
ORDER BY
	Bedrooms


-- Number of Full Baths Count
SELECT
	FullBath,
	COUNT(FullBath) AS AmountOfProperties
FROM
	NashvilleCTE
WHERE 
	FullBath is not NULL
GROUP BY
	FullBath
ORDER BY
	FullBath


-- Number of Half Baths Count
SELECT
	HalfBath,
	COUNT(HalfBath) AS AmountOfProperties
FROM
	NashvilleCTE
WHERE 
	HalfBath is not NULL
GROUP BY
	HalfBath
ORDER BY
	HalfBath