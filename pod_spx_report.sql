WITH POD_SPX_Report AS
(
SELECT 
oo.waybill_no AS Waybill_No,
oo.sender_name AS Warehouse,
DATETIME(oo.input_time, 'Asia/Jakarta')Order_Date,
oo.order_no AS Order_ID,
ww.recipient_name AS Buyer_Name,
ww.recipient_district_name AS District,
ww.recipient_city_name AS City,
ma.mitra_by_area AS Area,
ww.recipient_address AS Buyer_Address,
ww.recipient_cellphone AS Buyer_Phone,
t0.option_name AS Service_Type,
ww.cod_amount AS COD_Amount,
t1.option_name as Payment_Type, 
oo.item_calculated_weight AS Weight,
DATETIME(oo.pickup_time, 'Asia/Jakarta')Pickup_Time,
t2.option_name as Order_Status,
DATETIME(ww.pod_scan_time, 'Asia/Jakarta')POD_Time,
DATE(rr.return_record_time, 'Asia/Jakarta')Return_Time,
--t3.label_bahasa AS Return_Confirm_Status,
DATE(rr.return_confirm_record_time, 'Asia/Jakarta')Confirm_Return_Time,
DATE(rr.return_pod_record_time, 'Asia/Jakarta')Return_POD_Time,

CASE WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t2.option_name NOT IN ('Cancel Order','Picked Up') THEN "Not Picked Up"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NOT NULL THEN "Delivered"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NOT NULL AND DATETIME(rr.return_confirm_record_time, 'Asia/Jakarta') IS NULL AND DATETIME(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Delivered"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NOT NULL AND DATETIME(rr.return_confirm_record_time, 'Asia/Jakarta') IS NOT NULL AND DATETIME(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Delivered"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t2.option_name IN ('Cancel Order') THEN "Cancel Order"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATETIME(rr.return_confirm_record_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Delivery Process"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATETIME(rr.return_confirm_record_time, 'Asia/Jakarta') IS NOT NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Return Process"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATETIME(rr.return_confirm_record_time, 'Asia/Jakarta') IS NOT NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NOT NULL THEN "Returned"
     END AS POD_Status,

CASE WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL THEN "Not Signed Yet"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t2.option_name IN ('Cancel Order') THEN "Not Signed Yet"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NOT NULL THEN "Signed"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_confirm_record_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Not Signed Yet"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NOT NULL AND DATE(rr.return_confirm_record_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Signed"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_confirm_record_time, 'Asia/Jakarta') IS NOT NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NULL THEN "Not Signed Yet"
     WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(ww.pod_scan_time, 'Asia/Jakarta') IS NULL AND DATE(rr.return_confirm_record_time, 'Asia/Jakarta') IS NOT NULL AND DATE(rr.return_pod_record_time, 'Asia/Jakarta') IS NOT NULL THEN "Signed"
     END AS Remarks,

sr.option_name AS Order_Source

FROM `datawarehouse_idexp.order_order`oo
LEFT join `grand-sweep-324604.datawarehouse_idexp.waybill_waybill` ww on oo.waybill_no = ww.waybill_no and ww.deleted = '0'
LEFT JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_return_bill` rr ON ww.waybill_no = rr.waybill_no AND rr.deleted = '0'

-- FROM `warehouse_idexp.ide_order_order` oo
-- LEFT JOIN `warehouse_idexp.ide_waybill_waybill` ww on oo.waybill_no = ww.waybill_no and ww.deleted = '0'
-- LEFT JOIN `warehouse_idexp.ide_waybill_return_bill` rr ON ww.waybill_no = rr.waybill_no AND rr.deleted = '0'

left join `grand-sweep-324604.datawarehouse_idexp.system_option` sr on oo.order_source  = sr.option_value and sr.type_option = 'orderSource'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t1 on oo.payment_type  = t1.option_value and t1.type_option = 'paymentType'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t0 on oo.service_type  = t0.option_value and t0.type_option = 'serviceType'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t2 on oo.order_status  = t2.option_value and t2.type_option = 'orderStatus'


LEFT JOIN `datamart_idexp.masterdata_backlog_city_to_ma` ma ON ww.recipient_district_name = ma.destination AND ww.recipient_city_name = ma.destination_city 

WHERE DATE(oo.input_time,'Asia/Jakarta') BETWEEN '2022-09-01' AND '2023-05-07'
-- >= '2022-08-31 17:00:00' and oo.input_time <= '2023-03-23 16:59:59'

AND sr.option_name IN ('Shopee Express')
AND oo.order_no NOT IN ("ID200018099679","IDB006713271700",	"IDB000573937072",	"IDB004453258479",	"IDB005164212502",	"IDB005491164377",	"IDB006386909442",	"IDB002427447393",	"IDB005110962820",	"IDB005994668980",	"IDB005020283904",	"IDB002496432050",	"IDB000957598125",	"IDB004853689400",	"IDB004909848393",	"IDB001660113365",	"IDB006690120033",	"IDB000815910059",	"IDB008374378565",	"IDB004928640742",	"IDB006339959088",	"IDB008723922339",	"IDB003683425498",	"IDB001246701042",	"IDB000633430837",	"IDB000546307846",	"IDB004976904196",	"IDB000106244144",	"IDB000164464180",	"IDB006904250245",	"IDB007567110676",	"IDB000636413343",	"IDB008674759886",	"IDB005275132558",	"IDB004104918515",	"IDB007065810791",	"IDB006592195188",	"IDB001704244127")

-- AND oo.waybill_no IN (


),
spx_remove_duplicate AS (
SELECT
Waybill_No,
Warehouse,
Order_Date,
Order_ID,
Buyer_Name,
District,
City,
Area,
Buyer_Address,
Buyer_Phone,
Service_Type,
COD_Amount,
Payment_Type AS Metode_Pembayaran, 
Weight,
POD_Time,
POD_Status,
Remarks,
Pickup_Time,
Order_Status,
Return_Time,
--Return_Confirm_Status,
Confirm_Return_Time,
Return_POD_Time,
Order_Source

FROM POD_SPX_Report
QUALIFY ROW_NUMBER() OVER (PARTITION BY Waybill_No ORDER BY Return_POD_Time DESC, Confirm_Return_Time DESC, Return_Time DESC, Pickup_Time DESC, POD_Time DESC, Order_Date DESC, 1 DESC
)=1)

SELECT * FROM spx_remove_duplicate



GROUP BY Waybill_No,
Warehouse,
Order_Date,
Order_ID,
Buyer_Name,
District,
City,
Area,
Buyer_Address,
Buyer_Phone,
Service_Type,
COD_Amount,
Metode_Pembayaran, 
Weight,
POD_Time,
POD_Status,
Remarks,
Pickup_Time,
Order_Status,
Return_Time,
--Return_Confirm_Status,
Confirm_Return_Time,
Return_POD_Time,
Order_Source

ORDER BY Order_Date ASC
