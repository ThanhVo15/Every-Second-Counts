/***
# Ngày 6 - Daily Learning Challenge

🧩 **PART 1: SQL PRACTICE (AdventureWorks)**

1. **Mô tả bài toán thực tế**: Là Data Engineer tại AdventureWorks, bạn cần xây dựng data mart nhỏ để phân tích hành vi mua sắm (market basket analysis) thông qua các sản phẩm thường mua cùng nhau (co-purchase), kết hợp với dữ liệu khách hàng và inventory để đề xuất sản phẩm cá nhân hóa và dự báo nhu cầu tồn kho dựa trên tần suất co-purchase, nhằm tối ưu hóa khuyến mãi và quản lý hàng tồn.

2. **Mục tiêu học tập**: Thành thạo kỹ năng market basket analysis với SQL (áp dụng self-join cho pair items), xử lý dữ liệu lớn với advanced aggregation và ranking, xây dựng ETL mini với dynamic queries hoặc pivot để tạo data mart hỗ trợ recommendation system.

3. **Gợi ý tư duy**: Sử dụng self-join trên Sales.SalesOrderDetail để tìm pair sản phẩm trong cùng order, join với Sales.SalesOrderHeader, Sales.Customer, và Production.ProductInventory. Áp dụng CTE để tính support/count co-purchase, window function để rank top pairs per khách hàng hoặc category. Thêm logic dự báo inventory (nhu cầu = tần suất co-purchase * avg order qty), và có thể dùng PIVOT cho matrix co-purchase nếu cần báo cáo.

4. **Truy vấn SQL tối ưu**:
   ```sql
   WITH OrderItems AS (
       SELECT 
           sod.SalesOrderID,
           sod.ProductID,
           p.Name AS ProductName,
           COUNT(*) OVER (PARTITION BY sod.SalesOrderID) AS ItemsPerOrder
       FROM Sales.SalesOrderDetail sod
       JOIN Production.Product p ON sod.ProductID = p.ProductID
       WHERE ItemsPerOrder > 1  -- Chỉ order có nhiều item
   ),
   CoPurchasePairs AS (
       SELECT 
           a.SalesOrderID,
           a.ProductID AS ProductA,
           b.ProductID AS ProductB,
           a.ProductName AS NameA,
           b.ProductName AS NameB,
           COUNT(*) OVER (PARTITION BY a.ProductID, b.ProductID) AS CoPurchaseCount
       FROM OrderItems a
       JOIN OrderItems b ON a.SalesOrderID = b.SalesOrderID AND a.ProductID < b.ProductID  -- Tránh duplicate pairs
   ),
   TopPairsPerCustomer AS (
       SELECT 
           soh.CustomerID,
           cpp.NameA + ' & ' + cpp.NameB AS PairName,
           cpp.CoPurchaseCount,
           ROW_NUMBER() OVER (PARTITION BY soh.CustomerID ORDER BY cpp.CoPurchaseCount DESC) AS RankPair
       FROM CoPurchasePairs cpp
       JOIN Sales.SalesOrderHeader soh ON cpp.SalesOrderID = soh.SalesOrderID
   ),
   DuBaoInventory AS (
       SELECT 
           p.ProductID,
           SUM(pi.Quantity) AS TongTonKho,
           (SELECT SUM(CoPurchaseCount) FROM CoPurchasePairs WHERE ProductA = p.ProductID OR ProductB = p.ProductID) * AVG(sod.OrderQty) AS NhuCauDuBao
       FROM Production.Product p
       JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
       JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
       GROUP BY p.ProductID
   ),
   PersonalizedRec AS (
       SELECT 
           c.CustomerID,
           tpc.PairName,
           tpc.CoPurchaseCount,
           di.TongTonKho,
           di.NhuCauDuBao,
           CASE 
               WHEN di.TongTonKho < di.NhuCauDuBao THEN 'High Demand - Stock Up'
               ELSE 'Normal'
           END AS RecStatus
       FROM Sales.Customer c
       JOIN TopPairsPerCustomer tpc ON c.CustomerID = tpc.CustomerID
       CROSS APPLY (
           SELECT TOP 1 ProductID FROM Production.Product 
           WHERE Name = SUBSTRING(tpc.PairName, 1, CHARINDEX(' & ', tpc.PairName) - 1)  -- Lấy ProductA
       ) AS pa
       JOIN DuBaoInventory di ON pa.ProductID = di.ProductID
       WHERE tpc.RankPair <= 5  -- Top 5 pairs per customer
   )
   SELECT * FROM PersonalizedRec
   ORDER BY CustomerID, CoPurchaseCount DESC;
   ```
   **Giải thích chi tiết**:
   - CTE `OrderItems`: Lọc order có nhiều item, tính items per order với window.
   - CTE `CoPurchasePairs`: Self-join để tạo pairs, đếm co-purchase với window, condition a < b tránh pair lặp.
   - CTE `TopPairsPerCustomer`: Join với header để gán customer, rank pairs với ROW_NUMBER().
   - CTE `DuBaoInventory`: Tính nhu cầu dự báo từ tổng co-count * avg qty, sử dụng correlated subquery.
   - CTE `PersonalizedRec`: Cross apply để parse pair và link inventory, CASE cho recommendation status.
   - Query chính: Select từ personalized, order để dễ đọc. Kỹ thuật nâng cao: Self-join for pairs, cross apply for dynamic parse, multi-window, correlated subqueries.

5. **Hướng tối ưu**: Tạo index trên SalesOrderID và ProductID (CREATE INDEX idx_SalesOrderDetail_OrderProduct ON Sales.SalesOrderDetail(SalesOrderID, ProductID)). Partition table SalesOrderDetail theo SalesOrderID range cho self-join lớn. Materialized view cho CoPurchasePairs: CREATE MATERIALIZED VIEW vw_CoPairs AS (SELECT FROM CoPurchasePairs), refresh hàng tuần. Scale với big data bằng Redshift hoặc BigQuery với clustering trên ProductID, giảm join time từ quadratic xuống linear qua optimization.

6. **Insight & ứng dụng thực tế**: Data mart này cung cấp insight về bundle sản phẩm phổ biến, giúp marketing tạo promo và inventory tránh thiếu hụt. Trong ETL pipeline (như Luigi hoặc Airflow), schedule query để update recommendation engine, integrate với Tableau cho viz network graph pairs và dashboard rec per customer, nâng cao doanh số cross-sell.

***/

