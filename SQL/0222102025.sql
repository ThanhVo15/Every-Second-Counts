-- 21/10/2025
/**

### 📌 Mức độ: Dễ - Trung bình (Ước tính: 15-20 phút)

### 📋 Ngữ cảnh & Mục tiêu Phân tích

Trong phân tích dữ liệu bán hàng, việc xác định các **khách hàng có giá trị cao (High-Value Customers - HVC)** 
là rất quan trọng để tối ưu hóa chiến lược marketing và duy trì mối quan hệ. 
Một tiêu chí phổ biến để xác định HVC là những khách hàng có tổng doanh thu (tổng số lượng sản phẩm * đơn giá) 
vượt qua một ngưỡng nhất định trong một khoảng thời gian.

**Yêu cầu:**

Viết một truy vấn SQL từ cơ sở dữ liệu **AdventureWorks** để:

1.  **Tính tổng doanh thu (Total Revenue)** cho **mỗi khách hàng** trong năm **2013**.
    * Sử dụng bảng `Sales.SalesOrderHeader` (cho ID Khách hàng, ID Đơn hàng, Ngày đặt hàng) 
	và bảng `Sales.SalesOrderDetail` (cho Số lượng và Đơn giá).
    * Doanh thu được tính là $\sum (\text{OrderQty} \times \text{UnitPrice})$.
2.  **Lọc** ra những khách hàng có **Tổng doanh thu** vượt quá **$50,000**.
3.  **Sắp xếp** kết quả theo Tổng doanh thu **giảm dần**.
4.  **Chỉ hiển thị** `CustomerID` và `TotalRevenue`.

### 🔑 Gợi ý về Bảng (AdventureWorks)

| Tên Bảng | Cột Quan trọng | Mục đích |
| :--- | :--- | :--- |
| `Sales.SalesOrderHeader` | `CustomerID`, `SalesOrderID`, `OrderDate` | Thông tin về đơn hàng (ID khách hàng, ngày đặt hàng) |
| `Sales.SalesOrderDetail` | `SalesOrderID`, `OrderQty`, `UnitPrice` | Chi tiết đơn hàng (số lượng, giá) |
**/
--------------------------------------------------------------------------------------------------------
-- 1
WITH FinalTable AS (
	SELECT 
		YEAR(SOH.OrderDate) AS OrderYear,
		SOH.CustomerID AS CustomerID,
		SUM(SOD.OrderQty * SOD.UnitPrice) AS TotalRevenue
	FROM Sales.SalesOrderHeader SOH
	JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
	WHERE YEAR(SOH.OrderDate) = 2013
	GROUP BY SOH.CustomerID, YEAR(SOH.OrderDate)
)
SELECT
	CustomerID,
	FORMAT(TotalRevenue, 'N2')
FROM FinalTable
WHERE TotalRevenue > 50000
ORDER BY TotalRevenue Desc;