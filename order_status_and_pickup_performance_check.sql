
WITH order_check AS (
SELECT 
oo.waybill_no as Waybill_No,
oo.ecommerce_order_no as ECommerce_Order_No, 
oo.order_no AS Order_No,
oo.sender_name AS Sender,
ot.option_name AS operation_type,
ol.operation_branch_name AS Alfastore_name,
DATETIME(ol.operation_time,'Asia/Jakarta') AS Time_Drop_to_Store,
t2.option_name AS order_status_from_orderline,
oo.sender_province_name AS Origin_Province,
oo.sender_city_name AS Origin_City,
oo.sender_district_name AS Origin_District,
CASE WHEN ww.shipping_time IS NOT NULL THEN ww.pickup_branch_name
WHEN ww.shipping_time IS NULL THEN oo.scheduling_target_branch_name 
END AS Origin_Branch,
ma.mitra_by_area AS Pickup_Area,
kw.kanwil_name AS Kanwil_Area,

t1.option_name as Order_status, 
 
DATETIME(oo.pickup_record_time,'Asia/Jakarta')Pickup_Time,

DATETIME(oo.input_time,'Asia/Jakarta')Input_Time,


DATETIME(oo.start_pickup_time, 'Asia/Jakarta') start_pickup_time,
DATETIME(oo.end_pickup_time, 'Asia/Jakarta') end_pickup_time,

DATETIME(ww.shipping_time,'Asia/Jakarta')Shipping_Time,
t12.label_bahasa AS Waybill_Status,
DATETIME(ww.pod_scan_time,'Asia/Jakarta')POD_Time,
CASE 
WHEN t1.option_name IN ('Cancel Order') THEN "Cancel Order"
-- WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NOT NULL THEN "Picked Up"
WHEN ot.option_name IS NOT NULL THEN ot.option_name
WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NULL AND st.option_name IN ('Pick up') AND t12.label_bahasa IS NULL THEN "Not Picked Up Yet"
WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NULL AND t12.label_bahasa IS NULL AND st.option_name IN ('Pick up') AND t1.option_name NOT IN ('Picked Up','Cancel Order') THEN "Not Picked Up Yet"
    WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NULL AND st.option_name IN ('Drop off') AND t12.label_bahasa IS NULL THEN "Not Dropped Off Yet"
    WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NULL AND t12.label_bahasa IS NULL AND st.option_name IN ('Drop off') AND t1.option_name NOT IN  ('Picked Up','Cancel Order') THEN "Not Dropped Off Yet"
WHEN DATETIME(ww.shipping_time,'Asia/Jakarta') IS NOT NULL AND t12.label_bahasa IS NOT NULL AND t1.option_name IN ('Picked Up') THEN "Picked Up"
WHEN DATETIME(oo.pickup_record_time,'Asia/Jakarta') IS NULL AND DATETIME(ww.shipping_time,'Asia/Jakarta') IS NOT NULL THEN "Picked Up"
END AS Order_Status_FInal, 
CASE 
WHEN ol.operation_branch_name IS NOT NULL THEN ol.operation_branch_name
WHEN ol.operation_branch_name IS NULL THEN NULL
END AS Remarks,
-- t4.register_reason_bahasa as Pickup_Failure_Reason,
st.option_name AS Service_Type,
sr.option_name AS Order_Source,
DATETIME(oo.cancel_time, 'Asia/Jakarta')Time_Cancelled,
CASE 
  WHEN oo.pickup_time IS NULL AND t1.option_name IN ('Cancel Order') THEN date_diff(current_date('Asia/Jakarta'), DATE(oo.cancel_time, 'Asia/Jakarta'), DAY)
  END AS Cancel_Time_to_Date,

-----------------------scheduling_to_branch_and_courier_status--------------------------
   CASE 
     WHEN DATETIME(oo.input_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "OnTime Schedule"
     WHEN DATETIME(oo.input_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') >= DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "Late Schedule"
     WHEN DATETIME(oo.input_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL THEN "Late Schedule"
     WHEN DATETIME(oo.input_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Yet"
     END AS Scheduling_To_Branch_Status,
  --  DATE_DIFF(DATETIME(oo.scheduling_time, 'Asia/Jakarta'), DATETIME(oo.input_time, 'Asia/Jakarta'), HOUR) AS Order_Scheduling_Branch_Duration,

-- TIME_DIFF(TIME(a.scheduling_courier_time, 'Asia/Jakarta'), TIME(a.scheduling_time, 'Asia/Jakarta'), HOUR) AS Scheduling_Branch_to_Courier_Duration,

CASE 
   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name <> oo.pickup_branch_name THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') >= DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') <= DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') > DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name IS NULL THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') <= DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') > DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND oo.scheduling_target_branch_name IS NOT NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Yet"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND oo.scheduling_target_branch_name IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Branch Yet"
  END AS Scheduling_to_Courier_Status,

--------------------------------pickup_performance_by_start_pickup_time_+1day----------------------------------------------

CASE 
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND st.option_name in ('Drop off') AND DATETIME(oo.pickup_time, 'Asia/Jakarta') <= DATE_ADD(DATE(oo.input_time, 'Asia/Jakarta'), INTERVAL 2 DAY)THEN "Not Late"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND st.option_name in ('Drop off') AND t1.option_name NOT IN ('Cancel Order') AND CURRENT_DATE('Asia/Jakarta') > DATE_ADD(DATE(oo.input_time, 'Asia/Jakarta'), INTERVAL 2 DAY) THEN "Late Dropped Off"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND t1.option_name NOT IN ('Cancel Order') AND DATETIME(oo.pickup_time, 'Asia/Jakarta') <= DATE_ADD(DATETIME(oo.start_pickup_time, 'Asia/Jakarta'), INTERVAL 1 DAY) THEN "Not Late"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND t1.option_name NOT IN ('Cancel Order') AND DATETIME(oo.pickup_time, 'Asia/Jakarta') > DATE_ADD(DATETIME(oo.start_pickup_time, 'Asia/Jakarta'), INTERVAL 1 DAY) THEN "Late"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t1.option_name NOT IN ('Cancel Order') AND CURRENT_DATETIME('Asia/Jakarta') <= DATE_ADD(DATETIME(oo.start_pickup_time, 'Asia/Jakarta'), INTERVAL 1 DAY) THEN "Not Pickup Yet (Not Late)"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t1.option_name NOT IN ('Cancel Order') AND CURRENT_DATETIME('Asia/Jakarta') > DATE_ADD(DATETIME(oo.start_pickup_time, 'Asia/Jakarta'), INTERVAL 1 DAY) THEN "Late"
        WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t1.option_name IN ('Cancel Order') THEN 'Cancel Order'
    END AS Pickup_Performance,

-------------mapping_late_pickup_reason----------------
CASE 
WHEN t4.register_reason_bahasa IS NULL THEN lpr.late_pickup_reason
ELSE t4.register_reason_bahasa
END AS Pickup_Failure_Reason,

DATETIME (oo.pickup_failure_time, 'Asia/Jakarta') AS Pickup_Failure_Attempt,

CASE 
WHEN t4.register_reason_bahasa IS NULL THEN pf2.problem_factor
ELSE pf1.problem_factor
END AS Late_Pickup_Factor,

CASE 
WHEN t4.register_reason_bahasa IS NULL THEN pf2.problem_category
ELSE pf1.problem_category
END AS Late_Pickup_Category,


FROM `grand-sweep-324604.datawarehouse_idexp.order_order` oo
LEFT JOIN `datawarehouse_idexp.order_line` ol ON oo.waybill_no = ol.waybill_no
LEFT join `grand-sweep-324604.datawarehouse_idexp.waybill_waybill` ww on oo.waybill_no = ww.waybill_no and ww.deleted = '0'
AND DATE(ww.shipping_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -95 DAY))
LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_problem_piece` ps ON ww.waybill_no = ps.waybill_no AND ps.problem_type IN ('02')
AND DATE(ps.operation_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -95 DAY))
LEFT JOIN `grand-sweep-324604.datawarehouse_idexp.res_dict_line` t12 ON ww.waybill_status = t12.value AND t12.dict_id = 14 AND t12.deleted='0'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t1 on oo.order_status  = t1.option_value and t1.type_option = 'orderStatus'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t2 on ol.order_status  = t2.option_value and t2.type_option = 'orderStatus'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` sr on oo.order_source  = sr.option_value and sr.type_option = 'orderSource'
LEFT join `grand-sweep-324604.datawarehouse_idexp.res_problem_package` t4 on oo.pickup_failure_problem_code = t4.code and t4.deleted = '0'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` st on oo.service_type  = st.option_value and st.type_option = 'serviceType'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` ot on ol.operation_type  = ot.option_value and ot.type_option = 'operationType'
LEFT JOIN `datamart_idexp.masterdata_backlog_city_to_ma` ma ON oo.sender_district_name = ma.destination AND oo.sender_city_name = ma.destination_city 
LEFT JOIN `datamart_idexp.mitra_late_reason_pickup`lpr ON oo.waybill_no = lpr.waybill_no  
LEFT JOIN `datamart_idexp.mapping_kanwil_area` kw ON oo.sender_province_name = kw.province_name
LEFT JOIN `datamart_idexp.masterdata_mapping_problem_factor` pf1 ON oo.pickup_failure_problem_code = pf1.code
LEFT JOIN `datamart_idexp.masterdata_mapping_problem_factor` pf2 ON lpr.late_pickup_reason = pf2.register_reason_bahasa

-- WHERE oo.input_time >= '2022-10-06 17:00:00' and oo.input_time <= '2022-10-07 16:59:59'
WHERE DATE(oo.input_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -95 DAY)) 

AND oo.waybill_no IN (
"IDS900015875671",
"IDS900042755051",
"IDS900072206846"

)

QUALIFY ROW_NUMBER() OVER (PARTITION BY oo.waybill_no ORDER BY ww.update_time DESC)=1),

