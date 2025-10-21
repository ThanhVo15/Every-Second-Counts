-- 19/10/2025
/**

### 🎯 Mục tiêu

Bạn là một nhà phân tích đang nghiên cứu xu hướng mua hàng của khách hàng. 
Hãy viết một truy vấn để xác định **Top 5 Khách hàng** (theo `CustomerID`) dựa trên **Tổng số lượng sản phẩm** mà họ đã mua.

### 📜 Yêu cầu

1.  Sử dụng bảng `Sales.SalesOrderHeader` (chứa thông tin đơn hàng) 
và `Sales.SalesOrderDetail` (chứa chi tiết sản phẩm trong đơn hàng).
2.  Tính **Tổng số lượng sản phẩm** (`OrderQty`) đã mua cho mỗi khách hàng (`CustomerID`).
3.  Sắp xếp kết quả theo **Tổng số lượng sản phẩm** giảm dần.
4.  Chỉ lấy **5 hàng đầu tiên**.

### 💡 Gợi ý về Cột và Bảng

| Tên Bảng | Cột Liên Quan | Mục đích |
| :--- | :--- | :--- |
| `Sales.SalesOrderHeader` | `CustomerID` | Mã Khách hàng |
| | `SalesOrderID` | Mã Đơn hàng |
| `Sales.SalesOrderDetail` | `SalesOrderID` | Mã Đơn hàng (để nối) |
| | `OrderQty` | Số lượng sản phẩm trong đơn hàng |
**/
--------------------------------------------------------------------------------------------------------
-- 1
SELECT TOP 5
	SOH.CustomerID,
	SUM(SOD.OrderQty) AS TotalQty,
	SUM(SOH.TotalDue) AS TotalRev
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY
	SOH.CustomerID	
ORDER BY
	TotalQty DESC;

