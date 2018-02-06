<cfset jquery11=true>
<cfinclude template = "/includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<cfset BORROWNUMBERPATTERN = '^B[12][0-9]{3}-[0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
<style>
.form-style-2{
    width: 50%;
    padding: 20px 12px 10px 20px;
    font: 15px Arial, Helvetica, sans-serif;
        float:left;
            margin: 10px 160px 30px 0px;
}
.form-style-2-heading{
    font-weight: bold;
    font-style: italic;
    border-bottom: 2px solid #ddd;
    margin-bottom: 20px;
    font-size: 16px;
    padding-bottom: 3px;
}
.form-style-2 label{
    display: block;
    margin: 0px 0px 15px 0px;
}
.form-style-2 label > span{
    width: 150px;
    font-weight: bold;
    float: left;
    padding-top: 8px;
    padding-right: 5px;
}
.form-style-2 span.required{
    color:red;
}
.form-style-2 .tel-number-field{
    width: 40px;
    text-align: center;
}
.form-style-2 input.input-field{
    width: 48%;

}
.form-style-2 input.input-field,
.form-style-2 .tel-number-field,
.form-style-2 .textarea-field,
 .form-style-2 .select-field{
    box-sizing: border-box;
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    border: 1px solid #C2C2C2;
    box-shadow: 1px 1px 4px #EBEBEB;
    -moz-box-shadow: 1px 1px 4px #EBEBEB;
    -webkit-box-shadow: 1px 1px 4px #EBEBEB;
    border-radius: 3px;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
    padding: 7px;
    outline: none;
}
.form-style-2 .input-field:focus,
.form-style-2 .tel-number-field:focus,
.form-style-2 .textarea-field:focus,
.form-style-2 .select-field:focus{
    border: 1px solid #0C0;
}
.form-style-2 .textarea-field{
    height:50px;
    width: 55%;
}
.form-style-2 input[type=submit],
.form-style-2 input[type=button]{
    border: none;
    padding: 8px 15px 8px 15px;
    background: #FF8500;
    color: #fff;
    box-shadow: 1px 1px 4px #DADADA;
    -moz-box-shadow: 1px 1px 4px #DADADA;
    -webkit-box-shadow: 1px 1px 4px #DADADA;
    border-radius: 3px;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
}
.form-style-2 input[type=submit]:hover,
.form-style-2 input[type=button]:hover{
    background: #EA7B00;
    color: #fff;
}


.form-style-3{
    width:100%;
    padding: 20px 12px 10px 20px;
    font: 15px Arial, Helvetica, sans-serif;
    float: left;
    position: relative;
}
.form-style-3-heading{
    font-weight: bold;
    font-style: italic;
    border-bottom: 2px solid #ddd;
    margin-bottom: 20px;
    font-size: 16px;
    padding-bottom: 3px;
}
.form-style-3 label{
    margin: 15px 0px 30px 0px;
    width: 160px;
    float: left;
}
.form-style-3 label{
    font-weight: bold;
    float: left;
    padding-top: 8px;
    padding-right: 5px;
}
.form-style-3 span.required{
    color:red;
}
.form-style-3 input.input-field{
    width: 160px;
    float: left;
}

.form-style-3 input.input-field,
.form-style-3 .tel-number-field,
.form-style-3 .textarea-field,
 .form-style-3 .select-field{
    box-sizing: border-box;
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    border: 1px solid #C2C2C2;
    box-shadow: 1px 1px 4px #EBEBEB;
    -moz-box-shadow: 1px 1px 4px #EBEBEB;
    -webkit-box-shadow: 1px 1px 4px #EBEBEB;
    border-radius: 3px;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
    padding: 7px;
    outline: none;
}
.form-style-3 .input-field:focus,
.form-style-3 .tel-number-field:focus,
.form-style-3 .textarea-field:focus,
.form-style-3 .select-field:focus{
    border: 1px solid #0C0;
}
.form-style-3 .textarea-field{
    height:100px;
    width: 55%;
}
.form-style-3 input[type=submit],
.form-style-3 input[type=button]{
    border: none;
    padding: 8px 15px 8px 15px;
    background: #FF8500;
    color: #fff;
    box-shadow: 1px 1px 4px #DADADA;
    -moz-box-shadow: 1px 1px 4px #DADADA;
    -webkit-box-shadow: 1px 1px 4px #DADADA;
    border-radius: 3px;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
}
.form-style-3 input[type=submit]:hover,
.form-style-3 input[type=button]:hover{
    background: #EA7B00;
    color: #fff;
}
span.sm {font-size: 11px;}
</style>
<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select borrow_status from ctborrow_status
</cfquery>
<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct(institution_acronym)  from collection
</cfquery>
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(trans_agent_role)  from cttrans_agent_role 
           where trans_agent_role != 'recipient institution'
           order by trans_agent_role 
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from collection order by collection
</cfquery>
<cfoutput>
<script>

jQuery(document).ready(function() {
	jQuery("##received_date").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##lenders_loan_date").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##due_date").datepicker({ dateFormat: 'yy-mm-dd'});	
	jQuery("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##received_date_after").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##received_date_before").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##due_date_after").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##due_date_before").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##lenders_loan_date_after").datepicker({ dateFormat: 'yy-mm-dd'});
	jQuery("##lenders_loan_date_before").datepicker({ dateFormat: 'yy-mm-dd'});
	//shipped_date
	$.each($("input[id^='shipped_date']"), function() {
		$("##" + this.id).datepicker({ dateFormat: 'yy-mm-dd'});
   	});
});

function setBorrowNum(cid,v){
	$("##borrow_number").val(v);
	$("##collection_id").val(cid);
}

</script>
</cfoutput>

<cfset title="Borrow">

