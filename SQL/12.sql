-- SELECT * FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME IN ('BillOfMaterials', 'Product', 'ProductInventory');

SELECT 
	BOM.ComponentID,
	P.Name AS ComponentName,
	SUM(bom.PerAssemblyQty) AS TongSoLuong,
	AVG(PI.Quantity) AS TrungBinhTonKho
FROM Production.BillOfMaterials BOM
JOIN Production.Product P
	ON BOM.ComponentID = P.ProductID
JOIN Production.ProductInventory PI
	ON BOM.ComponentID = PI.ProductID
GROUP BY BOM.ComponentID, P.Name
ORDER BY TongSoLuong DESC;