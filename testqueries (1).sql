
USE seafoodcity;

-- ============================================================
-- QUERY 1: Top 20 best-selling products at EACH store
--   Ranked by total quantity sold per store
-- ============================================================
WITH StoreSales AS (
    SELECT
        pr.StoreID,
        COALESCE(bm.Address, w.Url) AS StoreLocation,
        p.ProductID,
        p.Name        AS ProductName,
        p.Brand,
        SUM(i.QuantityPurchased)                    AS TotalUnitsSold,
        SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS TotalRevenue,
        RANK() OVER (
            PARTITION BY pr.StoreID
            ORDER BY SUM(i.QuantityPurchased) DESC
        ) AS RankAtStore
    FROM Included i
    JOIN `Transaction` t       ON i.TransactionID  = t.TransactionID
    JOIN Processing pr         ON t.TransactionID  = pr.TransactionID
    JOIN Store s               ON pr.StoreID        = s.StoreID
    LEFT JOIN BrickAndMotor bm ON s.StoreID         = bm.StoreID
    LEFT JOIN Web w            ON s.StoreID         = w.StoreID
    JOIN Products p            ON i.ProductID       = p.ProductID
    GROUP BY pr.StoreID, COALESCE(bm.Address, w.Url),
             p.ProductID, p.Name, p.Brand
)
SELECT *
FROM StoreSales
WHERE RankAtStore <= 20
ORDER BY StoreID, RankAtStore;

-- ============================================================
-- QUERY 2: Top 20 best-selling products in EACH STATE
--   (Web store is excluded — no physical state)
-- ============================================================
WITH StateSales AS (
    SELECT
        bm.State,
        p.ProductID,
        p.Name        AS ProductName,
        p.Brand,
        SUM(i.QuantityPurchased)                    AS TotalUnitsSold,
        SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS TotalRevenue,
        RANK() OVER (
            PARTITION BY bm.State
            ORDER BY SUM(i.QuantityPurchased) DESC
        ) AS RankInState
    FROM Included i
    JOIN `Transaction` t  ON i.TransactionID = t.TransactionID
    JOIN Processing pr    ON t.TransactionID = pr.TransactionID
    JOIN BrickAndMotor bm ON pr.StoreID       = bm.StoreID
    JOIN Products p       ON i.ProductID      = p.ProductID
    GROUP BY bm.State, p.ProductID, p.Name, p.Brand
)
SELECT *
FROM StateSales
WHERE RankInState <= 20
ORDER BY State, RankInState;

-- ============================================================
-- QUERY 3: Top 5 stores with the MOST SALES so far this year
--   "This year" = 2025 (current year at time of submission)
-- ============================================================
WITH YearlySales AS (
    SELECT
        s.StoreID,
        COALESCE(bm.Address, w.Url)      AS StoreLocation,
        COALESCE(bm.State, 'WEB')        AS State,
        COUNT(DISTINCT t.TransactionID)  AS NumberOfTransactions,
        SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS TotalSalesRevenue,
        RANK() OVER (
            ORDER BY SUM(i.QuantityPurchased * i.UnitPriceAtSale) DESC
        ) AS SalesRank
    FROM `Transaction` t
    JOIN Processing pr         ON t.TransactionID = pr.TransactionID
    JOIN Store s               ON pr.StoreID       = s.StoreID
    LEFT JOIN BrickAndMotor bm ON s.StoreID        = bm.StoreID
    LEFT JOIN Web w            ON s.StoreID        = w.StoreID
    JOIN Included i            ON t.TransactionID  = i.TransactionID
    WHERE YEAR(t.TransactionDate) = (
        SELECT MAX(YEAR(TransactionDate)) FROM `Transaction`
    )
    GROUP BY s.StoreID,
             COALESCE(bm.Address, w.Url),
             COALESCE(bm.State, 'WEB')
)
SELECT *
FROM YearlySales
ORDER BY TotalSalesRevenue DESC
LIMIT 5;

