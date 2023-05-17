  SELECT 
       oo.waybill_no,
       oo.total_shipping_fee as freight,
       ww.total_shipping_fee as ASF,
       oo.item_calculated_weight as order_calculated_weight, 
       ww.item_calculated_weight as waybill_actual_weight_ww,

       ww.standard_shipping_fee as waybill_std_ship_fee,

       ww.other_fee as waybill_biaya_lainnya,
       ww.insurance_amount as waybill_insurance_fee,
       oo.handling_fee as order_handling_fee,
       ww.handling_fee as waybill_handling_fee,

       oo.sender_province_name as order_origin_province,
       oo.sender_city_name as order_origin_city,
       oo.sender_district_name as order_origin_district,
       ww.sender_province_name as waybill_origin_province,
       ww.sender_city_name as waybill_origin_city, 
       ww.sender_district_name as waybill_origin_district,

       oo.recipient_province_name as order_destination_province,
       oo.recipient_city_name as order_destination_city, 
       oo.recipient_district_name as order_destination_district,     
       ww.recipient_province_name as waybill_destination_province,
       ww.recipient_city_name as waybill_destination_city,
       ww.recipient_district_name as waybill_destination_district,

CASE 
      WHEN oo.sender_city_name = ww.sender_city_name AND oo.recipient_city_name = ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) = CAST(ww.item_actual_weight AS NUMERIC) THEN "No Issue"
      WHEN CAST(oo.item_calculated_weight AS NUMERIC) <> CAST(ww.item_actual_weight AS NUMERIC) THEN "Change of Weight"
      WHEN oo.sender_city_name <> ww.sender_city_name AND oo.recipient_city_name = ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) = CAST(ww.item_actual_weight AS NUMERIC) THEN "Different Origin City"
      WHEN oo.sender_city_name <> ww.sender_city_name AND oo.recipient_city_name = ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) <> CAST(ww.item_actual_weight AS NUMERIC) THEN "Different Origin City & Change of Weight"
      WHEN oo.sender_city_name = ww.sender_city_name AND oo.recipient_city_name <> ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) = CAST(ww.item_actual_weight AS NUMERIC) THEN "Change of Destination Area"
      WHEN oo.sender_city_name = ww.sender_city_name AND oo.recipient_city_name <> ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) <> CAST(ww.item_actual_weight AS NUMERIC) THEN "Change of Weight & Change of Destination Area"
      WHEN oo.sender_city_name <> ww.sender_city_name AND oo.recipient_city_name <> ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) = CAST(ww.item_actual_weight AS NUMERIC) THEN "Different Origin City & Change of Destination Area"
      WHEN oo.sender_city_name <> ww.sender_city_name AND oo.recipient_city_name <> ww.recipient_city_name AND CAST(oo.item_calculated_weight AS NUMERIC) <> CAST(ww.item_actual_weight AS NUMERIC) THEN "Change of Weight, Different Origin City & Change of Destination Area"     
      WHEN oo.order_status = '04' THEN 'Cancel Order'
    WHEN t1.option_name IS NULL OR ww.deleted = '1' THEN 'Not Picked Up'
      END AS ASF_Status,

       st.option_name AS Service_Type  


from `datawarehouse_idexp.order_order` oo
 LEFT OUTER JOIN `datawarehouse_idexp.waybill_waybill` ww on oo.waybill_no = ww.waybill_no and ww.deleted = '0'
 AND DATE(ww.shipping_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -95 DAY))
-- LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.res_dict_line` t1 on oo.order_status = t1.value and t1.dict_id = 13 and t1.deleted = '0'
LEFT OUTER JOIN `datawarehouse_idexp.system_option` t1 ON ww.waybill_status = t1.option_value AND t1.type_option = 'waybillStatus'
LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.system_option` st on oo.service_type  = st.option_value and st.type_option = 'serviceType'

WHERE DATE(oo.input_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -95 DAY))
