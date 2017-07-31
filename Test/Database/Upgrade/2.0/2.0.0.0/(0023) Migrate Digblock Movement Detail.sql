-- migrate digblock movement detail into new DPT schema
-- (ensures movements tab in digblock tab is not empty)

insert into ParcelGrade (Parcel_GRade_Id, Grade_Id, Grade_Value)
select dpt.data_process_transaction_id, dptg.grade_id, dptg.grade_value
from dataprocesstransaction dpt
inner join dataprocesstransactionGrade dptg
	on dpt.data_process_transaction_id = dptg.data_process_transaction_id
where dpt.original_source_digblock_id is not null

set identity_insert dataprocesstransactionparcel on
		
insert into dataprocesstransactionparcel (data_process_transaction_parcel_id, data_process_transaction_id, parcel_grade_id, source_digblock_id, tonnes)
select data_process_transaction_id, data_process_transaction_id, data_process_transaction_id, original_source_digblock_id, tonnes
from dataprocesstransaction dpt

set identity_insert dataprocesstransactionparcel off