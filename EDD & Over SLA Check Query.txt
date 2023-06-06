-------------QUERY EDD CHECK ----------------
WITH over_sla_check AS (
SELECT CASE WHEN oo.ecommerce_order_no IS NULL THEN ww.ecommerce_order_no ELSE oo.ecommerce_order_no END AS ecommerce_order_no,
 CASE WHEN oo.order_no IS NULL THEN ww.order_no ELSE oo.order_no END AS order_no, 
 CASE WHEN ww.waybill_no IS NULL THEN oo.waybill_no ELSE ww.waybill_no END AS waybill_no, 
IF(ww.delivery_record_time IS NOT NULL,'Yes','No') AS delivery_attempt,
--------------------------------------------------------------
CASE WHEN oo.order_status = '04' THEN 'Cancel Order'
    WHEN t1.option_name IS NULL OR ww.deleted = '1' THEN 'Not Picked Up'
    WHEN t1.option_name IN ('Signed') OR ww.pod_record_time IS NOT NULL THEN 'Delivered'
    WHEN t1.option_name IN ('Return Received') OR ww.return_pod_record_time IS NOT NULL THEN 'Returned'
    WHEN ps.problem_reason LIKE '%bea cukai%' OR ps.problem_reason LIKE '%Rejected by customs%' THEN 'Paket ditolak bea cukai (red line)'
    WHEN ps.problem_reason IN ('Kemasan paket rusak','Paket rusak/pecah', 'Kerusakan pada resi / informasi resi tidak jelas','Damaged parcels','Information on AWB is unclear/damage','Packaging is damage') THEN 'Damaged'
    WHEN ps.problem_reason IN ('Paket hilang atau tidak ditemukan', 'Parcels is lost or cannot be found','Package is lost') then 'Lost'
    
    WHEN ww.waybill_status <> '06' AND (ww.return_flag = '1' OR ww.return_waybill_no IS NOT NULL) AND rr.return_confirm_record_time IS NOT NULL AND rr.return_pod_record_time IS NULL THEN 'Return Process'

    ELSE 'Over SLA' END AS final_status,


CASE WHEN t5.return_type = 'Alamat penerima tidak jelas/tidak dapat ditemukan' THEN 'Alamat penerima tidak dapat ditemukan'
    WHEN t5.return_type = 'Data waybill tidak sesuai dan tidak ada data pengganti' THEN 'Data alamat dan/atau penerima tidak sesuai'
    WHEN t5.return_type = 'Marketplace meminta pengiriman dibatalkan' THEN 'Cancel order oleh E-commerce'
    WHEN t5.return_type = 'Nominal PAD/COD tidak sesuai' THEN 'Nominal COD tidak sesuai'
    WHEN t5.return_type = 'Paket crosslabel/tertukar' THEN 'Paket Tertukar'
    WHEN t5.return_type = 'Paket melebihi ukuran atau berat yang ditentukan' THEN 'Berat timbangan tidak sesuai'
    WHEN t5.return_type = 'Paket melebihi ukuran atau berat yang ditentukan' THEN 'Berat timbangan tidak sesuai'
    WHEN t5.return_type = 'Penerima ingin membuka paket sebelum membayar' THEN 'Penerima menolak menerima paket' --'Penerima menolak pembayaran COD'
    WHEN t5.return_type = "Nominal COD tidak sesuai" THEN 'Penerima menolak menerima paket'
    WHEN t5.return_type = 'Penerima meminta dikirim ke alamat lain' THEN 'Penerima pindah alamat'
    WHEN t5.return_type = 'Penerima meminta reschedule dalam rentang waktu cukup lama' THEN 'Penerima tidak di tempat'
    WHEN t5.return_type = 'Penerima meminta return karena kebutuhannya sudah terpenuhi' THEN 'Penerima meminta paket untuk di return'
    WHEN t5.return_type = 'Penerima meminta return karena pengiriman terlalu lama' THEN 'Penerima meminta paket untuk di return'
    WHEN t5.return_type = 'Penerima meminta return karena sedang tidak di lokasi' THEN 'Penerima tidak di tempat'
    WHEN t5.return_type = 'Penerima meminta return tanpa alasan' THEN 'Penerima meminta paket untuk di return'
    WHEN t5.return_type = 'Penerima menolak membayar PAD' THEN 'Penerima menolak menerima paket'
    WHEN t5.return_type = 'Penerima merasa tidak memesan paket' THEN 'Penerima merasa tidak memesan paket'
    WHEN t5.return_type = 'Penerima Tidak Dapat Dihubungi' THEN 'Penerima tidak dapat dihubungi'
    WHEN t5.return_type = 'Penerima tidak memiliki dana untuk membayar' THEN 'Penerima menolak menerima paket'
    WHEN t5.return_type = 'Pengirim meminta mengembalikan barang' THEN 'Pengirim Meminta Retur'
    WHEN t5.return_type = 'Percobaan pengiriman 3 kali gagal' THEN 'Penerima tidak dapat dihubungi'
    ELSE t5.return_type END AS remarks_return,
ww.return_pod_branch_name,
ww.return_signer,
t3.option_name AS order_status, t1.option_name AS waybill_status, 
DATETIME(ww.shipping_time, 'Asia/Jakarta') AS shipping_time,
DATETIME(ww.update_time, 'Asia/Jakarta') AS update_time,
DATETIME(ww.pod_record_time, 'Asia/Jakarta') AS pod_record_time, 
DATETIME(rr.return_confirm_record_time,'Asia/Jakarta') AS return_confirm_record_time,
DATETIME(ww.return_pod_record_time,'Asia/Jakarta') AS return_pod_record_time,
DATETIME(rr.return_record_time,'Asia/Jakarta') AS return_record_time, t4.option_name AS return_confirm_status, 


DATE(ww.delivery_record_time, 'Asia/Jakarta') Delivery_Date,
CASE WHEN ps.problem_reason NOT IN ('02','00') THEN DATE(ps.operation_time,'Asia/Jakarta') END AS Delivery_Time,
ps.problem_reason AS POS_Reason,
MAX(ps.problem_reason) OVER (PARTITION BY ps.waybill_no ORDER BY ps.operation_time DESC) AS problem_reason, 
MAX(DATETIME(ps.operation_time,'Asia/Jakarta')) OVER (PARTITION BY ps.waybill_no ORDER BY ps.operation_time DESC) AS Latest_POS_time,
st.option_name AS Service_Type,
ww.sender_city_name AS sender_city_name,
    ww.recipient_province_name AS Dest_Province,
    -------------------Yang pake 3PL Papua, Maluku, NTT-------------------
ww.recipient_city_name AS recipient_city_name,
kw1.kanwil_name AS kanwil_area_delivery,


FROM `grand-sweep-324604.datawarehouse_idexp.order_order` oo
    LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_waybill` ww ON oo.waybill_no = ww.waybill_no AND ww.deleted = '0'
    AND DATE(ww.shipping_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -185 DAY))
    LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_return_bill` rr ON ww.waybill_no = rr.waybill_no AND rr.deleted = '0'
    LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.waybill_problem_piece` ps ON ww.waybill_no = ps.waybill_no AND ps.problem_type NOT IN ('02')
    AND DATE(ps.operation_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -185 DAY))
	LEFT OUTER JOIN `datawarehouse_idexp.system_option` t1 ON ww.waybill_status = t1.option_value AND t1.type_option = 'waybillStatus'
    LEFT OUTER JOIN `datawarehouse_idexp.system_option` sr ON oo.order_source = sr.option_value AND sr.type_option = 'orderSource'
	LEFT OUTER JOIN `datawarehouse_idexp.system_option` t3 ON oo.order_status  = t3.option_value AND t3.type_option = 'orderStatus'
	LEFT OUTER JOIN `datawarehouse_idexp.system_option` t4 ON rr.return_confirm_status  = t4.option_value AND t4.type_option = 'returnConfirmStatus'
	LEFT OUTER JOIN `grand-sweep-324604.datawarehouse_idexp.return_type` t5 ON rr.return_type_id = t5.id AND t5.deleted=0
    left join `grand-sweep-324604.datawarehouse_idexp.system_option` st on oo.service_type  = st.option_value and st.type_option = 'serviceType'
    LEFT OUTER JOIN `datamart_idexp.mapping_kanwil_area` kw1 ON ww.recipient_province_name = kw1.province_name

    WHERE DATE(oo.input_time,'Asia/Jakarta') >= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -195 DAY))
    

AND oo.waybill_no IN (

"IDS901069632935",
"IDS902248635153",
"IDS900610860453",
"IDS900834132458",
"IDS900788691104",
"IDS903798615009",
"IDS901808723878",
"IDS903378703018",
"IDS903294875441",
"IDS901165346431",
"IDS903298828276",
"IDS901344356249",
"IDS902102980754",
"IDS903719651140",
"IDS902240897889",
"IDS902888269072",
"IDS900513452078",
"IDS902467868292",
"IDS901074696263",
"IDI903950001621",
"IDS900854780154",
"IDS903362028136"

)

ORDER BY rr.return_record_time DESC, ps.operation_time DESC, rr.return_confirm_record_time DESC, ww.input_time DESC, ww.update_time DESC
),


remove_duplikat AS (SELECT 
ecommerce_order_no,
order_no,
waybill_no,
delivery_attempt,
final_status,
remarks_return,
return_pod_branch_name,
return_signer,
order_status,
waybill_status,
shipping_time,
update_time,
pod_record_time,
return_pod_record_time,
return_record_time,
return_confirm_status,
return_confirm_record_time,
Latest_POS_time,
sender_city_name,
Dest_Province,
recipient_city_name,
kanwil_area_delivery,

CASE 
    WHEN problem_reason IN ('Paket dikirim via ekspedisi lain','Pengirim mengantarkan paket ke Drop Point','Pengirim tidak di tempat','Paket sedang disiapkan','Pengirim akan mengantar paket ke cabang','Pengirim tidak ada di lokasi/toko','Alamat pengirim kurang jelas','Pengirim sedang mempersiapkan paket','Pengirim meminta pergantian jadwal','Paket belum ada/belum selesai dikemas','Pengirim tidak dapat dihubungi','Pengirim merasa tidak menggunakan iDexpress','Pengirim sedang libur','Pengirim sebagai dropshipper dan menunggu supplier','Paket pre order') THEN "0"

    WHEN problem_reason = 'Paket salah dalam proses penyortiran' THEN 'Paket salah sortir/ salah rute'
    WHEN problem_reason = 'Paket akan dikembalikan ke cabang asal' THEN 'Paket salah sortir/ salah rute'
    WHEN problem_reason = 'Data alamat tidak sesuai dengan kode sortir' THEN 'Alamat tidak lengkap'
    WHEN problem_reason = 'Reschedule pengiriman dengan penerima' THEN 'Penerima menjadwalkan ulang waktu pengiriman'
    WHEN problem_reason = 'Pelanggan ingin dikirim ke alamat berbeda' THEN 'Penerima menjadwalkan ulang waktu pengiriman'
    WHEN problem_reason = 'Cuaca buruk / bencana alam' THEN 'Cuaca buruk / Hujan'
    WHEN problem_reason = 'Pelanggan membatalkan pengiriman' THEN 'Pengirim membatalkan pengiriman'
    WHEN problem_reason = 'Pelanggan tidak di lokasi' THEN 'Penerima tidak di tempat'
    WHEN problem_reason = 'Pelanggan libur akhir pekan/libur panjang' THEN 'Penerima tidak di tempat'
    WHEN problem_reason = 'Pelanggan berinisiatif mengambil paket di cabang' THEN 'Penerima ingin mengambil paket di cabang'
    WHEN problem_reason = 'Alamat pelanggan salah/sudah pindah alamat' THEN 'Penerima pindah alamat'
    WHEN problem_reason = 'Nomor telepon yang tertera tidak dapat dihubungi atau alamat tidak jelas' THEN 'Nomor telepon tidak dapat dihubungi'
    WHEN problem_reason = 'Nomor telepon yang tertera tidak dapat dihubungi' THEN 'Nomor telepon tidak dapat dihubungi'
    WHEN problem_reason = 'Sudah melewati jam operasional Drop Point' THEN 'Melewati jam operasional cabang'
    WHEN problem_reason = 'Telepon bermasalah, tidak dapat dihubungi' THEN 'Nomor telepon tidak dapat dihubungi'
    ELSE problem_reason
    END AS latest_problem_reason,
Service_Type,
CASE WHEN final_status = 'Over SLA' THEN 'Paket Jalan' ELSE final_status END AS EDD_status,



FROM over_sla_check

QUALIFY ROW_NUMBER() OVER (PARTITION BY waybill_no ORDER BY update_time DESC)=1),

OverSLA AS (
SELECT 
rd.ecommerce_order_no,
rd.order_no,
rd.waybill_no,
rd.delivery_attempt,
CASE WHEN cl.waybill_no IS NOT NULL THEN "EDD Claimed"
ELSE rd.final_status END AS final_status,
rd.remarks_return,
rd.return_pod_branch_name,
rd.return_signer,
rd.order_status,
rd.waybill_status,
rd.shipping_time,
rd.update_time,
rd.pod_record_time,
rd.return_pod_record_time,
rd.return_record_time,
rd.return_confirm_status,
rd.return_confirm_record_time,
------------------------------------------------------------------------
rd.Latest_POS_time,
rd.latest_problem_reason,
rd.Service_Type,
CASE WHEN cl.waybill_no IS NOT NULL THEN "EDD Claimed"
ELSE rd.EDD_status END AS EDD_status,
rd.sender_city_name,
rd.Dest_Province,
rd.recipient_city_name,
rd.kanwil_area_delivery,
cast(t6.sla as INTEGER) AS SLA_Shopee,
DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)) day)) AS Due_Date_Delivery,

    CASE WHEN rd.shipping_time IS NULL THEN NULL   
    WHEN rd.shipping_time IS NOT NULL AND cast(t6.sla as INTEGER) IS NULL THEN "No SLA (OoC)"

--------------EDD +0hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time = DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)) day) THEN "EDD +0 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time = DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)) day) THEN "EDD +0 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') = DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)) day)) THEN "EDD +0 Hari"

--------------EDD +1hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+2) day) THEN "EDD +1 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+2) day) THEN "EDD +1 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+2) day)) THEN "EDD +1 Hari"

--------------EDD +2hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+3) day) THEN "EDD +2 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+3) day) THEN "EDD +2 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+3) day)) THEN "EDD +2 Hari"

--------------EDD +3hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+4) day) THEN "EDD +3 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+4) day) THEN "EDD +3 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+4) day)) THEN "EDD +3 Hari"

--------------EDD +4hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND DATE(rd.pod_record_time) < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+5) day) THEN "EDD +4 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+5) day) THEN "EDD +4 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+5) day)) THEN "EDD +4 Hari"

--------------EDD +5hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+5) day) THEN "EDD +5 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+6) day) THEN "EDD +5 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+6) day)) THEN "EDD +5 Hari"

--------------EDD +6hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+7) day) THEN "EDD +6 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+7) day) THEN "EDD +6 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+7) day)) THEN "EDD +6 Hari"

--------------EDD +7hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+8) day) THEN "EDD +7 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+8) day) THEN "EDD +7 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+8) day)) THEN "EDD +7 Hari"

--------------EDD +8hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+9) day) THEN "EDD +8 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+9) day) THEN "EDD +8 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+9) day)) THEN "EDD +8 Hari"

--------------EDD +9hari------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day) THEN "EDD +9 Hari"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time < DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day) THEN "EDD +9 Hari"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') < DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day)) THEN "EDD +9 Hari"

--------------EDD +10hari >------------------
---------------pod/not------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time >= DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day) THEN "EDD +10 Hari >"
    -----------return--------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time >= DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day) THEN "EDD +10 Hari >"
    ------------------not pod and not return----------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') >= DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)+10) day)) THEN "EDD +10 Hari >"
    END AS EDD_Category,

CASE WHEN rd.shipping_time IS NULL THEN NULL   
    WHEN rd.shipping_time IS NOT NULL AND cast(t6.sla as INTEGER) IS NULL THEN "No SLA (OoC)"
---------------pod/not--------------------------
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time <= DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day) THEN "< 3x SLA"
    WHEN rd.pod_record_time IS NOT NULL AND rd.pod_record_time > DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day) THEN "> 3x SLA"
------------------return-------------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time <= DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day) THEN "< 3x SLA"
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NOT NULL AND rd.return_record_time > DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day) THEN "> 3x SLA"
-----------------not pod and not return-------------------------
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') <= DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day)) THEN "< 3x SLA"
    WHEN rd.pod_record_time IS NULL AND rd.return_confirm_record_time IS NULL AND CURRENT_DATE('Asia/Jakarta') > DATE(DATE_ADD(rd.shipping_time, INTERVAL (cast(t6.sla as INTEGER)*3) day)) THEN "> 3x SLA"
    END AS SLA_Status_3x,

    rd.EDD_status AS EDD_status_asli,


FROM remove_duplikat rd
LEFT OUTER JOIN `datamart_idexp.masterdata_sla_shopee` t6 ON rd.recipient_city_name = t6.destination_city and rd.sender_city_name = t6.origin_city
LEFT OUTER JOIN `datamart_idexp.masterdata_waybill_claim_edd_shopee` cl ON rd.waybill_no = cl.waybill_no

QUALIFY ROW_NUMBER() OVER (PARTITION BY waybill_no ORDER BY update_time DESC)=1
)

SELECT 
ecommerce_order_no,
order_no,
waybill_no,
delivery_attempt,
final_status,
remarks_return,
return_pod_branch_name,
return_signer,
order_status,
waybill_status,
shipping_time,
update_time,
return_pod_record_time,
return_record_time,
return_confirm_status,
return_confirm_record_time,
Latest_POS_time,
latest_problem_reason,
Service_Type,
pod_record_time,
SLA_Shopee,
Due_Date_Delivery,
EDD_status, 
CASE 
    WHEN waybill_no =	"IDS902935228837"	THEN "Diganti menjadi AWB IDD903842208558"
    WHEN waybill_no =	"IDS902816564984"	THEN "Diganti menjadi AWB IDD903530511073"
    WHEN waybill_no =	"IDS901833783163"	THEN "Diganti menjadi AWB IDD901590699802"
    WHEN waybill_no =	"IDS900575303535"	THEN "Diganti menjadi AWB IDD900449352429"
    WHEN waybill_no =	"IDS900207032140"	THEN "Diganti menjadi AWB IDD904081277323"
    WHEN waybill_no =	"IDS901775104453"	THEN "Diganti menjadi AWB IDD903202309918"
    WHEN waybill_no =	"IDS902399412520"	THEN "Diganti menjadi AWB IDD901271636810"
END AS Additional_Info,
EDD_Category,
SLA_Status_3x,
Dest_Province,
EDD_status_asli,
date_diff(current_date('Asia/Jakarta'), DATE(Due_Date_Delivery), DAY) AS aging_from_SLA,
kanwil_area_delivery,

FROM OverSLA

