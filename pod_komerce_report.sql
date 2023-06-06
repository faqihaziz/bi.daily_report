
WITH POD_Komerce AS (
SELECT 
waybill_no, 
DATE(a.shipping_time, 'Asia/Jakarta')shipping_Date, 
TIME(a.shipping_time, 'Asia/Jakarta')shipping_time, 
pod_branch_name AS POD_Branch, 
DATE(a.pod_scan_time, 'Asia/Jakarta')POD_Date,
TIME(a.pod_scan_time, 'Asia/Jakarta')POD_Time, 
pickup_branch_name AS Origin_Branch, 
DATE(a.shipping_time, 'Asia/Jakarta') as Pickup_Date, 
TIME(a.shipping_time, 'Asia/Jakarta') as Pickup_Time, 
recipient_district_name AS Destination, 
item_name AS Item_Name, 
item_calculated_weight AS Calculated_Weight, 
cod_amount AS COD_Amount, 
insurance_amount AS Insurance_Fee, 
standard_shipping_fee AS Standard_Shipping_Fee, 
receivable_shipping_fee AS Receivable_Shipping_Fee, 
handling_fee AS Handling_Fee, 
other_fee AS Other_Fee, 
total_shipping_fee AS Total_Shipping_Fee, 
vip_customer_name AS VIP_Username, 
sender_name AS Sender, 
sender_cellphone AS Sender_Handphone, 
recipient_name AS Recipient,
recipient_cellphone AS Recipient_Handphone, 
recipient_address AS Recipient_Address, 
d.option_name as Payment_Type, 
et.option_name as Express_Type, 
t1.option_name as POD_Status, 
t9.option_name as Waybill_Source,
sender_province_name AS Origin_Province, 
sender_city_name AS Origin_City, 
recipient_province_name AS Destination_Province, 
recipient_city_name AS Destination_City

from `grand-sweep-324604.datawarehouse_idexp.waybill_waybill` a 

LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.system_option` t1 on a.pod_flag  = t1.option_value and t1.type_option = 'podFlag'
LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.system_option` t9 on a.waybill_source  = t9.option_value and t9.type_option = 'waybillSource'
LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.system_option` d on a.payment_type  = d.option_value and d.type_option = 'paymentType'
left OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.system_option` et on a.express_type  = et.option_value and et.type_option = 'expressType'

--where shipping_time >= '2022-07-24 17:00:00' and shipping_time <= '2022-10-30 16:59:59'
WHERE DATE(shipping_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -65 DAY)) 
AND DATE(pod_record_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -32 DAY)) 
-- and pod_scan_time >= '2022-10-31 17:00:00' and pod_scan_time <= '2022-11-23 16:59:59'

AND t9.option_name In ('Komerce')
AND pod_scan_time IS NOT NULL

QUALIFY ROW_NUMBER() OVER (PARTITION BY waybill_no)=1

)
SELECT
waybill_no,
shipping_Date,
shipping_time,
POD_Branch,
POD_Date,
CONCAT(POD_Date,' ',POD_Time) AS POD_Time,
Origin_Branch,
CONCAT(Pickup_Date,' ',Pickup_Time) AS Pickup_Time,
Destination,
Item_Name,
Calculated_Weight,
COD_Amount,
Insurance_Fee,
Standard_Shipping_Fee,
Receivable_Shipping_Fee,
Handling_Fee,
Other_Fee,
Total_Shipping_Fee,
VIP_Username,
Sender,
Sender_Handphone,
Recipient,
Recipient_Handphone,
Recipient_Address,
Payment_Type,
Express_Type,
POD_Status,
Waybill_Source,
Origin_Province,
Origin_City,
Destination_Province,
Destination_City,

FROM POD_Komerce
ORDER BY POD_Date ASC