<cfif action is "nothing">
    <div style="width: 50em;margin: 0 auto;overflow: hidden;padding: 2em 0;">
	<cfoutput>
	Find Borrows:
	<form name="borrow" method="post" action="Borrow.cfm">
		<input type="hidden" name="action" value="findEm">
		<label for="trans_agent_role_1">Agent 1</label>
		<select name="trans_agent_role_1">
			<option value="">Please choose an agent role...</option>
			<cfloop query="cttrans_agent_role">
				<option value="#trans_agent_role#">-> #trans_agent_role#:</option>
			</cfloop>
		</select>
		<label for="agent_1">Agent 1 Name</label>
		<input type="text" name="agent_1"  size="50">
		<label for="trans_agent_role_2">Agent 2</label>
		<select name="trans_agent_role_2">
			<option value="">Please choose an agent role...</option>
			<cfloop query="cttrans_agent_role">
				<option value="#trans_agent_role#">-> #trans_agent_role#:</option>
			</cfloop>
		</select>
		<label for="agent_2">Agent 2 Name</label>
		<input type="text" name="agent_2"  size="50">
		<label for="collection_id">Collection</label>
		<select name="collection_id" size="1" id="collection_id">
			<option value=""></option>
			<cfloop query="ctcollection">
				<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
			</cfloop>
		</select>
		<label for="borrow_number">MCZ Borrow Number (Byyyy-0-Aaa)</label>
		<input type="text" name="borrow_number" id="borrow_number"  >
		<label for="LENDERS_TRANS_NUM_CDE">Lender's Loan Number</label>
		<input type="text" name="LENDERS_TRANS_NUM_CDE" id="LENDERS_TRANS_NUM_CDE">
		<label for="lender_loan_type">Lender's Loan Type</label>
		<input type="text" name="lender_loan_type" id="lender_loan_type">
		<label for="LENDERS_INVOICE_RETURNED_FG">Lender acknowledged returned?</label>
		<select name="LENDERS_INVOICE_RETURNED_FG" id="LENDERS_INVOICE_RETURNED_FG" size="1">
			<option value=""></option>
			<option value="1">yes</option>
			<option value="0">no</option>
		</select>
		<label for="borrow_status">Status</label>
		<select name="borrow_status" id="borrow_status" size="1" class="reqdCld">
			<option value=""></option>
			<cfloop query="ctStatus">
				<option value="#ctStatus.borrow_status#">#ctStatus.borrow_status#</option>
			</cfloop>
		</select>
		<label for="received_date">Received Date</label>
		<input type="text" name="received_date_after" id="received_date_after"> -
		<input type="text" name="received_date_before" id="received_date_before">
		<span class="infoLink" onclick="$('##received_date_before').val($('##received_date_after').val());">copy</span>
		<label for="due_date_after">Due Date</label>
		<input type="text" name="due_date_after" id="due_date_after"> -
		<input type="text" name="due_date_before" id="due_date_before">
		<span class="infoLink" onclick="$('##due_date_before').val($('##due_date_after').val());">copy</span>
		<label for="lenders_loan_date">Lender's Loan Date</label>
		<input type="text" name="lenders_loan_date_after" id="lenders_loan_date_after"> -
		<input type="text" name="lenders_loan_date_before" id="lenders_loan_date_before">
		<span class="infoLink" onclick="$('##lenders_loan_date_before').val($('##lenders_loan_date_after').val());">copy</span>
		<label for="LENDERS_INSTRUCTIONS">Lender's Instructions</label>
		<input type="text" name="LENDERS_INSTRUCTIONS" id="LENDERS_INSTRUCTIONS">
		<label for="NATURE_OF_MATERIAL">Nature of Material</label>
		<input type="text" name="NATURE_OF_MATERIAL" id="NATURE_OF_MATERIAL">
        <label for="DESCRIPTION_OF_BORROW">Description</label>
		<input type="text" name="DESCRIPTION_OF_BORROW" id="DESCRIPTION_OF_BORROW">
		<label for="TRANS_REMARKS">Transaction Remarks</label>
		<input type="text" name="TRANS_REMARKS" id="TRANS_REMARKS">
        <label for="catalog_number">Catalog Number</label>
		<input type="text" name="Catalog_number" id="Catalog_number">
         <label for="sci_name">Scientific Name</label>
		<input type="text" name="sci_name" id="sci_name">
		<br>
		<input type="submit" class="schBtn"	value="Find matches">
		<input type="reset" class="clrBtn"	value="Clear Form">
	</form>
	</cfoutput>
    </div>