check_pickup AS (

SELECT 
Waybill_No,
ECommerce_Order_No,
Order_No,
Sender,
operation_type,
Alfastore_name,
Time_Drop_to_Store,
order_status_from_orderline,
Origin_Province,
Origin_City,
Origin_District,
Origin_Branch,
Pickup_Area,
Kanwil_Area,
Order_status,
Pickup_Time,
Input_Time,
-- start_pickup_time,
-- end_pickup_time,
Shipping_Time,
Waybill_Status,
-- POD_Time,
Order_Status_FInal,
Remarks,
-- Pickup_Failure_Reason
Service_Type,
Order_Source,
Time_Cancelled,
Cancel_Time_to_Date,
Scheduling_To_Branch_Status,
Scheduling_to_Courier_Status,
Pickup_Performance,
Pickup_Failure_Attempt,
CASE 
     WHEN Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "Late Schedule" AND Scheduling_to_Courier_Status = "Ontime Schedule to Courier" THEN "Late Schedule to Branch"
    WHEN Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "OnTime Schedule" AND Scheduling_to_Courier_Status = "Late Schedule to Courier" THEN "Late Schedule to Courier"
     WHEN Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "OnTime Schedule" AND Scheduling_to_Courier_Status = "Ontime Schedule to Courier" AND Shipping_Time IS NOT NULL THEN "Late Schedule to Courier"
     WHEN Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "OnTime Schedule" AND Scheduling_to_Courier_Status = "Ontime Schedule to Courier" AND Shipping_Time IS NULL THEN NULL
     WHEN Pickup_Failure_Reason IS NOT NULL THEN Pickup_Failure_Reason
     END AS Late_Pickup_Reason,

CASE 
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Cuaca buruk / bencana alam') THEN 'External' 
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Paket akan diproses dengan nomor resi yang baru','Di luar cakupan area cabang, akan dijadwalkan ke cabang lain','Melewati jam operasional cabang','Late Schedule to Branch','Late Schedule to Courier','Kurir tidak available','Late scan pickup') THEN 'IDE'
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Pengiriman akan menggunakan ekspedisi lain','Pengiriman dibatalkan','Pengirim akan mengantar paket ke cabang','Pengirim tidak ada di lokasi/toko','Alamat pengirim kurang jelas','Pengirim sedang mempersiapkan paket','Pengirim meminta pergantian jadwal','Paket belum ada/belum selesai dikemas','Pengirim tidak dapat dihubungi','Pengirim merasa tidak menggunakan iDexpress','Pengirim sedang libur','Pengirim sebagai dropshipper dan menunggu supplier','Paket pre order','Paket sedang disiapkan') THEN 'Pengirim'
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IS NULL THEN 'IDE'
END AS Late_Pickup_Factor,
CASE
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Cuaca buruk / bencana alam') THEN 'Uncontrollable'
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Paket akan diproses dengan nomor resi yang baru','Di luar cakupan area cabang, akan dijadwalkan ke cabang lain','Melewati jam operasional cabang','Late Schedule to Branch','Late Schedule to Courier','Kurir tidak available','Late scan pickup') THEN 'Controllable'
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IN ('Pengiriman akan menggunakan ekspedisi lain','Pengiriman dibatalkan','Pengirim akan mengantar paket ke cabang','Pengirim tidak ada di lokasi/toko','Alamat pengirim kurang jelas','Pengirim sedang mempersiapkan paket','Pengirim meminta pergantian jadwal','Paket belum ada/belum selesai dikemas','Pengirim tidak dapat dihubungi','Pengirim merasa tidak menggunakan iDexpress','Pengirim sedang libur','Pengirim sebagai dropshipper dan menunggu supplier','Paket pre order','Paket sedang disiapkan') THEN 'Uncontrollable'
WHEN Pickup_Performance = 'Late' AND Pickup_Failure_Reason IS NULL THEN 'Controllable'
END AS Late_Pickup_Category,
POD_Time,


FROM order_check
)

