
DROP DATABASE IF EXISTS seafoodcity;
CREATE DATABASE seafoodcity
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE seafoodcity;

-- ============================================================
-- CATEGORY HIERARCHY
-- ============================================================

-- Parent category table (generalisation of Seafood, Meat, Produce, etc.)
CREATE TABLE Category (
    CatID       INT          NOT NULL AUTO_INCREMENT,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 0,   -- 1 = perishable
    PRIMARY KEY (CatID)
);

-- Specialisation: Seafood
CREATE TABLE Seafood (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 1,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_seafood_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Meat
CREATE TABLE Meat (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 1,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_meat_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Produce
CREATE TABLE Produce (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 1,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_produce_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Frozen
CREATE TABLE Frozen (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_frozen_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Pantry
CREATE TABLE Pantry (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_pantry_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Personal Care
CREATE TABLE PersonalCare (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_personalcare_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Household Essentials
CREATE TABLE HouseholdEssentials (
    CatID        INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory  VARCHAR(100),
    IsPerishable TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (CatID),
    CONSTRAINT fk_household_cat FOREIGN KEY (CatID) REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- PRODUCTS
-- ============================================================

CREATE TABLE Products (
    ProductID   INT            NOT NULL AUTO_INCREMENT,
    UPC         VARCHAR(20)    NOT NULL UNIQUE,
    Name        VARCHAR(200)   NOT NULL,
    Brand       VARCHAR(100),
    UnitPrice   DECIMAL(10,2)  NOT NULL,   -- base list price
    Weight      DECIMAL(10,3),             -- numeric weight/size
    WeightUnit  VARCHAR(20),               -- e.g., 'lb', 'oz', 'kg', 'g', 'fl oz', 'ml', 'count'
    PRIMARY KEY (ProductID),
    INDEX idx_products_upc (UPC),
    INDEX idx_products_brand (Brand)
);

-- Belongs: many-to-many between Products and Category
CREATE TABLE Belongs (
    ProductID   INT NOT NULL,
    CatID       INT NOT NULL,
    PRIMARY KEY (ProductID, CatID),
    CONSTRAINT fk_belongs_product  FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_belongs_category FOREIGN KEY (CatID)     REFERENCES Category(CatID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- VENDORS
-- ============================================================

CREATE TABLE Vendors (
    SupplierID       INT          NOT NULL AUTO_INCREMENT,
    SupplierName     VARCHAR(200) NOT NULL,
    SupplierPhoneNum VARCHAR(20),
    Address          VARCHAR(300),
    PRIMARY KEY (SupplierID)
);

-- Supply: which vendors supply which products
CREATE TABLE Supply (
    ProductID   INT NOT NULL,
    SupplierID  INT NOT NULL,
    PRIMARY KEY (ProductID, SupplierID),
    CONSTRAINT fk_supply_product  FOREIGN KEY (ProductID)  REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_supply_vendor   FOREIGN KEY (SupplierID) REFERENCES Vendors(SupplierID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- WAREHOUSE
-- ============================================================

CREATE TABLE Warehouse (
    WarehouseID INT          NOT NULL AUTO_INCREMENT,
    Location    VARCHAR(200) NOT NULL,
    Zipcode     VARCHAR(10),
    Capacity    INT,                  -- total capacity in units
    Inventory   INT          DEFAULT 0,
    Region      VARCHAR(100),
    PRIMARY KEY (WarehouseID)
);

-- ============================================================
-- STORE (generalisation)
-- ============================================================

CREATE TABLE Store (
    StoreID     INT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (StoreID)
);

-- Specialisation: BrickAndMotor (physical stores)
CREATE TABLE BrickAndMotor (
    StoreID     INT          NOT NULL,
    Address     VARCHAR(300) NOT NULL,
    State       CHAR(2)      NOT NULL,   -- 2-letter US state abbreviation
    PRIMARY KEY (StoreID),
    CONSTRAINT fk_bam_store FOREIGN KEY (StoreID) REFERENCES Store(StoreID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- BrickAndMotorHours: store hours per day
CREATE TABLE BrickAndMotorHours (
    StoreID      INT         NOT NULL,
    Day          VARCHAR(10) NOT NULL,   -- Monday, Tuesday, …
    OpeningTime  TIME        NOT NULL,
    ClosingTime  TIME        NOT NULL,
    PRIMARY KEY (StoreID, Day),
    CONSTRAINT fk_bamhours_store FOREIGN KEY (StoreID) REFERENCES BrickAndMotor(StoreID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Specialisation: Web (online store)
CREATE TABLE Web (
    StoreID     INT          NOT NULL,
    Url         VARCHAR(300) NOT NULL,
    PRIMARY KEY (StoreID),
    CONSTRAINT fk_web_store FOREIGN KEY (StoreID) REFERENCES Store(StoreID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- INVENTORY (per-store product stock & pricing)
-- NOTE: UnitPrice here allows stores to have different prices
-- ============================================================

CREATE TABLE Inventory (
    ProductID   INT            NOT NULL,
    StoreID     INT            NOT NULL,
    Quantity    INT            NOT NULL DEFAULT 0,
    UnitPrice   DECIMAL(10,2)  NOT NULL,   -- store-specific price
    PRIMARY KEY (ProductID, StoreID),
    CONSTRAINT fk_inventory_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inventory_store   FOREIGN KEY (StoreID)   REFERENCES Store(StoreID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Stock: warehouse holds products
CREATE TABLE Stock (
    ProductID   INT NOT NULL,
    WarehouseID INT NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (ProductID, WarehouseID),
    CONSTRAINT fk_stock_product   FOREIGN KEY (ProductID)   REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stock_warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Restock: warehouse replenishes a store
CREATE TABLE Restock (
    RestockID       INT  NOT NULL AUTO_INCREMENT,
    WarehouseID     INT  NOT NULL,
    StoreID         INT  NOT NULL,
    ProductID       INT  NOT NULL,
    Restock_Date    DATE NOT NULL,
    Restock_Quantity INT  NOT NULL,
    PRIMARY KEY (RestockID),
    CONSTRAINT fk_restock_warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_restock_store     FOREIGN KEY (StoreID)     REFERENCES Store(StoreID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_restock_product   FOREIGN KEY (ProductID)   REFERENCES Products(ProductID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- CUSTOMERS
-- ============================================================

CREATE TABLE Customer (
    CustomerID    INT          NOT NULL AUTO_INCREMENT,
    FullName      VARCHAR(200),           -- NULL allowed (anonymous / refused)
    CustomerEmail VARCHAR(200),
    Address       VARCHAR(300),
    PRIMARY KEY (CustomerID),
    INDEX idx_customer_email (CustomerEmail)
);

-- ============================================================
-- TRANSACTIONS
-- ============================================================

CREATE TABLE Transaction (
    TransactionID   INT            NOT NULL AUTO_INCREMENT,
    TotalPrice      DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    TransactionDate DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TransactionID)
);

-- Make: links a customer to a transaction (frequent shoppers only)
CREATE TABLE Make (
    CustomerID    INT         NOT NULL,
    TransactionID INT         NOT NULL UNIQUE,   -- one transaction belongs to one customer
    PayMethod     VARCHAR(50) NOT NULL,           -- 'Cash', 'Credit', 'Debit', 'Online'
    PRIMARY KEY (CustomerID, TransactionID),
    CONSTRAINT fk_make_customer     FOREIGN KEY (CustomerID)    REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_make_transaction  FOREIGN KEY (TransactionID) REFERENCES Transaction(TransactionID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Included: line items in a transaction
CREATE TABLE Included (
    TransactionID    INT            NOT NULL,
    ProductID        INT            NOT NULL,
    QuantityPurchased INT           NOT NULL DEFAULT 1,
    UnitPriceAtSale  DECIMAL(10,2)  NOT NULL,   -- price at the time of sale
    PRIMARY KEY (TransactionID, ProductID),
    CONSTRAINT fk_included_transaction FOREIGN KEY (TransactionID) REFERENCES Transaction(TransactionID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_included_product     FOREIGN KEY (ProductID)     REFERENCES Products(ProductID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Processing: which store processed a transaction
CREATE TABLE Processing (
    StoreID       INT NOT NULL,
    TransactionID INT NOT NULL UNIQUE,
    PRIMARY KEY (StoreID, TransactionID),
    CONSTRAINT fk_processing_store       FOREIGN KEY (StoreID)       REFERENCES Store(StoreID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_processing_transaction FOREIGN KEY (TransactionID) REFERENCES Transaction(TransactionID)
        ON DELETE CASCADE ON UPDATE CASCADE
);