-- ============================================================
-- QUERY 4 (adapted for Seafood City — no Coke/Pepsi):
--   In how many stores does Bangus (Milkfish) outsell Tilapia?
--   These are the two flagship fresh fish products at Seafood City
--   (Analogous to the Coke vs Pepsi question)
-- ============================================================
WITH StoreMeatSales AS (
    SELECT
        pr.StoreID,
        p.Name              AS MeatName,
        SUM(i.QuantityPurchased) AS UnitsSold
    FROM Included i
    JOIN `Transaction` t  ON i.TransactionID = t.TransactionID
    JOIN Processing pr    ON t.TransactionID = pr.TransactionID
    JOIN Products p       ON i.ProductID     = p.ProductID
    WHERE p.Name IN (
        'Pork Belly (Liempo) per lb',
        'Chicken Leg Quarters per lb'
    )
    GROUP BY pr.StoreID, p.Name
),
PorkSales    AS (
    SELECT StoreID, UnitsSold
    FROM StoreMeatSales
    WHERE MeatName = 'Pork Belly (Liempo) per lb'
),
ChickenSales AS (
    SELECT StoreID, UnitsSold
    FROM StoreMeatSales
    WHERE MeatName = 'Chicken Leg Quarters per lb'
)
SELECT
    COUNT(*)                                  AS StoresPorkBeatChicken,
    GROUP_CONCAT(pk.StoreID ORDER BY pk.StoreID) AS StoreIDs
FROM PorkSales pk
JOIN ChickenSales ck ON pk.StoreID = ck.StoreID
WHERE pk.UnitsSold > ck.UnitsSold;

-- ============================================================
-- QUERY 5: Top 3 product CATEGORIES that customers buy together
--   with Rice (ProductID 45/46 — the most common Filipino staple)
--   Analogous to "what do people buy with milk"
-- ============================================================
WITH RiceBuyers AS (
    -- Transactions that included a rice product
    SELECT DISTINCT i.TransactionID
    FROM Included i
    JOIN Products p ON i.ProductID = p.ProductID
    WHERE p.Name IN ('Kokuho Rose Calrose Rice 15lb', 'Dinorado Premium Rice 25lb')
),
CoProducts AS (
    -- Other items in those same transactions
    SELECT
        c.CategoryName,
        SUM(i.QuantityPurchased) AS TotalUnitsBoughtWithRice
    FROM RiceBuyers rb
    JOIN Included i   ON rb.TransactionID = i.TransactionID
    JOIN Belongs b    ON i.ProductID = b.ProductID
    JOIN Category c   ON b.CatID = c.CatID
    JOIN Products p   ON i.ProductID = p.ProductID
    WHERE p.Name NOT IN ('Kokuho Rose Calrose Rice 15lb', 'Dinorado Premium Rice 25lb')
    GROUP BY c.CategoryName
)
SELECT
    CategoryName,
    TotalUnitsBoughtWithRice,
    RANK() OVER (ORDER BY TotalUnitsBoughtWithRice DESC) AS CategoryRank
FROM CoProducts
ORDER BY TotalUnitsBoughtWithRice DESC
LIMIT 3;

-- ============================================================
-- BONUS QUERY A: Store inventory levels — flag low stock
--   (Useful for triggering reorders; inventory < 20 units)
-- ============================================================
SELECT
   s.StoreID,
   COALESCE(bm.Address, w.Url) AS StoreLocation,
   p.Name        AS ProductName,
   p.Brand,
   inv.Quantity  AS CurrentStock,
   inv.UnitPrice AS StorePrice
FROM Inventory inv
JOIN Store s               ON inv.StoreID   = s.StoreID
LEFT JOIN BrickAndMotor bm ON s.StoreID     = bm.StoreID
LEFT JOIN Web w            ON s.StoreID     = w.StoreID
JOIN Products p            ON inv.ProductID = p.ProductID
WHERE inv.Quantity < 100
ORDER BY s.StoreID, inv.Quantity ASC;

-- ============================================================
-- BONUS QUERY B: Customer purchase history (basket analysis)
--   Show all transactions for a given frequent-shopper customer
-- ============================================================
SELECT
    c.CustomerID,
    c.FullName,
    t.TransactionID,
    t.TransactionDate,
    mk.PayMethod,
    COALESCE(bm.Address, w.Url) AS StoreLocation,
    p.Name             AS ProductName,
    i.QuantityPurchased,
    i.UnitPriceAtSale,
    (i.QuantityPurchased * i.UnitPriceAtSale) AS LineTotal
FROM Customer c
JOIN Make mk          ON c.CustomerID = mk.CustomerID
JOIN Transaction t    ON mk.TransactionID = t.TransactionID
JOIN Included i       ON t.TransactionID = i.TransactionID
JOIN Products p       ON i.ProductID = p.ProductID
JOIN Processing pr    ON t.TransactionID = pr.TransactionID
JOIN Store s          ON pr.StoreID = s.StoreID
LEFT JOIN BrickAndMotor bm ON s.StoreID = bm.StoreID
LEFT JOIN Web w            ON s.StoreID = w.StoreID
WHERE c.CustomerID = 1   -- Change CustomerID to view any customer
ORDER BY t.TransactionDate, i.TransactionID;