SELECT 
Waybill_No,
ECommerce_Order_No,
Order_No,
Sender,
Alfastore_name,
Time_Drop_to_Store,
Origin_Province,
Origin_City,
Origin_District,
Origin_Branch,
Pickup_Area,
Kanwil_Area,
Order_status,
Pickup_Time,
Input_Time,
-- start_pickup_time,
-- end_pickup_time,
Shipping_Time,
Order_Status_FInal,
Remarks,
Service_Type,
Order_Source,
Pickup_Performance,
Pickup_Failure_Attempt,
Late_Pickup_Reason,
CASE
  WHEN Pickup_Performance IN ("Late", "Not Pick Up Yet") AND Late_Pickup_Reason IS NULL THEN "No Reason"
  WHEN Late_Pickup_Reason IN ("Alamat pengirim kurang jelas","Alamat / telepon tidak lengkap") THEN "Alamat tidak lengkap"
  WHEN Late_Pickup_Reason IN ("Di luar cakupan area cabang, akan dijadwalkan ke cabang lain", "Melewati jam operasional cabang", "Late Schedule to Branch", "Late Schedule to Courier", "Kurir tidak available", "Late scan pickup") THEN "3PL Case"
  WHEN Late_Pickup_Reason IN ("Pengirim tidak dapat dihubungi") THEN "No telepon tidak dapat dihubungi"
  WHEN Late_Pickup_Reason IN ("Cuaca buruk / bencana alam","Pengirim merasa tidak menggunakan iDexpress","Pengiriman dibatalkan sebelum di pickup") THEN "Other"
  WHEN Late_Pickup_Reason IN ("Pengirim sedang mempersiapkan paket",
"Pengirim meminta pergantian jadwal", "Paket belum ada/belum selesai dikemas", "Pengirim sebagai dropshipper dan menunggu supplier", "Paket pre order") THEN "Paket belum siap"
  WHEN Late_Pickup_Reason IN ("Pengirim tidak ada di lokasi/toko", "Pengirim sedang libur") THEN "Pengirim tidak di tempat"
  WHEN Late_Pickup_Reason IN ("Pengirim akan mengantar paket ke cabang") THEN "Seller drop paket"
  WHEN Late_Pickup_Factor = "IDE" THEN "3PL Case"
  END AS Mapping_Reason_Shopee,