</cfif>
<!------------------------------------------------------------------------------------------------------->
<cfif action is "findEm">
<cfset title="Find Borrows">
     <div style="width: 90%;margin: 0 auto;overflow: hidden;padding: 2em 0;">
	<cfoutput>
		<cfset f="trans,
				borrow,
				trans_agent,
				preferred_agent_name">
		<cfset w="trans.transaction_id = borrow.transaction_id and
				trans.transaction_id = trans_agent.transaction_id (+) and
				trans_agent.agent_id=preferred_agent_name.agent_id (+)">

		<cfif (isdefined("trans_agent_role_1") and len(trans_agent_role_1) gt 0) or (isdefined("agent_1") and len(agent_1) gt 0)>
			<cfset f=f & ", agent_name a1,trans_agent ta1">
			<cfset w=w & " and trans.transaction_id=ta1.transaction_id and ta1.agent_id=a1.agent_id">
			<cfif isdefined("trans_agent_role_1") and len(trans_agent_role_1) gt 0>
				<cfset w=w & " and ta1.trans_agent_role='#trans_agent_role_1#'">
			</cfif>
			<cfif isdefined("agent_1") and len(agent_1) gt 0>
				<cfset w=w & " and upper(a1.agent_name) like '%#ucase(agent_1)#%'">
			</cfif>
		</cfif>
		<cfif (isdefined("trans_agent_role_2") and len(trans_agent_role_2) gt 0) or (isdefined("agent_2") and len(agent_2) gt 0)>
			<cfset f=f & ", agent_name a2,trans_agent ta2">
			<cfset w=w & " and trans.transaction_id=ta2.transaction_id and ta2.agent_id=a2.agent_id">
			<cfif isdefined("trans_agent_role_2") and len(trans_agent_role_2) gt 0>
				<cfset w=w & " and ta2.trans_agent_role='#trans_agent_role_2#'">
			</cfif>
			<cfif isdefined("agent_2") and len(agent_2) gt 0>
				<cfset w=w & " and upper(a2.agent_name) like '%#ucase(agent_2)#%'">
			</cfif>
		</cfif>
		<cfif isdefined("collection_id") and len(collection_id) gt 0>
			<cfset w=w & " and trans.collection_id=#collection_id#">
		</cfif>
		<cfif isdefined("borrow_number") and len(borrow_number) gt 0>
			<cfset w=w & " and upper(borrow_number) like '%#ucase(borrow_number)#%'">
		</cfif>
		<cfif isdefined("LENDERS_TRANS_NUM_CDE") and len(LENDERS_TRANS_NUM_CDE) gt 0>
			<cfset w=w & " and upper(LENDERS_TRANS_NUM_CDE) like '%#ucase(LENDERS_TRANS_NUM_CDE)#%'">
		</cfif>
		<cfif isdefined("lender_loan_type") and len(lender_loan_type) gt 0>
			<cfset w=w & " and lender_loan_type = '#lender_loan_type#'">
		</cfif>
		<cfif isdefined("LENDERS_INVOICE_RETURNED_FG") and len(LENDERS_INVOICE_RETURNED_FG) gt 0>
			<cfset w=w & " and LENDERS_INVOICE_RETURNED_FG = #lender_loan_type#">
		</cfif>
		<cfif isdefined("borrow_status") and len(borrow_status) gt 0>
			<cfset w=w & " and borrow_status = '#borrow_status#'">
		</cfif>
		<cfif isdefined("received_date_after") and len(received_date_after) gt 0>
			<cfset w=w & " and to_char(received_date,'yyyy-mm-dd') >= '#received_date_after#'">
		</cfif>
		<cfif isdefined("received_date_before") and len(received_date_before) gt 0>
			<cfset w=w & " and to_char(received_date,'yyyy-mm-dd') <= '#received_date_before#'">
		</cfif>
		<cfif isdefined("lenders_loan_date_after") and len(lenders_loan_date_after) gt 0>
			<cfset w=w & " and to_char(lenders_loan_date,'yyyy-mm-dd') >= '#lenders_loan_date_after#'">
		</cfif>
		<cfif isdefined("lenders_loan_date_before") and len(lenders_loan_date_before) gt 0>
			<cfset w=w & " and to_char(lenders_loan_date,'yyyy-mm-dd') <= '#lenders_loan_date_before#'">
		</cfif>
		<cfif isdefined("due_date_after") and len(due_date_after) gt 0>
			<cfset w=w & " and to_char(due_date,'yyyy-mm-dd') >= '#due_date_after#'">
		</cfif>
		<cfif isdefined("due_date_before") and len(due_date_before) gt 0>
			<cfset w=w & " and to_char(due_date,'yyyy-mm-dd') <= '#due_date_before#'">
		</cfif>
		<cfif isdefined("LENDERS_INSTRUCTIONS") and len(LENDERS_INSTRUCTIONS) gt 0>
			<cfset w=w & " and upper(LENDERS_INSTRUCTIONS) like '%#ucase(LENDERS_INSTRUCTIONS)#%'">
		</cfif>
		<cfif isdefined("NATURE_OF_MATERIAL") and len(NATURE_OF_MATERIAL) gt 0>
			<cfset w=w & " and upper(NATURE_OF_MATERIAL) like '%#ucase(NATURE_OF_MATERIAL)#%'">
		</cfif>
            <cfif isdefined("DESCRIPTION_OF_BORROW") and len(DESCRIPTION_OF_BORROW) gt 0>
			<cfset w=w & " and upper(DESCRIPTION_OF_BORROW) like '%#ucase(DESCRIPTION_OF_BORROW)#%'">
		</cfif>
		<cfif isdefined("TRANS_REMARKS") and len(TRANS_REMARKS) gt 0>
			<cfset w=w & " and upper(TRANS_REMARKS) like '%#ucase(TRANS_REMARKS)#%'">
		</cfif>


		<cfquery name="getBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				borrow.TRANSACTION_ID,
				LENDERS_TRANS_NUM_CDE,
				BORROW_NUMBER,
				LENDERS_INVOICE_RETURNED_FG,
				RECEIVED_DATE,
				DUE_DATE,
				LENDERS_LOAN_DATE,
				BORROW_STATUS,
				LENDERS_INSTRUCTIONS,
                DESCRIPTION_OF_BORROW,
            NO_OF_SPECIMENS,
				TRANS_DATE,
				CORRESP_FG,
				NATURE_OF_MATERIAL,
				TRANS_REMARKS,
				lender_loan_type,
				preferred_agent_name.agent_name,
				trans_agent.trans_agent_role
			FROM
				#preservesinglequotes(f)#
			WHERE
				#preservesinglequotes(w)#
		</cfquery>
		<cfif getBorrow.recordcount is 0>
			<div class="error">Nothing matched. Use your back button to try again.</div>
			<cfabort>
		</cfif>
		<cfquery name="b" dbtype="query">
			select
				TRANSACTION_ID,
				LENDERS_TRANS_NUM_CDE,
				BORROW_NUMBER,
				LENDERS_INVOICE_RETURNED_FG,
				RECEIVED_DATE,
				DUE_DATE,
				LENDERS_LOAN_DATE,
				BORROW_STATUS,
				LENDERS_INSTRUCTIONS,
				TRANS_DATE,
				CORRESP_FG,
				NATURE_OF_MATERIAL,
            DESCRIPTION_OF_BORROW,
            NO_OF_SPECIMENS,
				TRANS_REMARKS,
				lender_loan_type
			from
				getBorrow
			group by
				TRANSACTION_ID,
				LENDERS_TRANS_NUM_CDE,
				BORROW_NUMBER,
				LENDERS_INVOICE_RETURNED_FG,
				RECEIVED_DATE,
				DUE_DATE,
				LENDERS_LOAN_DATE,
				BORROW_STATUS,
				LENDERS_INSTRUCTIONS,
            DESCRIPTION_OF_BORROW,
            NO_OF_SPECIMENS,
				TRANS_DATE,
				CORRESP_FG,
				NATURE_OF_MATERIAL,
				TRANS_REMARKS,
				lender_loan_type
		</cfquery>
            <h3 style="margin-bottom: .5em;">Borrow Search Results</h3>
		<table border>
			<tr>
				<td>
					MCZ Transaction ##
				</td>
				<td>
					Type
				</td>
				<td>
					Received Date
				</td>
				<td>
					Due Date
				</td>
				<td>
					Status
				</td>
				<td>
					Nature of Material
				</td>
				<td>
					Agents
				</td>
			</tr>
		<cfloop query="b">
			<tr>
				<td style="width:100px;padding: 10px;">
					<a href="Borrow.cfm?action=edit&transaction_id=#transaction_id#">
						#BORROW_NUMBER#
					</a>
				</td>
				<td style="width:60px;padding: 10px;">
					#lender_loan_type#
				</td>
				<td style="width:100px;padding: 10px;">
					#dateformat(RECEIVED_DATE,"yyyy-mm-dd")#
				</td>
				<td style="width:100px;padding: 10px;">
					#dateformat(DUE_DATE,"yyyy-mm-dd")#
				</td>
				<td style="width:60px;padding: 10px;">
					#BORROW_STATUS#
				</td>
				<td style="width: 420px;padding: 10px;">
					#NATURE_OF_MATERIAL#
				</td>
				<cfquery name="a" dbtype="query">
					select
						agent_name,
						trans_agent_role
					from
						getBorrow
					where
						transaction_id=#transaction_id#
					group by
						agent_name,
						trans_agent_role
					order by
						trans_agent_role,
						agent_name
				</cfquery>

				<td style="width: 300px;padding: 10px;">
					<cfloop query="a">
						#trans_agent_role#: #agent_name#<br>
					</cfloop>
				</td>
			</tr>
		</cfloop>
		</table>

	</cfoutput>
    </div>