-- ============================================================
-- BONUS QUERY C: Sales history by store — monthly breakdown
-- ============================================================
SELECT
    s.StoreID,
    COALESCE(bm.Address, w.Url) AS StoreLocation,
    DATE_FORMAT(t.TransactionDate, '%Y-%m') AS YearMonth,
    COUNT(DISTINCT t.TransactionID) AS NumberOfTransactions,
    SUM(i.QuantityPurchased) AS TotalItemsSold,
    SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS MonthlyRevenue
FROM Transaction t
JOIN Processing pr  ON t.TransactionID = pr.TransactionID
JOIN Store s        ON pr.StoreID = s.StoreID
LEFT JOIN BrickAndMotor bm ON s.StoreID = bm.StoreID
LEFT JOIN Web w            ON s.StoreID = w.StoreID
JOIN Included i    ON t.TransactionID = i.TransactionID
GROUP BY s.StoreID, COALESCE(bm.Address, w.Url), DATE_FORMAT(t.TransactionDate, '%Y-%m')
ORDER BY s.StoreID, YearMonth;

-- ============================================================
-- BONUS QUERY D: Top-selling products by BRAND
-- ============================================================
SELECT
    p.Brand,
    SUM(i.QuantityPurchased) AS TotalUnitsSold,
    SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS TotalRevenue,
    COUNT(DISTINCT i.TransactionID) AS TransactionsAppearing,
    RANK() OVER (ORDER BY SUM(i.QuantityPurchased) DESC) AS BrandRank
FROM Included i
JOIN Products p ON i.ProductID = p.ProductID
GROUP BY p.Brand
ORDER BY TotalUnitsSold DESC;

-- ============================================================
-- BONUS QUERY E: Restock summary — what was restocked where
-- ============================================================
SELECT
    r.RestockID,
    r.Restock_Date,
    wh.Location AS WarehouseLocation,
    wh.Region,
    s.StoreID,
    COALESCE(bm.Address, 'WEB') AS StoreAddress,
    p.Name AS ProductName,
    r.Restock_Quantity
FROM Restock r
JOIN Warehouse wh ON r.WarehouseID = wh.WarehouseID
JOIN Store s      ON r.StoreID = s.StoreID
LEFT JOIN BrickAndMotor bm ON s.StoreID = bm.StoreID
JOIN Products p   ON r.ProductID = p.ProductID
ORDER BY r.Restock_Date, r.StoreID;

-- ============================================================
-- BONUS QUERY F: Average transaction value per store
-- ============================================================
SELECT
    s.StoreID,
    COALESCE(bm.Address, w.Url) AS StoreLocation,
    COALESCE(bm.State, 'WEB') AS State,
    COUNT(DISTINCT t.TransactionID) AS TotalTransactions,
    ROUND(SUM(i.QuantityPurchased * i.UnitPriceAtSale) /
          COUNT(DISTINCT t.TransactionID), 2) AS AvgTransactionValue,
    SUM(i.QuantityPurchased * i.UnitPriceAtSale) AS TotalRevenue
FROM Transaction t
JOIN Processing pr  ON t.TransactionID = pr.TransactionID
JOIN Store s        ON pr.StoreID = s.StoreID
LEFT JOIN BrickAndMotor bm ON s.StoreID = bm.StoreID
LEFT JOIN Web w            ON s.StoreID = w.StoreID
JOIN Included i    ON t.TransactionID = i.TransactionID
GROUP BY s.StoreID, COALESCE(bm.Address, w.Url), COALESCE(bm.State, 'WEB')
ORDER BY AvgTransactionValue DESC;

-- ============================================================
-- BONUS QUERY G: Products sold at the web store but NOT at
--   any physical store (web-exclusive catalog check)
-- ============================================================
SELECT
    p.ProductID,
    p.Name,
    p.Brand,
    inv.UnitPrice AS WebPrice,
    inv.Quantity  AS WebStock
FROM Inventory inv
JOIN Products p ON inv.ProductID = p.ProductID
WHERE inv.StoreID = 8   -- Web store
  AND inv.ProductID NOT IN (
      SELECT ProductID FROM Inventory
      WHERE StoreID != 8
  );

-- ============================================================
-- BONUS QUERY H: Vendor supply coverage —
--   how many products does each vendor supply?
-- ============================================================
SELECT
    v.SupplierID,
    v.SupplierName,
    COUNT(s.ProductID) AS NumProductsSupplied,
    GROUP_CONCAT(p.Name ORDER BY p.Name SEPARATOR ' | ') AS ProductList
FROM Vendors v
JOIN Supply s   ON v.SupplierID = s.SupplierID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY v.SupplierID, v.SupplierName
ORDER BY NumProductsSupplied DESC;