CASE
  WHEN Pickup_Performance IN ("Late", "Not Pick Up Yet") AND Late_Pickup_Reason IS NULL THEN "IDX"
  WHEN Late_Pickup_Reason IN ("Alamat pengirim kurang jelas") THEN "Seller"
  WHEN Late_Pickup_Reason IN ("Di luar cakupan area cabang, akan dijadwalkan ke cabang lain", "Melewati jam operasional cabang", "Late Schedule to Branch", "Late Schedule to Courier", "Kurir tidak available", "Late scan pickup") THEN "IDX"
  WHEN Late_Pickup_Reason IN ("Pengirim tidak dapat dihubungi","Alamat / telepon tidak lengkap") THEN "Seller"
  WHEN Late_Pickup_Reason IN ("Cuaca buruk / bencana alam") THEN "External"
  WHEN Late_Pickup_Reason IN ("Pengirim sedang mempersiapkan paket",
"Pengirim meminta pergantian jadwal", "Paket belum ada/belum selesai dikemas", "Pengirim sebagai dropshipper dan menunggu supplier", "Paket pre order","Pengirim merasa tidak menggunakan iDexpress") THEN "Seller"
  WHEN Late_Pickup_Reason IN ("Pengirim tidak ada di lokasi/toko", "Pengirim sedang libur","Pengiriman dibatalkan sebelum di pickup") THEN "Seller"
  WHEN Late_Pickup_Reason IN ("Pengirim akan mengantar paket ke cabang") THEN "Seller"
  WHEN Late_Pickup_Factor = "IDE" THEN "IDX"
  END AS Mapping_Reason_Category_Shopee,

Late_Pickup_Factor,
Late_Pickup_Category,
POD_Time,


FROM check_pickup


