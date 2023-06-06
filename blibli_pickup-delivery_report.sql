WITH blibli_report AS (

SELECT 
oo.waybill_no AS Waybill_No,
oe.email_date AS Email_Date, 
oo.order_no AS Order_No,
oo.sender_name AS Sender,
oo.sender_cellphone AS Sender_Phone,
oo.sender_province_name AS Origin_Province,
oo.sender_city_name AS Origin_City,
oo.sender_district_name AS Origin_District,

CASE WHEN oo.pickup_branch_name IS NOT NULL THEN mb.mitra_by_area
WHEN oo.pickup_branch_name IS NULL THEN ma.mitra_by_area 
END AS Pickup_Area,

oo.sender_address AS Sender_Address,
oo.scheduling_target_branch_name AS Scheduled_Branch,
DATETIME(oo.scheduling_time, 'Asia/Jakarta')Time_Scheduled_to_Branch,

   CASE 
     WHEN DATETIME(oo.create_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "OnTime Schedule"
     WHEN DATETIME(oo.create_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') >= DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "Late Schedule"
     WHEN DATETIME(oo.create_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL THEN "Late Schedule"
     WHEN DATETIME(oo.create_time, 'Asia/Jakarta') < DATETIME(oo.end_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Yet"
     END AS Scheduling_To_Branch_Status,

oo.pickup_branch_name AS Pickup_PDB,
oo.create_time AS Order_Time_A,
oo.pickup_time AS Pickup_Time_A,
DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta')Scheduling_Courier_Time,

CASE 
   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name <> oo.pickup_branch_name THEN "Ontime Schedule to Courier"
   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') >= DATETIME(oo.start_pickup_time, 'Asia/Jakarta') THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') <= DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name = oo.pickup_branch_name AND DATETIME(oo.scheduling_time, 'Asia/Jakarta') < DATETIME(oo.start_pickup_time, 'Asia/Jakarta') AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') > DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND oo.scheduling_target_branch_name IS NULL THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') <= DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Ontime Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') > DATE_SUB(DATETIME(oo.end_pickup_time, 'Asia/Jakarta'), INTERVAL 1 HOUR) THEN "Late Schedule to Courier"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND scheduling_target_branch_name IS NOT NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Yet"

   WHEN DATETIME(oo.pickup_time, 'Asia/Jakarta') IS NULL AND scheduling_target_branch_name IS NULL AND DATETIME(oo.scheduling_courier_time, 'Asia/Jakarta') IS NULL THEN "Not Schedule Branch Yet"
  END AS Scheduling_to_Courier_Status,

DATETIME(oo.pickup_time, 'Asia/Jakarta')Pickup_Time,
DATETIME(oo.create_time, 'Asia/Jakarta')Order_Time,
DATETIME(oo.input_time, 'Asia/Jakarta')Input_Time,
DATETIME(oo.start_pickup_time, 'Asia/Jakarta') Pickup_Start_Time,
DATETIME(oo.end_pickup_time, 'Asia/Jakarta') Pickup_End_Time,
sr.option_name as Order_Source,

CASE 
    WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(oo.pickup_time, 'Asia/Jakarta') <= oe.email_date THEN "On Time"
    WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND t3.option_name IN ('Cancel Order') THEN "Cancel Order"
    WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL AND DATE(oo.pickup_time, 'Asia/Jakarta') > oe.email_date THEN "Late"
    WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND CURRENT_DATE('Asia/Jakarta') > oe.email_date THEN "Late"
    WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NULL AND CURRENT_DATE('Asia/Jakarta') = oe.email_date THEN "Not Picked Up"
    END AS Pickup_Perform,

DATE_DIFF(DATE(oo.pickup_time, 'Asia/Jakarta'), oe.email_date, Day) AS Pickup_Duration_Day,

oo.recipient_name AS Buyer_Name,
oo.recipient_cellphone AS Buyer_Phone,
oo.recipient_address AS Buyer_Address,
oo.recipient_province_name AS Destination_Province,
oo.recipient_city_name AS Destination_City,
oo.item_calculated_weight AS Calculated_Weight,
st.option_name AS Service_Type,

CASE WHEN DATE(oo.pickup_time, 'Asia/Jakarta') IS NOT NULL THEN "Picked Up"
ELSE t3.option_name END AS Order_Status,
DATETIME(oo.pickup_failure_time, 'Asia/Jakarta') First_Attempt_Pickup_Failure,
t0.label_english as Pickup_Failure_Flag, 
CASE 
WHEN oe.waybill_no IN ("IDB007494989192") THEN "Late generated, system error"
ELSE t4.register_reason_bahasa END AS Pickup_Failure_Reason,

t5.label_english as Pickup_Status,
DATETIME(ww.shipping_time, 'Asia/Jakarta')Shipping_Time,
DATETIME(ww.pod_scan_time, 'Asia/Jakarta')POD_Time,
ww.signer AS POD_Signer,
t10.label_bahasa as Relation,
datetime(rr.return_confirm_record_time,'Asia/Jakarta') as Return_Start_Time,
datetime(rr.return_pod_scan_time,'Asia/Jakarta') as Return_POD_Time,
t11.option_name AS Waybill_Status


FROM `datawarehouse_idexp.order_order` oo
LEFT JOIN `datamart_idexp.masterdata_blibli_orderemail` oe ON oo.waybill_no = oe.waybill_no 
-- FROM `datamart_idexp.masterdata_blibli_orderemail` oe
-- FROM `grand-sweep-324604.datawarehouse_idexp.order_order` oo 
-- LEFT JOIN `grand-sweep-324604.datawarehouse_idexp.order_order` oo ON oe.waybill_no = oo.waybill_no AND oo.deleted = '0'
LEFT JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_waybill` ww ON oo.waybill_no = ww.waybill_no AND ww.deleted = '0'
LEFT JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_return_bill` rr ON ww.waybill_no = rr.waybill_no AND rr.deleted = '0'
left join `datawarehouse_idexp.res_dict_line` t10 on ww.relationship_type  = t10.value and t10.dict_id = 5
left join `grand-sweep-324604.datawarehouse_idexp.system_option` t3 on oo.order_status  = t3.option_value and t3.type_option = 'orderStatus'
left join `grand-sweep-324604.datawarehouse_idexp.res_dict_line` t8 on oo.pod_status  = t8.value and t8.dict_id = 104 AND t8.deleted = '0'
left join `grand-sweep-324604.datawarehouse_idexp.res_dict_line` t5 on oo.pickup_flag  = t5.value and t5.dict_id = 38 AND t5.deleted = '0'
left join `grand-sweep-324604.datawarehouse_idexp.system_option` sr on oo.order_source  = sr.option_value and sr.type_option = 'orderSource'
LEFT join `grand-sweep-324604.datawarehouse_idexp.res_dict_line` t0 on oo.pickup_failure_flag = t0.value and t0.dict_id = 73 AND t0.deleted = '0'
LEFT join `grand-sweep-324604.datawarehouse_idexp.res_problem_package` t4 on oo.pickup_failure_problem_code = t4.code
LEFT JOIN `datamart_idexp.mapping_mitra_by_branch` mb ON oo.pickup_branch_name = mb.branch_name
LEFT JOIN `datamart_idexp.masterdata_backlog_city_to_ma` ma ON oo.sender_district_name = ma.destination AND oo.sender_city_name = ma.destination_city
left join `grand-sweep-324604.datawarehouse_idexp.system_option` st on oo.service_type  = st.option_value and st.type_option = 'serviceType'
LEFT OUTER JOIN `datawarehouse_idexp.system_option` t11 ON ww.waybill_status = t11.option_value AND t11.type_option = 'waybillStatus'

WHERE DATE(oo.input_time, 'Asia/Jakarta') BETWEEN '2023-01-01' AND '2023-03-26'
-- WHERE oo.input_time >= '2022-10-31 17:00:00' and oo.input_time <= '2023-02-12 16:59:59'
--AND ww.pod_scan_time >= '2022-07-31 17:00:00' and ww.pod_scan_time <= '2022-09-13 16:59:59'


AND sr.option_name IN ('Blibli','Blibli API')
-- and oe.waybill_no in ('IDB003532256514')


QUALIFY ROW_NUMBER() OVER (PARTITION BY oo.waybill_no ORDER BY ww.update_time DESC)=1

),
blibli_pickup AS (
    SELECT 
Waybill_No,
Email_Date,
Order_No,
Sender,
Sender_Phone,
Origin_Province,
Origin_City,
Origin_District,
Pickup_Area,
Sender_Address,
Scheduled_Branch,
Time_Scheduled_to_Branch,
Scheduling_To_Branch_Status,
Pickup_PDB,
Order_Time_A,
Pickup_Time_A,
Scheduling_Courier_Time,
Scheduling_to_Courier_Status,
Pickup_Time,
Order_Time,
Input_Time,
Pickup_Start_Time,
Pickup_End_Time,
Order_Source,
Buyer_Name,
Buyer_Phone,
Buyer_Address,
Destination_Province,
Destination_City,
Calculated_Weight,
Order_Status,
Pickup_Perform,
Pickup_Duration_Day,

CASE 
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Cuaca buruk / bencana alam') 	THEN 'External' 
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Paket akan diproses dengan nomor resi yang baru','Di luar cakupan area cabang, akan dijadwalkan ke cabang lain','Melewati jam operasional cabang','Late Schedule to Branch','Late Schedule to Courier','Kurir tidak available',"Late generated, system error", "Dalam Penjadwalan Kurir") THEN 'IDE'
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Pengiriman akan menggunakan ekspedisi lain','Pengiriman dibatalkan','Pengirim akan mengantar paket ke cabang','Pengirim tidak ada di lokasi/toko','Alamat pengirim kurang jelas','Pengirim sedang mempersiapkan paket','Pengirim meminta pergantian jadwal','Paket belum ada/belum selesai dikemas','Pengirim tidak dapat dihubungi','Pengirim merasa tidak menggunakan iDexpress','Pengirim sedang libur','Pengirim sebagai dropshipper dan menunggu supplier','Paket pre order', "Berat paket tidak sesuai") THEN 'Pengirim'
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IS NULL THEN 'IDE'
END AS Late_Factor,

CASE
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Cuaca buruk / bencana alam') 	THEN 'Uncontrollable'
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Paket akan diproses dengan nomor resi yang baru','Di luar cakupan area cabang, akan dijadwalkan ke cabang lain','Melewati jam operasional cabang','Late Schedule to Branch','Late Schedule to Courier','Kurir tidak available',"Late generated, system error", "Dalam Penjadwalan Kurir") THEN 'Controllable'
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IN ('Pengiriman akan menggunakan ekspedisi lain','Pengiriman dibatalkan','Pengirim akan mengantar paket ke cabang','Pengirim tidak ada di lokasi/toko','Alamat pengirim kurang jelas','Pengirim sedang mempersiapkan paket','Pengirim meminta pergantian jadwal','Paket belum ada/belum selesai dikemas','Pengirim tidak dapat dihubungi','Pengirim merasa tidak menggunakan iDexpress','Pengirim sedang libur','Pengirim sebagai dropshipper dan menunggu supplier','Paket pre order', "Berat paket tidak sesuai") THEN 'Uncontrollable'
WHEN Pickup_Perform = 'Late' AND Pickup_Failure_Reason IS NULL THEN 'Controllable'
END AS Late_Category,

CASE 
     WHEN Pickup_Time IS NULL AND Pickup_Failure_Reason IS NOT NULL THEN Pickup_Failure_Reason
     WHEN Pickup_Perform IN ('On Time') AND Pickup_Failure_Reason IS NULL THEN NULL
     WHEN Pickup_Perform IN ('On Time') AND Pickup_Failure_Reason IS NOT NULL THEN Pickup_Failure_Reason
     --WHEN Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NULL THEN "Dalam Penjadwalan Kurir"
     WHEN Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "Late Schedule" AND Scheduling_to_Courier_Status = "Ontime Schedule to Courier" THEN "Late Schedule to Branch"
     WHEN Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "OnTime Schedule" AND Scheduling_to_Courier_Status = "Late Schedule to Courier" THEN "Late Schedule to Courier"
     WHEN Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NOT NULL THEN Pickup_Failure_Reason
     WHEN Pickup_Perform IN ('Cancel Order') AND Pickup_Failure_Reason IS NULL THEN "Cancel Order"
     WHEN Pickup_Perform IN ('Cancel Order') AND Pickup_Failure_Reason IS NOT NULL THEN Pickup_Failure_Reason
     WHEN Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "Late Schedule" AND Scheduling_to_Courier_Status = "Late Schedule to Courier" THEN "Late Schedule to Branch"
     WHEN Pickup_Time IS NULL AND Pickup_Perform IN ('Late') AND Pickup_Failure_Reason IS NULL AND Scheduling_To_Branch_Status = "OnTime Schedule" AND Scheduling_to_Courier_Status = "Ontime Schedule to Courier" THEN "Dalam Penjadwalan Kurir"
     WHEN Waybill_No IN ("IDB002697847154", "IDB009626478465", "IDB004981251173", "IDB002130955241", "IDB000654977040") THEN "Misskom tim WH dengan kurir, barang belum siap saat kurir datang"
     WHEN Waybill_No IN ("IDB007494989192") THEN "Late generated, system error"
     END AS Late_Pickup_Reason,
Shipping_Time,
POD_Time,
POD_Signer,
Relation,
Return_Start_Time,
Return_POD_Time,
Pickup_Failure_Flag,
First_Attempt_Pickup_Failure,
Pickup_Failure_Reason,
Pickup_Status

FROM blibli_report)



SELECT * FROM blibli_pickup


