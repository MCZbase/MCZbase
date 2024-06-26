<cfinclude template="/includes/_header.cfm">
<!---
create table cf_temp_data_loan_item (
 KEY                                                            NUMBER,
 INSTITUTION_ACRONYM                                            VARCHAR2(5),
COLLECTION_CDE                                                 VARCHAR2(4),
 OTHER_ID_TYPE                                                  VARCHAR2(30),
 OTHER_ID_NUMBER                                                VARCHAR2(30),
 LOAN_number                                                           VARCHAR2(30),
collection_object_id number,
transaction_id number,
ITEM_DESCRIPTION VARCHAR2(60),
status varchar2(255)
);


create or replace public synonym cf_temp_data_loan_item for cf_temp_data_loan_item;
grant all on cf_temp_data_loan_item to manage_transactions;

 CREATE OR REPLACE TRIGGER cf_temp_data_loan_item_key                                         
 before insert  ON cf_temp_data_loan_item  
 for each row 
    begin     
    	if :NEW.key is null then                                                                                      
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;                                
    end;                                                                                            
/
sho err
--->
<cfset title="Load Cataloged Item Loans">


<script type='text/javascript' src='/includes/loadLoanPart.js'></script>


		
<cfif action is "nothing">
    <div style="width:56em;margin: 0 auto; padding: 1em 0 3em 0;">
<cfoutput>
    <h3 class="wikilink">Bulkload Data Loans</h3>
	The following must all be true to use this form:
	<ul class="geol_hier">
		<li>
			Encumbrances have been checked
		</li>
		<li>A loan of loan type 'data' has been created in Arctos.</li>
		<li>Loan Item reconciled person is you (<i>#session.username#</i>)</li>
		<li>Loan Item reconciled date is today (#dateformat(now(),"yyyy-mm-dd")#)</li>
	</ul>
    <p>Upload a file comma-delimited text file (CSV) in the following format. (You may copy the template below and save as .CSV)  Include column headers. </p>
    
            <p style="margin: 1em 0;"><span class="likeLink" onclick="document.getElementById('template').style.display='block';">view template</span></p>
	<div id="template" style="display:none; margin: 1em 0;">
		<label for="t">Copy the following code and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,LOAN_NUMBER</textarea>
	</div>
    
<ul class="geol_hier">
	<li style="color:red;">Institution_Acronym (required)</li>
	<li style="color: red;">Collection_Cde (required)</li>
	<li style="color:red;">Other_Id_Type (required. "catalog number" is acceptable)</li>
	<li style="color: red;">Other_Id_Number (required; display value)</li>
	<li style="color:red;">Loan_Number (required)</li>
</ul>
</cfoutput>

<p>
<div id="template">
		<textarea rows="2" cols="80" style="display: none;" id="t">INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,LOAN_NUMBER</textarea>
	</div> 

<cfform name="catnum" method="post" enctype="multipart/form-data">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			  <input type="submit" value="Upload this file" #saveClr#>
		</cfform>
    </div>
</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "getFile">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		delete from cf_temp_data_loan_item
	</cfquery>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />	
	<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				<cfset thisBit=arrResult[o][i]>
				<cfif #o# is 1>
					<cfset colNames="#colNames#,#thisBit#">
				<cfelse>
					<cfset colVals="#colVals#,'#trim(thisBit)#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames=replace(colNames,",","","first")>
		</cfif>	
		<cfif len(#colVals#) gt 1>
			<cfset colVals=replace(colVals,",","","first")>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into cf_temp_data_loan_item (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
	<cfquery name="gotit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_temp_data_loan_item
	</cfquery>
	<cfdump var="#gotit#">
	If the above table is accurate, <a href="DataLoanBulkload.cfm?action=verify">click here to proceed</a>.
</cfif>
<!------------------------------------------------------->
<cfif action is "verify">
<cfoutput>
<cftransaction>
	<cfquery name="loanID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		update 
			cf_temp_data_loan_item 
		set 
			(transaction_id) 
		= (select
				loan.transaction_id 
			from 
				trans,loan,collection
			where 
				trans.transaction_id = loan.transaction_id and
				loan.loan_type='data' and
				trans.collection_id = collection.collection_id and
				collection.institution_acronym=cf_temp_data_loan_item.institution_acronym and
				collection.collection_cde=cf_temp_data_loan_item.collection_cde and
				loan.loan_number = cf_temp_data_loan_item.loan_number
			)
	</cfquery>
	<cfquery name="missedMe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		update cf_temp_data_loan_item set status = 'loan not found' where
		transaction_id is null
	</cfquery>
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_temp_data_loan_item where status is null
	</cfquery>  
		<cfloop query="data">
			<cfif other_id_type is "catalog number">
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select 
						cataloged_item.collection_object_id 
					from
						cataloged_item,
						collection
					where
						cataloged_item.collection_id = collection.collection_id and
						collection.institution_acronym = '#institution_acronym#' and
						collection.collection_cde = '#collection_cde#' and
						cat_num = '#other_id_number#'
				</cfquery>
			<cfelse>
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select 
						cataloged_item.collection_object_id 
					from
						cataloged_item,
						collection,
						coll_obj_other_id_num
					where
						cataloged_item.collection_id = collection.collection_id and
						cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id and
						collection.institution_acronym = '#institution_acronym#' and
						collection.collection_cde = '#collection_cde#' and
						display_value = '#other_id_number#' and
						other_id_type = '#other_id_type#'
				</cfquery>
			</cfif>
			<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
				collObj.recordcount is 1....
				<cfquery name="YayCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_data_loan_item
					set
						status='spiffy',
						collection_object_id = #collObj.collection_object_id#
					where
						key=#key#
				</cfquery>
				<cfquery name="defDescr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update 
						cf_temp_data_loan_item 
						set (ITEM_DESCRIPTION)
						= (
							select collection.collection || ' ' || cat_num || ' cataloged item'
							from
							cataloged_item,
							collection
						where
							cataloged_item.collection_id = collection.collection_id and
							cataloged_item.collection_object_id=#collObj.collection_object_id#
					)
					where ITEM_DESCRIPTION is null and key=#key#
				</cfquery>
			<cfelse>
				no CI
				<cfquery name="BooCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_data_loan_item
					set
						status='no item'
					where
						key=#key#
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
	<cfquery name="done" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_temp_data_loan_item
	</cfquery> 
	<cfdump var=#done#>
	<cfquery name="bads" dbtype="query">
		select count(*) c from done where status != 'spiffy'
	</cfquery>
	---------#bads.c#-------------
	<cfif bads.c is 0 or bads.c is ''>
		If everything in the table above looks OK, <a href="DataLoanBulkload.cfm?action=loadData">click here to finalize loading</a>.
	<cfelse>
		Something isn't happy. Check the status column in the above table, fix your data, and try again.
	</cfif>
	
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "loadData">
<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from cf_temp_data_loan_item
	</cfquery>
	<cftransaction>
		<cfloop query="getTempData">
			<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO loan_item (
					transaction_id,
					collection_object_id,
					RECONCILED_BY_PERSON_ID,
					reconciled_date,
					item_descr
					)
				VALUES (
					 #transaction_id#,
					  #collection_object_id#,
					  #session.myAgentId#,
					  sysdate,
					  '#ITEM_DESCRIPTION#'
					)
			</cfquery>
		</cfloop>
	</cftransaction>
	Spiffy, all done.
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
