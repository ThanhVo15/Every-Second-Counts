SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Customer', 'SalesOrderHeader', 'SalesOrderDetail');

SELECT 
	P.PersonType,
	SUM(SOH.TotalDue) AS TotalRevenue,
	SUM(SOD.OrderQty) AS TotalQuantity,
	COUNT(DISTINCT SOH.SalesOrderID) AS TotalOrder,
	AVG(SOH.TotalDue) AS AverageRevenue
FROM Person.Person as P
JOIN Sales.SalesOrderHeader as SOH
	ON P.BusinessEntityID = SOH.CustomerID
JOIN Sales.SalesOrderDetail as SOD
	ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY P.PersonType
ORDER BY TotalRevenue DESC;