-- Query để xây dựng data mart cho Market Basket Analysis và Recommendation
WITH OrderItems AS (
    SELECT 
        sod.SalesOrderID,
        sod.ProductID,
        p.Name AS ProductName
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    -- Lọc sau bằng HAVING vì window cần full data
),
FilteredOrderItems AS (
    SELECT *
    FROM OrderItems
    WHERE (SELECT COUNT(*) FROM OrderItems oi2 WHERE oi2.SalesOrderID = OrderItems.SalesOrderID) > 1  -- Lọc order có >1 item (subquery thay window cho compatibility)
),
CoPurchasePairs AS (
    SELECT 
        a.SalesOrderID,
        a.ProductID AS ProductA,
        b.ProductID AS ProductB,
        a.ProductName AS NameA,
        b.ProductName AS NameB,
        COUNT(*) OVER (PARTITION BY a.ProductID, b.ProductID) AS CoPurchaseCount  -- Đếm tần suất pair
    FROM FilteredOrderItems a
    JOIN FilteredOrderItems b ON a.SalesOrderID = b.SalesOrderID AND a.ProductID < b.ProductID  -- Self-join, tránh duplicate
),
TopPairsPerCustomer AS (
    SELECT 
        soh.CustomerID,
        cpp.NameA + ' & ' + cpp.NameB AS PairName,
        cpp.CoPurchaseCount,
        ROW_NUMBER() OVER (PARTITION BY soh.CustomerID ORDER BY cpp.CoPurchaseCount DESC) AS RankPair  -- Rank top pairs
    FROM CoPurchasePairs cpp
    JOIN Sales.SalesOrderHeader soh ON cpp.SalesOrderID = soh.SalesOrderID
),
DuBaoInventory AS (
    SELECT 
        p.ProductID,
        SUM(pi.Quantity) AS TongTonKho,  -- Tổng tồn kho
        (SELECT SUM(CoPurchaseCount) FROM CoPurchasePairs WHERE ProductA = p.ProductID OR ProductB = p.ProductID) * 
        (SELECT AVG(sod.OrderQty) FROM Sales.SalesOrderDetail sod WHERE sod.ProductID = p.ProductID) AS NhuCauDuBao  -- Dự báo: co-count * avg qty
    FROM Production.Product p
    JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
    GROUP BY p.ProductID
),
PersonalizedRec AS (
    SELECT 
        c.CustomerID,
        tpc.PairName,
        tpc.CoPurchaseCount,
        di.TongTonKho,
        di.NhuCauDuBao,
        CASE 
            WHEN di.TongTonKho < di.NhuCauDuBao THEN 'High Demand - Stock Up'
            ELSE 'Normal'
        END AS RecStatus
    FROM Sales.Customer c
    JOIN TopPairsPerCustomer tpc ON c.CustomerID = tpc.CustomerID
    CROSS APPLY (
        SELECT TOP 1 ProductID FROM Production.Product 
        WHERE Name = SUBSTRING(tpc.PairName, 1, CHARINDEX(' & ', tpc.PairName) - 1)  -- Parse ProductA từ pair name
    ) AS pa
    JOIN DuBaoInventory di ON pa.ProductID = di.ProductID
    WHERE tpc.RankPair <= 5  -- Top 5 per customer
)
SELECT * FROM PersonalizedRec
ORDER BY CustomerID, CoPurchaseCount DESC;  -- Final output cho data mart