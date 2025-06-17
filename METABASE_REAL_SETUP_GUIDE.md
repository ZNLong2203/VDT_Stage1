# 🎯 METABASE SETUP GUIDE - VDT STAGE 1

## 📊 Hướng dẫn tạo Dashboard thực tế với Metabase

### 🚀 **BƯỚC 1: Tạo Custom Questions**

#### 1.1 Tạo Number Cards (KPIs)
```sql
-- Query 1: Total Orders
SELECT COUNT(*) as value
FROM ods_orders 
WHERE is_deleted = false;
```
**Setup:**
- Click "New" → "Question" → "Custom Question"
- Paste query → Run
- Visualization: **Number**
- Title: "Total Orders"
- Save as "Total Orders"

```sql
-- Query 2: Total Revenue  
SELECT ROUND(SUM(payment_value), 2) as value
FROM ods_payments p
JOIN ods_orders o ON p.order_id = o.order_id
WHERE p.is_deleted = false 
    AND o.is_deleted = false
    AND o.order_status = 'delivered';
```
**Setup:**
- Visualization: **Number**
- Title: "Total Revenue"
- Format: Currency ($)

#### 1.2 Tạo Pie Chart (Order Status)
```sql
SELECT 
    order_status,
    COUNT(*) as count
FROM ods_orders 
WHERE is_deleted = false
GROUP BY order_status;
```
**Setup:**
- Visualization: **Pie Chart**
- Dimension: order_status
- Metric: count
- Title: "Order Status Distribution"

#### 1.3 Tạo Bar Chart (Payment Methods)
```sql
SELECT 
    payment_type,
    COUNT(*) as transactions
FROM ods_payments 
WHERE is_deleted = false
GROUP BY payment_type
ORDER BY transactions DESC;
```
**Setup:**
- Visualization: **Bar Chart**
- X-axis: payment_type
- Y-axis: transactions
- Title: "Payment Methods"

#### 1.4 Tạo Line Chart (Daily Trend)
```sql
SELECT 
    DATE(order_purchase_timestamp) as date,
    COUNT(*) as orders
FROM ods_orders 
WHERE is_deleted = false
    AND order_purchase_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY DATE(order_purchase_timestamp)
ORDER BY date;
```
**Setup:**
- Visualization: **Line Chart**
- X-axis: date
- Y-axis: orders
- Title: "Daily Orders (7 Days)"

---

### 🎨 **BƯỚC 2: Tạo Dashboard**

1. **Tạo Dashboard mới:**
   - Click "New" → "Dashboard"
   - Tên: "VDT Stage 1 - Executive Overview"

2. **Thêm Questions vào Dashboard:**
   - Click "Add a question"
   - Chọn các questions đã tạo
   - Arrange theo layout

3. **Layout đề xuất:**
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Total Orders│Total Revenue│   Active    │  Avg Order  │
│   (Number)  │  (Number)   │ Customers   │   Value     │
│             │             │  (Number)   │  (Number)   │
├─────────────┴─────────────┼─────────────┴─────────────┤
│     Order Status          │    Payment Methods        │
│     (Pie Chart)           │    (Bar Chart)            │
├───────────────────────────┼───────────────────────────┤
│     Daily Orders          │   Product Categories      │
│     (Line Chart)          │    (Bar Chart)            │
├───────────────────────────┴───────────────────────────┤
│              Top Customers Table                      │
│                 (Table)                               │
└───────────────────────────────────────────────────────┘
```

---

### 🔧 **BƯỚC 3: Customization**

#### 3.1 Number Cards
- **Size**: Medium hoặc Large
- **Color**: 
  - Total Orders: Blue
  - Total Revenue: Green  
  - Active Customers: Purple
  - Avg Order Value: Orange

#### 3.2 Pie Charts
- **Colors**: Metabase default hoặc custom
- **Show percentages**: Enable
- **Legend**: Right side

#### 3.3 Bar Charts
- **Orientation**: Vertical hoặc Horizontal
- **Show values**: On bars
- **Sort**: Descending by value

#### 3.4 Line Charts
- **Line style**: Smooth
- **Show dots**: Enable
- **Grid**: Light

---

### 📱 **BƯỚC 4: Responsive & Sharing**

#### 4.1 Mobile Optimization
- Test dashboard trên mobile
- Adjust card sizes nếu cần
- Stack vertically cho small screens

#### 4.2 Auto-refresh
- Dashboard settings → Auto-refresh
- Set interval: 5 minutes cho executive dashboard

#### 4.3 Sharing
- Click "Share" → "Public link" (nếu cần)
- Hoặc add users vào dashboard

---

### 🎯 **BƯỚC 5: Advanced Features**

#### 5.1 Filters
- Add date range filter:
  - Dashboard → Add filter → Date
  - Connect to timestamp fields

#### 5.2 Drill-down
- Click on chart elements để drill down
- Setup click behavior trong chart settings

#### 5.3 Alerts
- Set up alerts cho critical metrics
- Email notifications khi values thay đổi

---

### 🚨 **TROUBLESHOOTING**

#### Vấn đề thường gặp:

1. **Query không chạy:**
   - Check database connection
   - Verify table names và field names
   - Check permissions

2. **Chart không hiển thị đúng:**
   - Check data types
   - Verify aggregation functions
   - Check for NULL values

3. **Performance chậm:**
   - Add indexes cho frequently queried columns
   - Limit result sets với LIMIT
   - Use appropriate date ranges

---

### 📊 **DEMO SCRIPT (5 phút)**

**Slide 1: Overview (30s)**
- "Đây là dashboard real-time cho VDT Stage 1"
- "Hiển thị KPIs quan trọng từ pipeline CDC → Flink → StarRocks"

**Slide 2: KPIs (1 phút)**
- Point to Number cards
- "97,886 orders processed, $X revenue"
- "Real-time data từ StarRocks"

**Slide 3: Order Analysis (1.5 phút)**
- Show Pie chart: "98.56% delivered successfully"
- Show Bar chart: "Credit card là payment method phổ biến nhất"

**Slide 4: Trends (1.5 phút)**
- Show Line chart: "Daily order pattern"
- "Có thể thấy xu hướng tăng/giảm"

**Slide 5: Customer Insights (30s)**
- Show Table: "Top customers by revenue"
- "Data-driven insights cho business decisions"

---

### 🎨 **COLOR PALETTE**

```css
/* Consistent colors across dashboard */
Primary Blue: #1f77b4
Success Green: #2ca02c  
Warning Orange: #ff7f0e
Danger Red: #d62728
Info Purple: #9467bd
Gray: #7f7f7f
```

---

### ✅ **CHECKLIST BEFORE DEMO**

- [ ] All queries run successfully
- [ ] Charts display correctly
- [ ] Dashboard loads quickly
- [ ] Mobile responsive
- [ ] Colors are consistent
- [ ] Titles are clear
- [ ] Data is recent
- [ ] No error messages
- [ ] Auto-refresh working
- [ ] Demo script practiced

---

*🎯 Mục tiêu: Tạo dashboard professional, functional và impressive cho đánh giá VDT Stage 1!* 