</cfif>
<!------------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfset title="Edit Borrow">
  <div style="width: 95%;margin: 0 auto;overflow: hidden;padding: 2em;">
<cfoutput>
		<cfquery name="getBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				borrow.TRANSACTION_ID,
				LENDERS_TRANS_NUM_CDE,
				BORROW_NUMBER,
				LENDERS_INVOICE_RETURNED_FG,
				RECEIVED_DATE,
				DUE_DATE,
				LENDERS_LOAN_DATE,
				BORROW_STATUS,
				LENDERS_INSTRUCTIONS,
				concattransagent(trans.transaction_id,'entered by') enteredby,
				TRANS_DATE,
				CORRESP_FG,
				NATURE_OF_MATERIAL,
                DESCRIPTION_OF_BORROW,
                NO_OF_SPECIMENS,
				TRANS_REMARKS,
				lender_loan_type,
				collection.collection
			FROM
				trans,
				borrow,
				collection
			WHERE
				trans.transaction_id = borrow.transaction_id and
				trans.collection_id = collection.collection_id and
				borrow.transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				trans_agent_id,
				trans_agent.agent_id,
				agent_name,
				trans_agent_role,
                        	MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
			from
				trans_agent,
				preferred_agent_name
			where
				trans_agent.agent_id = preferred_agent_name.agent_id and
				trans_agent_role != 'entered by' and
				trans_agent.transaction_id=#transaction_id#
			order by
				trans_agent_role,
				agent_name
		</cfquery>
	<table><tr><td valign="top">
       <h2 class="wikilink" style="margin-left: 0;">Edit Borrow <img src="/images/info_i_2.gif" onClick="getMCZDocs('Borrow')" class="likeLink" alt="[ help ]">
        <span class="loanNum">#getBorrow.collection# #getBorrow.borrow_number# </span>	</h2>
	<form name="borrow" id="borrow" method="post" action="Borrow.cfm">
	<input type="hidden" name="action" value="update">
	<input type="hidden" name="transaction_id" value="#getBorrow.transaction_id#">
	<table class="editLoanTable"> 
		<tr>
			<td colspan="3">
				<span style="font-size:14px;">Entered by #getBorrow.enteredby#</span>
 				</td>
		</tr>
		<tr>
			<td>
				<label for="collection_id">Collection</label>
				<span id="collection_id">#getBorrow.collection#</span>
			</td>
			<td colspan="3">
				<label for="borrow_number">MCZ Borrow Number</label>
				<input type="text" name="borrow_number" id="borrow_number"
				       required pattern="#BORROWNUMBERPATTERN#"
					value="#getBorrow.borrow_number#">
			</td>
		</tr>
		<tr>
			<td colspan="3">
				<table id="loanAgents"> <!--- id of loanAgents is used by addTransAgent() to find table to add rows to --->
					<tr>
						<th>Agent Name  <span class="linkButton" onclick=" addTransAgentToForm('','','','borrow'); ">Add Row</span> </th>
						<th></th>
						<th>Role</th>
						<th>Delete?</th>
						<th>CloneAs</th>
					</tr>
					<cfset i=0>
					<cfloop query="transAgents">
						<cfset i++>
						<tr>
							<td>
								<!--- original value ---> 
								<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
								<!--- text value ---> 
								<input type="text" name="trans_agent_#i#" id="trans_agent_#i#"
									class="reqdClr" size="30" value="#agent_name#"
				  					onchange="getAgent('agent_id_#i#','trans_agent_#i#','borrow',this.value); return false;"
				  					onKeyPress="return noenter(event);">
								<!--- new value ---> 
				  				<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#" 
									onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#');" >
							</td>
							<td style=" min-width: 3.5em; ">
							    <span id="agentViewLink_#i#"><a href="/agents.cfm?agent_id=#agent_id#" target="_blank">View</a><cfif transAgents.worstagentrank EQ 'A'> &nbsp;<cfelseif transAgents.worstagentrank EQ 'F'><img src='/images/flag-red.svg.png' width='16'><cfelse><img src='/images/flag-yellow.svg.png' width='16'></cfif>
                        			                    </span>
 								</td>
							<td>
								<cfset thisRole = #trans_agent_role#>
								<select name="trans_agent_role_#i#" id="trans_agent_role_#i#">
									<cfloop query="cttrans_agent_role">
										<option 
											<cfif #trans_agent_role# is #thisRole#> selected="selected"</cfif>
											value="#trans_agent_role#">#trans_agent_role#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1">
							</td>
							<td>
								<select id="cloneTransAgent_#i#" name="cloneTransAgent_#i#"
									onchange="cloneTransAgent(#i#)" style="width:8em">
								<option value=""></option>
								<cfloop query="cttrans_agent_role">
									<option value="#trans_agent_role#">#trans_agent_role#</option>
								</cfloop>
								</select>
							</td>
						</tr>
						<cfset na = i>
					</cfloop>
					<input type="hidden" id="numAgents" name="numAgents" value="#na#">
				</table>
			</td>
			<td>
			</td>
		</tr>
		<tr>
			<td>
				<label for="LENDERS_TRANS_NUM_CDE">Lender's Loan Number</label>
				<input type="text" name="LENDERS_TRANS_NUM_CDE" id="LENDERS_TRANS_NUM_CDE"
					value="#getBorrow.LENDERS_TRANS_NUM_CDE#">
			</td>
			<td>
				<label for="lender_loan_type">Lender's Loan Type</label>
				<input type="text" name="lender_loan_type" id="lender_loan_type"
					value="#getBorrow.lender_loan_type#">
			</td>
			<td>
				<label for="borrow_status">Status</label>
				<select name="borrow_status" id="borrow_status" size="1" class="reqdCld">
					<cfloop query="ctStatus">
						<option 
							<cfif #ctStatus.borrow_status# is "#getBorrow.BORROW_STATUS#"> selected </cfif>
						value="#ctStatus.borrow_status#">#ctStatus.borrow_status#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="LENDERS_INVOICE_RETURNED_FG">Lender acknowledged returned?</label>
				<select name="LENDERS_INVOICE_RETURNED_FG" id="LENDERS_INVOICE_RETURNED_FG" size="1">
					<option <cfif #getBorrow.LENDERS_INVOICE_RETURNED_FG# IS 1> selected </cfif>
						value="1">yes</option>
					<option <cfif #getBorrow.LENDERS_INVOICE_RETURNED_FG# IS 0> selected </cfif>
						value="0">no</option>
				</select>
			</td>
		</tr>
		<tr>
			<td>
				<label for="received_date">Received Date</label>
				<input type="text" name="received_date" id="received_date" value="#dateformat(getBorrow.RECEIVED_DATE,"yyyy-mm-dd")#">
			</td>
			<td>
				<label for="due_date">Due Date</label>
				<input type="text" name="due_date" id="due_date" value="#dateformat(getBorrow.DUE_DATE,"yyyy-mm-dd")#">
			</td>
			<td>
				<label for="lenders_loan_date">Lender's Loan Date</label>
				<input type="text" name="lenders_loan_date" id="lenders_loan_date" value="#dateformat(getBorrow.LENDERS_LOAN_DATE,"yyyy-mm-dd")#">
			</td>
			<td>
				<label for="no_of_specimens">Total No. of Specimens</label>
				<input type="text" name="no_of_specimens" id="no_of_specimens" value="#getBorrow.no_of_specimens#">
			</td>
		</tr>
		<tr>
			<td colspan="4">
				<label for="LENDERS_INSTRUCTIONS">Lender's Instructions</label>
				<textarea name="LENDERS_INSTRUCTIONS" id="LENDERS_INSTRUCTIONS" rows="3" cols="120">#getBorrow.LENDERS_INSTRUCTIONS#</textarea>
			</td>
		</tr>
		<tr>
			<td colspan="4">
				<label for="NATURE_OF_MATERIAL">Nature of Material</label>
				<textarea name="NATURE_OF_MATERIAL" id="NATURE_OF_MATERIAL" rows="3" cols="120" class="reqdClr" required>#getBorrow.NATURE_OF_MATERIAL#</textarea>
			</td>
		</tr>
            	<tr>
			<td colspan="4">
				<label for="DESCRIPTION_OF_BORROW">Description</label>
				<textarea name="DESCRIPTION_OF_BORROW" id="DESCRIPTION_OF_BORROW" rows="3" cols="120" class="reqdClr" required >#getBorrow.DESCRIPTION_OF_BORROW#</textarea>
			</td>
		</tr>
      
            
		<tr>
			<td colspan="4">
				<label for="TRANS_REMARKS">Transaction Remarks</label>
				<textarea name="TRANS_REMARKS" id="TRANS_REMARKS" rows="3" cols="120">#getBorrow.TRANS_REMARKS#</textarea>
			</td>
		</tr>
		<tr>
			<td colspan="4">
				<input type="button" class="schBtn" value="Save Edits" 
				       onClick="if (checkFormValidity($('##borrow')[0])) { borrow.action.value='update'; submit();  } ">
				<input type="button" class="delBtn" value="Delete Borrow"
					onclick="borrow.action.value='delete';confirmDelete('borrow');">
			</td>
		</tr>
            	<tr>
			<td colspan="4">
   			<label for="redir">Print...Return Receipt</label>
			<select name="redir" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
   				<option value=""></option>
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_borrower_header">MCZ Return Receipt Header</option>
            			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_borrow_items">MCZ Return Receipt Items</option>
        		</select>
   			<div><strong>The return shipment must be entered below and marked 'Printed on invoice' (make sure that you don't have the shipment to the MCZ marked as 'Printed on invoice', or else the addresses will show up in the wrong places on the return receipt header).<strong></div>
			</td>
		</tr>
			
	</table>
	</form>
	<table style="width:100%;border: 1px solid ##666;margin: 20px 0;">   
            <tr>
                <td>
                  <div id="borrowItems"></div>

              </td>
            </tr>
</table>
<table>
            <tr>
				<form id="addBorrowItemform">
	               <h4 style="margin-bottom: 0;margin-left: 5px;">Add Borrowed Item</h4>
	               <input type="hidden" name="method" value="addBorrowItem">
	                 <input type="hidden" name="returnformat" value="json">
	                 <input type="hidden" name="queryformat" value="column">
	                <input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
	               <td><label for="catalog_number" style="width: 120px;margin-right: 5px;">Catalog Number <input type="text" class="input-field" name="catalog_number" id="catalog_number" style="width: 120px;margin-right: 5px;"></label></td>
	                <td><label for="sci_name" style="width: 190px;margin-right:5px;">Scientific Name <input type="text" class="input-field" name="sci_name" id="sci_name" style="width: 190px;margin-right:5px;"></label></td>
	                <td><label for="no_of_spec" style="width: 113px;margin-right: 5px;">No.&nbsp;of&nbsp;Specimens <input type="text" class="input-field" name="no_of_spec" id="no_of_spec" style="width: 113px;margin-right: 5px;"></label></td>
	                <td><label for="spec_prep" style="width: 156px;">Specimen Preparation <input type="text" class="input-field" name="spec_prep" id="spec_prep" style="width: 156px;"></label></td>
	                <td><label for="type_status" style="width:93px;">Type Status <input type="text" class="input-field" name="type_status" id="type_status" style="width:93px;"></label></td>
	                <td><label for="country_of_origin" style="width: 116px;">County of Origin <input type="text" class="input-field" name="country_of_origin" id="country_of_origin" style="width: 116px;"></label></td>
	                <td><label for="object_remarks" style="width: 170px;">Remarks <input type="text" class="input-field" name="object_remarks" id="object_remarks" style="width: 170px;"></label></td>
	                <td><label style="width:75px;margin:20px 0 0 0;padding:0;"><input class="input-field" type="button" onclick=" addBorrowItem2(); " style="cursor:pointer;background-color: ##76afd0;background-color: cornflowerblue;border:1px solid cornflowerblue;width:75px;padding-left: 8px;" value="Add Row"></label></td>
	           	</form>
	        </tr>

			<script>
			    function addBorrowItem2() {
				    jQuery.ajax(
			            {
			                url : "/component/functions.cfc",
			                type : "post",
			                dataType : "json",
			                data : $("##addBorrowItemform").serialize(),
			                success : function (data) {
			                    loadBorrowItems(#transaction_id#);
			                    $("##catalog_number").val('');
			                    $("##no_of_spec").val('');
			                    $("##type_status").val('');
			                },
			                fail: function(jqXHR,textStatus){
			                    alert(textStatus);
			                }
			            }
			        );
			    };
			        function deleteBorrowItem(borrow_item_id) {
				    jQuery.ajax(
			            {
			                url : "/component/functions.cfc",
			                type : "post",
			                dataType : "json",
			                data : {
			                   method : "deleteBorrowItem",
			                   returnformat : "json",
			                   queryformat : 'column',
			                   borrow_item_id : borrow_item_id
			                },
			                success : function (data) {
			                    loadBorrowItems(#transaction_id#);
			                },
			                fail: function(jqXHR,textStatus){
			                    alert(textStatus);
			                }
			            }
			        );
			    };
			    function loadBorrowItems(transaction_id) {

			        jQuery.ajax({
			          url: "component/functions.cfc",
			          data : {
			            method : "getBorrowItemsHTML",
			            transaction_id : transaction_id
			         },
			        success: function (result) {
			           $("##borrowItems").html(result);
			        },
			        dataType: "html"
			       }
			     )};
			    $(document).ready(loadBorrowItems(#transaction_id#));

			</script>
</table>
<table>
			<tr></tr>
			<tr>
				<h4 style="margin-bottom: 0;margin-left: 5px;">Upload Items From CSV File</h4>
				<cfform name="csv" method="post" action="/Borrow.cfm" enctype="multipart/form-data">
	           		<input type="hidden" name="action" value="getFile">
	           		<input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
	           		<td>
	           		<input type="file"
		   				name="FiletoUpload"
		   				size="45">
			  		<input type="submit" value="Upload this file" >
			  		</td>
			  	</cfform>
			</tr>
			<tr>
			  		<td>
			  			<p style="margin: 1em 0;"><span class="likeLink" onclick=" toggleTemplate(); " id="toggleLink">View csv file template</span></p>
						<div id="template" style="display:none;">
							<label for="t">Copy the following code and save as a .csv file</label>
							<textarea rows="2" cols="90" id="t">CATALOG_NUMBER,SCI_NAME,NO_OF_SPEC,SPEC_PREP,TYPE_STATUS,COUNTRY_OF_ORIGIN,OBJECT_REMARKS</textarea>
						</div>
						<script>
							function toggleTemplate() { 
								$('##template').toggle();
								if ($('##template').is(':visible')) { 
									$('##toggleLink').html('Hide csv file temlate');
								} else { 
									$('##toggleLink').html('View csv file temlate');
								}
							}
						</script>
					</td>
			</tr>
</table>

<div class="shippingBlock">
    <h3>Shipment Information:</h3>
<script>

function opendialog(page,id,title) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>'
  var adialog = $(id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    height: 800,
    width: 950,
    minWidth: 400,
    minHeight: 450,
    draggable:true,
    resizable:true,
    buttons: { "Ok": function () { loadShipments(#transaction_id#); $(this).dialog("destroy"); $(id).html(''); } },
    close: function() { loadShipments(#transaction_id#);  $(this).dialog( "destroy" ); $(id).html(); }
  });
  adialog.dialog('open');
};

</script>

	<cfquery name="ctShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
	</cfquery>
	<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                 select sh.*, toaddr.country_cde tocountry, toaddr.institution toinst, fromaddr.country_cde fromcountry, fromaddr.institution frominst
                 from shipment sh
                    left join addr toaddr on sh.shipped_to_addr_id  = toaddr.addr_id
                    left join addr fromaddr on sh.shipped_from_addr_id = fromaddr.addr_id
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getBorrow.transaction_id#">
	</cfquery>
    <div id="shipmentTable">Loading shipments...</div> <!--- shippmentTable for ajax replace --->

    <div class="addstyle">
        <input type="button" value="Add Shipment" class="lnkBtn" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);">
        <div class="shipmentnote">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div>
    </div><!--- end addstyle --->
</div> <!--- end Shipping block --->

<script>

$( document ).ready(loadShipments(#transaction_id#));

$(function() {
      $("##dialog-shipment").dialog({
        autoOpen: false,
        modal: true,
        width: 650,
        buttons: {
          "Save": function() {  saveShipment(#transaction_id#); } ,
          Cancel: function() {
            $(this).dialog( "close" );
          }
        },
        close: function() {
            $(this).dialog( "close" );
        }
      });
});

</script>


<div id="dialog-shipment" title="Create new Shipment">
  <form name="shipmentForm" id="shipmentForm" >
    <fieldset>
	<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
	<input type="hidden" name="shipment_id" value="" id="shipment_id">
	<input type="hidden" name="returnFormat" value="json" id="returnFormat">
           <table>
             <tr>
              <td>
		<label for="shipped_carrier_method">Shipping Method</label>
		<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctShip">
				<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
			</cfloop>
		</select>
              </td>
              <td colspan="2">
		<label for="carriers_tracking_number">Tracking Number</label>
		<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" >
              </td>
            </tr><tr>
              <td>
		<label for="no_of_packages">Number of Packages</label>
		<input type="text" value="1" name="no_of_packages" id="no_of_packages">
              </td>
              <td>
		<label for="shipped_date">Ship Date</label>
		<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date">
              </td>
              <td>
		<label for="foreign_shipment_fg">Foreign shipment?</label>
		<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr><tr>
              <td>
		<label for="package_weight">Package Weight (TEXT, include units)</label>
		<input type="text" value="" name="package_weight" id="package_weight">
              </td>
              <td>
		<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
		<input type="text" validate="float" label="Numeric value required."
			 value="" name="insured_for_insured_value" id="insured_for_insured_value">
              </td>
              <td>
		<label for="hazmat_fg">HAZMAT?</label>
		<select name="hazmat_fg" id="hazmat_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr>
           </table>

		<label for="packed_by_agent">Packed By Agent</label>
		<input type="text" name="packed_by_agent" class="reqdClr" size="50" value="" id="packed_by_agent"
			  onchange="getAgent('packed_by_agent_id','packed_by_agent','shipmentForm',this.value); return false;"
			  onKeyPress="return noenter(event);">
		<input type="hidden" name="packed_by_agent_id" value="" id="packed_by_agent_id" >

		<label for="shipped_to_addr">Shipped To Address</label>
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_to_addr_id','shipped_to_addr','shipmentForm'); return false;">
		<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">

		<label for="shipped_from_addr">Shipped From Address</label>
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_from_addr_id','shipped_from_addr','shipmentForm'); return false;">
		<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id" value="">

		<label for="shipment_remarks">Remarks</label>
		<input type="text" value="" name="shipment_remarks" id="shipment_remarks" size="60">
		<label for="contents">Contents</label>
		<input type="text" value="" name="contents" id="contents" size="60">

    </fieldset>
  </form>
  <div id="shipmentFormPermits"></div>
  <div id="shipmentFormStatus"></div>
</div>


	</cfoutput>
                </div>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>
	<!--- upload items --->
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
					<cfset colVals="#colVals#,'#thisBit#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames="TRANSACTION_ID#colNames#">
		</cfif>
		<cfif len(#colVals#) gt 1>
			<cfset colVals="#transaction_id##colVals#">
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into BORROW_ITEM (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="Borrow.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------->

<!------------------------------------------------------------------------------------------------------->
<cfif action is "update">
  <cfoutput>
  <cftransaction>
	<cfquery name="setBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE borrow SET
		LENDERS_INVOICE_RETURNED_FG = #LENDERS_INVOICE_RETURNED_FG#,
		LENDERS_TRANS_NUM_CDE = '#LENDERS_TRANS_NUM_CDE#',
        LENDER_LOAN_TYPE = '#LENDER_LOAN_TYPE#',
		RECEIVED_DATE = to_date('#RECEIVED_DATE#','yyyy-mm-dd'),
		DUE_DATE = to_date('#DUE_DATE#','yyyy-mm-dd'),
		LENDERS_LOAN_DATE = to_date('#LENDERS_LOAN_DATE#','yyyy-mm-dd'),
		LENDERS_INSTRUCTIONS = '#LENDERS_INSTRUCTIONS#',
        DESCRIPTION_OF_BORROW = '#DESCRIPTION_OF_BORROW#',
        NO_OF_SPECIMENS = '#NO_OF_SPECIMENS#',
		BORROW_STATUS = '#BORROW_STATUS#'
	WHERE
		TRANSACTION_ID=#TRANSACTION_ID#
	</cfquery>
	<cfquery name="setTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE trans SET
			NATURE_OF_MATERIAL = '#NATURE_OF_MATERIAL#',
			TRANS_REMARKS = '#TRANS_REMARKS#'
		WHERE
			TRANSACTION_ID=#TRANSACTION_ID#
	</cfquery>
	<cfloop from="1" to="#numAgents#" index="n">
	   <cfif IsDefined("trans_agent_id_" & n) >
	        <cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
	        <cfset agent_id_ = evaluate("agent_id_" & n)>
	        <cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
	        <cftry>
	                <cfset del_agnt_=evaluate("del_agnt_" & n)>
	        <cfcatch>
	                <cfset del_agnt_=0>
	        </cfcatch>
	        </cftry>
	        <cfif  del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
	                <cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	                        delete from trans_agent where trans_agent_id=#trans_agent_id_#
	                </cfquery>
	        <cfelse>
	                <cfif len(agent_id_) GT 0><!--- don't try to add/update a blank row --->
	                <cfif trans_agent_id_ is "new" and del_agnt_ is 0 and len(agent_id_) GT 0>
	                        <cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	                                insert into trans_agent (
	                                        transaction_id,
	                                        agent_id,
	                                        trans_agent_role
	                                ) values (
	                                        #transaction_id#,
	                                        #agent_id_#,
	                                        '#trans_agent_role_#'
	                                )
	                        </cfquery>
	                <cfelseif del_agnt_ is 0>
	                        <cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	                                update trans_agent set
	                                        agent_id = #agent_id_#,
	                                        trans_agent_role = '#trans_agent_role_#'
	                                where
	                                        trans_agent_id=#trans_agent_id_#
	                        </cfquery>
	                </cfif>
	                </cfif>
	        </cfif>
	   </cfif>
	</cfloop>
  </cftransaction>
  <cflocation url="Borrow.cfm?action=edit&transaction_id=#transaction_id#">
  </cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------------------->
<cfif action is "new">
<cfset title="New Borrow">
<cfoutput>
    <div class="newLoanWidth">

        <h2 class="wikilink" style="margin-left: 0;">New Borrow
            <img src="/images/info_i_2.gif" onClick="getMCZDocs('Borrow')" class="likeLink" alt="[ help ]">
        </h2>

	<form name="borrow" id="borrow"  method="post" action="Borrow.cfm">
	<table border>
			<input type="hidden" name="action" value="makeNew">
			<tr>
				<td>
					<label for="collection_id">Collection</label>
					<select name="collection_id" size="1" id="collection_id">
						<option value=""></option>
						<cfloop query="ctcollection">
							<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
						</cfloop>
					</select>
				<td>
					<label for="borrow_num">MCZ Borrow Number (Byyyy-n-Coll)</label>
					<input type="text" id="borrow_number" name="borrow_number" class="reqdClr" 
					       required pattern="#BORROWNUMBERPATTERN#" >
				</td>
				<td id="upperRightCell"><!--- id for positioning nextnumDiv --->
					<label for="lenders_trans_num_cde">Lender's Loan Number</label>
					<input type="text" name="lenders_trans_num_cde" id="lenders_trans_num_cde">
				</td>
			</tr>
			<tr>
				<td>
					<label for="lender_loan_type">Lender's Loan Type</label>
					<input type="text" name="lender_loan_type" id="lender_loan_type" >
				</td>
				<td>
					<label for="lenders_loan_date">Lender's Loan Date</label>
					<input type="text" name="lenders_loan_date" id="lenders_loan_date">
				</td>
				<td></td>
			</tr>
			<tr>
				<td>
					<label for="due_date">Due Date</label>
					<input type="text" name="due_date" id="due_date">
				</td>
				<td>
					<label for="received_date">Received Date</label>
					<input type="text" name="received_date" id="received_date">
				</td>
				<td></td>
			</tr>

			<tr>
				<td>
					<label for="trans_date">Transaction Date</label>
					<input type="text" name="trans_date" id="trans_date">
				</td>
				<td>
					<label for="borrow_status">Status</label>
					<select name="borrow_status" size="1" class="reqdCld">
						<cfloop query="ctStatus">
							<option value="#ctStatus.borrow_status#">#ctStatus.borrow_status#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="LENDERS_INVOICE_RETURNED_FG">Lender acknowledged returned?</label>
					<select name="LENDERS_INVOICE_RETURNED_FG" size="1">
						<option value="0">no</option>
						<option value="1">yes</option>
					</select>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="AuthorizedBy">Authorized By (external)</label>
					<input type="text"
						name="AuthorizedBy" id="AuthorizedBy"
						class="reqdClr" required
						onchange="getAgent('auth_agent_id','AuthorizedBy','borrow',this.value); return false;"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="auth_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="OverseenBy">Borrow Overseen By (MCZ)</label>
					<input type="text"
						name="OverseenBy" id="OverseenBy"
						class="reqdClr" required
						onchange="getAgent('over_agent_id','OverseenBy','borrow',this.value); return false;"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="over_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="ReceivedBy">Received By</label>
					<input type="text"
						name="ReceivedBy" id="ReceivedBy"
						class="reqdClr" required
						onchange="getAgent('received_agent_id','ReceivedBy','borrow',this.value); return false;"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="received_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="ReceivedFrom">Received From</label>
					<input type="text"
						name="ReceivedFrom" id="ReceivedFrom"
						class="reqdClr" required
						onchange="getAgent('received_from_agent_id','ReceivedFrom','borrow',this.value); return false;"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="received_from_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="LendingInstitution">Lending Institution</label>
					<input type="text"
						name="LendingInstitution"
						onchange="getAgent('lending_institution_agent_id','LendingInstitution','borrow',this.value); return false;"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="lending_institution_agent_id">
				</td>
			</tr>
            <tr>
				<td colspan="3">
					<label for="no_of_specimens">Total No. of Specimens</label>
                    <input type="text" name="no_of_specimens">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="LENDERS_INSTRUCTIONS">Lender's Instructions</label>
					<textarea name="LENDERS_INSTRUCTIONS" rows="3" cols="90"></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="NATURE_OF_MATERIAL">Nature of Material</label>
					<textarea name="NATURE_OF_MATERIAL" id="NATURE_OF_MATERIAL" 
					          rows="3" cols="90" class="reqdClr" required ></textarea>
				</td>
			</tr>
            		<tr>
				<td colspan="3">
					<label for="DESCRIPTION_OF_BORROW">Description</label>
					<textarea name="DESCRIPTION_OF_BORROW" id="DESCRIPTION_OF_BORROW" 
					          rows="3" cols="90" class="reqdClr" required ></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="TRANS_REMARKS">Transaction Remarks</label>
					<textarea name="TRANS_REMARKS" rows="3" cols="90"></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="button" class="schBtn" value="Create Borrow"
					       onClick="if (checkFormValidity($('##borrow')[0])) { submit();  } ">
				</td>
			</tr>
	</table>
	</form>

		<div class="nextnum" id="nextNumDiv">
			<p>Next Available MCZ Borrow Number:</p>
			<cfquery name="all_coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from collection order by collection
			</cfquery>
			<cfloop query="all_coll">
					<cfset stg="'B#dateformat(now(),"yyyy")#-' || nvl(max(to_number(regexp_substr(borrow_number,'[^-]+', 1, 2))) + 1,'1') || '-#collection_cde#'">
					<cfset whr=" AND substr(borrow_number, 2,4) ='#dateformat(now(),"yyyy")#'">
				<cftry>
					<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							 #preservesinglequotes(stg)# nn
						from
							borrow,
							trans,
							collection
						where
							borrow.transaction_id=trans.transaction_id and
							trans.collection_id=collection.collection_id and
							collection.collection_id=#collection_id#
							#preservesinglequotes(whr)#
					</cfquery>
					<cfcatch>
						<hr>
						#cfcatch.detail#
						<br>
						#cfcatch.message#
						<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select
								 'check data' nn
							from
								dual
						</cfquery>
					</cfcatch>
				</cftry>
				<cfif len(thisQ.nn) gt 0>
					<span class="likeLink" onclick="setBorrowNum('#collection_id#','#thisQ.nn#')">#collection# #thisQ.nn#</span>
				<cfelse>
					<span style="font-size:x-small">
						No data available for #collection#.
					</span>
				</cfif>
				<br>
			</cfloop>
                </div>
                <script>
                        $(document).ready( function() { $('##nextNumDiv').position( { my: "left top", at: "right+4 top-3", of: $('##upperRightCell'), colision: "none" } ); } );
                </script>
        </div>
	</cfoutput>
</cfif>


<!------------------------------------------------------------------------------------------------------->
<cfif #action# is "delete">
<cfoutput>
	<cftransaction>
		<cfquery name="killAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans_agent where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from borrow where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans where transaction_id=#transaction_id#
		</cfquery>
		</cftransaction>
		<cflocation url="Borrow.cfm" addtoken="false">
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------------------->
<cfif #action# is "makeNew">
<cfoutput>
	<cfquery name="nextTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select sq_transaction_id.nextval transaction_id from dual
	</cfquery>

	<cfset transaction_id = nextTrans.transaction_id>
	<cftransaction>
	<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO trans (
			TRANSACTION_ID,
			TRANS_DATE,
			TRANS_REMARKS,
			TRANSACTION_TYPE,
			NATURE_OF_MATERIAL,
			COLLECTION_ID)
		VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
			'#dateformat(TRANS_DATE,"yyyy-mm-dd")#',
			'#escapeQuotes(TRANS_REMARKS)#',
			'borrow',
			'#escapeQuotes(NATURE_OF_MATERIAL)#',
			#collection_id#
		)
	</cfquery>
	<cfquery name="newBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO borrow (
			TRANSACTION_ID,
			LENDERS_TRANS_NUM_CDE,
			BORROW_NUMBER,
			LENDERS_INVOICE_RETURNED_FG,
			RECEIVED_DATE,
			DUE_DATE,
			LENDERS_LOAN_DATE,
			lender_loan_type,
			LENDERS_INSTRUCTIONS,
            DESCRIPTION_OF_BORROW,
            no_of_specimens,
			BORROW_STATUS
		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
			'#LENDERS_TRANS_NUM_CDE#',
			'#Borrow_Number#',
			#LENDERS_INVOICE_RETURNED_FG#,
			'#dateformat(RECEIVED_DATE,"yyyy-mm-dd")#',
			'#dateformat(DUE_DATE,"yyyy-mm-dd")#',
			'#dateformat(LENDERS_LOAN_DATE,"yyyy-mm-dd")#',
            		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lender_loan_type#">,
            		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LENDERS_INSTRUCTIONS#">,
            		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION_OF_BORROW#">,
            		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#no_of_specimens#">,
            		<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BORROW_STATUS#">
		)
		</cfquery>
		<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				#transaction_id#,
				#AUTH_AGENT_ID#,
				'authorized by')
		</cfquery>
		<cfquery name="overBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				#transaction_id#,
				#OVER_AGENT_ID#,
				'borrow overseen by')
		</cfquery>
		<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				#transaction_id#,
				#RECEIVED_AGENT_ID#,
				'received by'
			)
		</cfquery>
		<cfquery name="recfrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#received_from_agent_id#">,
				'received from'
			)
		</cfquery>
                <cfif isdefined("lending_institution_agent_id") and len(#lending_institution_agent_id#) GT 0 >
		<cfquery name="recfrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lending_institution_agent_id#">,
				'lending institution'
			)
		</cfquery>
                </cfif>
	</cftransaction>
	<cflocation url="Borrow.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------->
    </div>

<cfinclude template = "/includes/_footer.cfm">
