SELECT ww.order_no, ww.waybill_no, 
DATE(ww.shipping_time, 'Asia/Jakarta') Shipping_Time,
    t2.label_bahasa AS Payment_Type,
CASE WHEN t2.label_bahasa IN ('PAD') THEN ww.standard_shipping_fee + ww.handling_fee + ww.cod_amount
     WHEN t2.label_bahasa IN ('Periodic') THEN ww.cod_amount
     ELSE 0 END AS Uang_pada_POD, 
    ww.cod_amount as Waybill_Nominal_COD,
CASE WHEN t1.label_bahasa IN ('Signed') THEN 'Delivered'
    WHEN problem_reason IN ('Kemasan paket rusak') THEN 'Damaged'
    WHEN problem_reason IN ('Kerusakan pada resi / informasi resi tidak jelas') THEN 'Damaged'
    WHEN problem_reason IN ('Paket hilang atau tidak ditemukan') THEN 'Lost'
    WHEN problem_reason IN ('Parcels is lost or cannot be found') THEN 'Lost'
    ELSE t1.label_bahasa END AS Final_Status,
    DATETIME(ww.pod_record_time,'Asia/Jakarta') AS POD_Date,
    DATETIME(ww.return_pod_record_time,'Asia/Jakarta') AS Return_POD_Date,
CASE WHEN t1.label_bahasa IN ('Returning', 'Return Received') THEN t5.return_type
    WHEN t1.label_bahasa NOT IN ('Signed') THEN ps.problem_reason
    ELSE t5.return_type END AS Remarks,
rr.return_pod_photo_url AS Return_POD_Photo,
ma.mitra_by_area AS Delivery_Area,
CASE WHEN ww.pod_branch_name IS NULL THEN ww.delivery_branch_name
WHEN ww.pod_branch_name IS NOT NULL THEN ww.pod_branch_name
END AS POD_Deliv_Branch


-- FROM `datawarehouse_idexp.waybill_waybill` ww
FROM `warehouse_idexp.ide_waybill_waybill` ww
    LEFT JOIN `datawarehouse_idexp.order_order` oo ON oo.waybill_no = ww.waybill_no 
    LEFT JOIN `datawarehouse_idexp.waybill_return_bill` rr ON rr.waybill_no = ww.waybill_no
    LEFT JOIN `datawarehouse_idexp.waybill_problem_piece` ps ON ps.waybill_no = ww.waybill_no
		LEFT JOIN  `datawarehouse_idexp.res_dict_line` t1 ON ww.waybill_status = t1.value AND t1.dict_id = 14
		LEFT JOIN  `datawarehouse_idexp.res_dict_line` t2 ON ww.payment_type  = t2.value AND t2.dict_id = 6
		LEFT JOIN  `grand-sweep-324604.datawarehouse_idexp.return_type` t5 ON rr.return_type_id = t5.id
        LEFT JOIN `datamart_idexp.masterdata_backlog_city_to_ma` ma ON ww.recipient_district_name = ma.destination AND ww.recipient_city_name = ma.destination_city 

WHERE ww.shipping_time BETWEEN '2021-09-30 17:00:00' AND '2022-12-08 16:59:59'

AND --ww.waybill_no IN (
ww.order_no IN (
"SPXID02000393362B",
"SPXID02002044585B"
      )
