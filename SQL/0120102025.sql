-- 20/10/2025
/**
### Ngữ cảnh

Trong cơ sở dữ liệu **AdventureWorks**, bạn là một nhà phân tích muốn hiểu rõ hơn về **tổng doanh số** 
và **số lượng giao dịch** của các sản phẩm được bán. 
Điều này rất quan trọng để xác định các sản phẩm bán chạy nhất và lên kế hoạch cho chiến lược tồn kho hoặc khuyến mãi.

### Yêu cầu

Sử dụng các bảng `Sales.SalesOrderDetail` và `Production.Product`, hãy viết một truy vấn SQL để:

1.  **Tính tổng số lượng** (`OrderQty`) và **tổng doanh thu** (sử dụng công thức `OrderQty * UnitPrice`) cho **mỗi sản phẩm**.
2.  Hiển thị `ProductID`, `Name` (tên sản phẩm), `TotalQuantity` (tổng số lượng bán) và `TotalRevenue` (tổng doanh thu).
3.  **Sắp xếp** kết quả theo `TotalRevenue` **giảm dần**.

### Gợi ý

  * Sử dụng `JOIN` để kết nối hai bảng.
  * Sử dụng hàm tổng hợp (`SUM`) và mệnh đề `GROUP BY`.
  * Sử dụng `AS` để đặt tên cột mới.
**/
--------------------------------------------------------------------------------------------------------
-- 1
SELECT 
	S.ProductID AS ProductID,
	P.Name AS ProductName,
	SUM(S.OrderQty) AS TotalQuantity,
	FORMAT(SUM(S.LineTotal),'N2') AS TotalRevenue
FROM Sales.SalesOrderDetail S
JOIN Production.Product P ON S.ProductID = P.ProductID
GROUP BY 
	S.ProductID, P.Name
ORDER BY
	TotalRevenue DESC;