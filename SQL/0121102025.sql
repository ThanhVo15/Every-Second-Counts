-- 21/10/2025
/**
### 🎯 Mục tiêu

Luyện tập kỹ năng sử dụng các hàm cửa sổ (`Window Functions`) và truy vấn con (`Subqueries`) 
để tính toán **tổng doanh thu hàng tháng** và **so sánh hiệu suất** của mỗi tháng với tháng trước đó.

### 📜 Tình huống/Yêu cầu

Sử dụng database **AdventureWorks**, hãy viết một truy vấn SQL để thực hiện các yêu cầu sau:

1.  **Tính tổng doanh thu (Total Revenue)** cho mỗi tháng trong năm **2014** 
(sử dụng cột `OrderDate` trong bảng `SalesOrderHeader`).
2.  **Tính toán Doanh thu tháng trước 
(Previous Month Revenue)**.
3.  **Tính toán Phần trăm thay đổi doanh thu (Revenue Change Percentage)** giữa tháng hiện tại và tháng trước, 
làm tròn đến 2 chữ số thập phân.

### 🔍 Dữ liệu Nguồn

  * **Bảng:** `Sales.SalesOrderHeader`
  * **Các cột cần thiết:**
      * `OrderDate` (Để xác định tháng/năm)
      * `TotalDue` (Để tính tổng doanh thu)

### 💡 Gợi ý

Sử dụng hàm cửa sổ **`LAG()`** để truy cập giá trị doanh thu của hàng (tháng) trước đó.

### 📝 Đầu ra Mong muốn

| OrderMonth | TotalRevenue | PreviousMonthRevenue | RevenueChangePercentage |
| :---: | :---: | :---: | :---: |
| 2014-01-01 | XXXXXX.XX | NULL | NULL |
| 2014-02-01 | YYYYYY.YY | XXXXXX.XX | ZZ.ZZ |
| ... | ... | ... | ... |
**/
--------------------------------------------------------------------------------------------------------
-- 1
SELECT 
	YEAR(OrderDate) AS OrderYear,
	MONTH(OrderDate) AS OrderMonth,
	SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2014
GROUP BY
		YEAR(OrderDate),
		MONTH(OrderDate)
ORDER BY
		MONTH(OrderDate);
-- 2,3 MoM
WITH MonthlyRevenue AS (
	SELECT 
		YEAR(OrderDate) AS OrderYear,
		MONTH(OrderDate) AS OrderMonth,
		SUM(TotalDue) AS TotalRevenue
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) = 2014
	GROUP BY
			YEAR(OrderDate),
			MONTH(OrderDate)
)
SELECT 
	OrderYear,
	OrderMonth,
	TotalRevenue,
	LAG(TotalRevenue,1,0) OVER (ORDER BY OrderMonth) AS PreviousMonthRevenue,
	ROUND(
		(TotalRevenue -LAG(TotalRevenue,1,0) OVER (ORDER BY OrderMonth)) *100 /
		NULLIF(LAG(TotalRevenue,1,0) OVER (ORDER BY OrderMonth),0),2
		) AS PercentChange
FROM MonthlyRevenue
ORDER BY
		MONTH(OrderMonth)
