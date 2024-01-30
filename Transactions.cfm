<cfif not isdefined("action")>
	<cfset action="findAll">
</cfif>
<!--- handle some cases of the transaction type being passed instead of the actual plural action --->
<cfif ucase(action) IS ucase("findLoan")><cfset action="findLoans"></cfif>
<cfif ucase(action) IS ucase("findAccn")><cfset action="findAccessions"></cfif>
<cfif ucase(action) IS ucase("findBorrow")><cfset action="findBorrows"></cfif>
<cfif ucase(action) IS ucase("findDeaccession")><cfset action="findDeaccessions"></cfif>
<cfif ucase(action) IS ucase("findDeacc")><cfset action="findDeaccessions"></cfif>
<cfswitch expression="#action#">
	<!--- API note: action/method e.g. action=findLoans and method=getLoans seems duplicative, but
			action is used to determine which tab to show in Transactions.cfm, and method is passed 
			to /transactions/component/search.cfm.  When invoking with execute=true method does not
			need to be included in the call, but it will be included in the URI parameter list when
			clicking on the "Link to this search" link.
	--->
	<cfcase value="findLoans">
		<cfset pageTitle = "Search Loans">
		<cfif isdefined("execute")>
			<cfset execute="loan">
		</cfif>
	</cfcase>
	<cfcase value="findAccessions">
		<cfset pageTitle = "Search Accessions">
		<cfif isdefined("execute")>
			<cfset execute="accn">
		</cfif>
	</cfcase>
	<cfcase value="findDeaccessions">
		<cfset pageTitle = "Search Deaccessions">
		<cfif isdefined("execute")>
			<cfset execute="deaccession">
		</cfif>
	</cfcase>
	<cfcase value="findBorrows">
		<cfset pageTitle = "Search borrows">
		<cfif isdefined("execute")>
			<cfset execute="borrow">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Search Transactions">
		<cfif isdefined("execute")>
			<cfset execute="all">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<!--
Transactions.cfm

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfset pageHasTabs="true">
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(transaction_id) as cnt FROM trans
</cfquery>
<cfquery name="ctSpecificType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select distinct specific_type from mczbase.transaction_view order by specific_type
</cfquery>
<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select count(transaction_id), specific_type, transaction_type 
	from mczbase.transaction_view 
	group by specific_type, transaction_type
	order by specific_type
</cfquery>
<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select distinct status from mczbase.transaction_view order by status
</cfquery>
<cfquery name="ctLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select loan_type from ctloan_type order by loan_type
</cfquery>
<cfquery name="ctLoanStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select loan_status from ctloan_status order by loan_status
</cfquery>
<cfquery name="ctAccnType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select accn_type from ctaccn_type order by accn_type
</cfquery>
<cfquery name="ctAccnStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select accn_status from ctaccn_status order by accn_status
</cfquery>
<cfquery name="ctDeaccType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select deacc_type from ctdeacc_type order by deacc_type
</cfquery>
<cfquery name="ctDeaccStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select deacc_status from ctdeacc_status order by deacc_status
</cfquery>
<cfquery name="ctBorrowStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select borrow_status from ctborrow_status order by borrow_status
</cfquery>
<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfquery name="ctpermit_type_trans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctpermit_type.permit_type
	FROM ctpermit_type
			left join permit on ctpermit_type.permit_type = permit.permit_type
			left join permit_trans on permit.permit_id = permit_trans.permit_id
			left join permit_shipment on permit.permit_id = permit_shipment.permit_id
			left join shipment on permit_shipment.shipment_id = shipment.shipment_id
			left join trans on (
				shipment.transaction_id = trans.transaction_id
				OR
				permit_trans.transaction_id = trans.transaction_id
			)
	group by ctpermit_type.permit_type
	order by ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type_trans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	FROM ctspecific_permit_type 
		left join permit on ctspecific_permit_type.specific_type = permit.specific_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	group by ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	order by ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctpermit_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select count(*) as ct, ctpermit_type.permit_type 
	from ctpermit_type left join permit on ctpermit_type.permit_type = permit.permit_type
	group by ctpermit_type.permit_type
	order by ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select count(*) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type 
	from ctspecific_permit_type left join permit on ctspecific_permit_type.specific_type = permit.specific_type
	group by ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	order by ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctpermit_type_accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctpermit_type.permit_type
	FROM ctpermit_type
		left join permit on ctpermit_type.permit_type = permit.permit_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE 
		trans.transaction_type = 'accn'
	GROUP BY ctpermit_type.permit_type
	ORDER BY ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type_accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	FROM ctspecific_permit_type 
		left join permit on ctspecific_permit_type.specific_type = permit.specific_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE
		trans.transaction_type = 'accn'
	GROUP BY ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	ORDER BY ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctpermit_type_loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctpermit_type.permit_type
	FROM ctpermit_type
		left join permit on ctpermit_type.permit_type = permit.permit_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE 
		trans.transaction_type = 'loan'
	GROUP BY ctpermit_type.permit_type
	ORDER BY ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type_loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	FROM ctspecific_permit_type 
		left join permit on ctspecific_permit_type.specific_type = permit.specific_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE
		trans.transaction_type = 'loan'
	GROUP BY ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	ORDER BY ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctpermit_type_deaccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctpermit_type.permit_type
	FROM ctpermit_type
		left join permit on ctpermit_type.permit_type = permit.permit_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE 
		trans.transaction_type = 'deaccession'
	GROUP BY ctpermit_type.permit_type
	ORDER BY ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type_deaccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	FROM ctspecific_permit_type 
		left join permit on ctspecific_permit_type.specific_type = permit.specific_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE
		trans.transaction_type = 'deaccession'
	GROUP BY ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	ORDER BY ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctpermit_type_borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctpermit_type.permit_type
	FROM ctpermit_type
		left join permit on ctpermit_type.permit_type = permit.permit_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE 
		trans.transaction_type = 'borrow'
	GROUP BY ctpermit_type.permit_type
	ORDER BY ctpermit_type.permit_type
</cfquery>
<cfquery name="ctspecific_permit_type_borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct trans.transaction_id) as ct, ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	FROM ctspecific_permit_type 
		left join permit on ctspecific_permit_type.specific_type = permit.specific_type
		left join permit_trans on permit.permit_id = permit_trans.permit_id
		left join permit_shipment on permit.permit_id = permit_shipment.permit_id
		left join shipment on permit_shipment.shipment_id = shipment.shipment_id
		left join trans on (
			shipment.transaction_id = trans.transaction_id
			OR
			permit_trans.transaction_id = trans.transaction_id
		)
	WHERE
		trans.transaction_type = 'borrow'
	GROUP BY ctspecific_permit_type.permit_type, ctspecific_permit_type.specific_type
	ORDER BY ctspecific_permit_type.specific_type
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select * from collection order by collection
</cfquery>
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(*) as cnt, ct.trans_agent_role 
	FROM cttrans_agent_role ct 
		left join trans_agent on ct.trans_agent_role = trans_agent.trans_agent_role
	GROUP BY ct.trans_agent_role
	ORDER BY ct.trans_agent_role
</cfquery>
<cfset selectedCollection = ''>
<cfif isdefined("collection_id") and len(collection_id) gt 0>
	<cfquery name="lookupCollection" dbtype="query">
		select collection from ctcollection where collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
	</cfquery>
	<cfset selectedCollection = lookupCollection.collection >
</cfif>

<cfoutput> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("status")>
		<cfset status="">
	</cfif>
	<cfif not isdefined("deacc_type")>
		<cfset deacc_type="">
	</cfif>
	<cfif not isdefined("deacc_status")>
		<cfset deacc_status="">
	</cfif>
	<cfif not isdefined("deacc_method")>
		<cfset deacc_method="">
	</cfif>
	<cfif not isdefined("value")>
		<cfset value="">
	</cfif>
	<cfif not isdefined("deacc_reason")>
		<cfset deacc_reason="">
	</cfif>
	<cfif not isdefined("borrow_status")>
		<cfset borrow_status="">
	</cfif>
	<cfif not isdefined("no_of_specimens")>
		<cfset no_of_specimens="">
	</cfif>
	<cfif not isdefined("borrow_catalog_number")>
		<cfset borrow_catalog_number="">
	</cfif>
	<cfif not isdefined("borrow_sci_name")>
		<cfset borrow_sci_name="">
	</cfif>
	<cfif not isdefined("borrow_spec_prep")>
		<cfset borrow_spec_prep="">
	</cfif>
	<cfif not isdefined("borrow_type_status")>
		<cfset borrow_type_status="">
	</cfif>
	<cfif not isdefined("lenders_instructions")>
		<cfset lenders_instructions="">
	</cfif>
	<cfif not isdefined("lenders_trans_num_cde")>
		<cfset lenders_trans_num_cde="">
	</cfif>
	<cfif not isdefined("due_date")>
		<cfset due_date="">
	</cfif>
	<cfif not isdefined("to_due_date")>
		<cfset to_due_date="">
	</cfif>
	<cfif not isdefined("loan_date")>
		<cfset loan_date="">
	</cfif>
	<cfif not isdefined("to_loan_date")>
		<cfset to_loan_date="">
	</cfif>
	<cfif not isdefined("borrow_description")>
		<cfset borrow_description="">
	</cfif>
	<cfif not isdefined("lenders_invoice_returned")>
		<cfset lenders_invoice_returned="">
	</cfif>
	<cfif not isdefined("accn_status")>
		<cfset accn_status="">
	</cfif>
	<cfif not isdefined("accn_type")>
		<cfset accn_type="">
	</cfif>
	<cfif not isdefined("rec_date")>
		<cfset rec_date="">
	</cfif>
	<cfif not isdefined("to_rec_date")>
		<cfset to_rec_date="">
	</cfif>
	<cfif not isdefined("loan_status")>
		<cfset loan_status="">
	</cfif>
	<cfif not isdefined("loan_type")>
		<cfset loan_type="">
	</cfif>
	<cfif not isdefined("insurance_value")>
		<cfset insurance_value="">
	</cfif>
	<cfif not isdefined("insurance_maintained_by")>
		<cfset insurance_maintained_by="">
	</cfif>
	<cfif not isdefined("nature_of_material")>
		<cfset nature_of_material="">
	</cfif>
	<cfif not isdefined("loan_description")>
		<cfset loan_description="">
	</cfif>
	<cfif not isdefined("loan_instructions")>
		<cfset loan_instructions="">
	</cfif>
	<cfif not isdefined("trans_remarks")>
		<cfset trans_remarks="">
	</cfif>
	<cfif not isdefined("trans_agent_role_1")>
		<cfset trans_agent_role_1="">
	</cfif>
	<cfif not isdefined("agent_1")>
		<cfset agent_1="">
	</cfif>
	<cfif not isdefined("agent_1_id")>
		<cfset agent_1_id="">
	</cfif>
	<cfif not isdefined("trans_agent_role_2")>
		<cfset trans_agent_role_2="">
	</cfif>
	<cfif not isdefined("agent_2")>
		<cfset agent_2="">
	</cfif>
	<cfif not isdefined("agent_2_id")>
		<cfset agent_2_id="">
	</cfif>
	<cfif not isdefined("trans_agent_role_3")>
		<cfset trans_agent_role_3="">
	</cfif>
	<cfif not isdefined("agent_3")>
		<cfset agent_3="">
	</cfif>
	<cfif not isdefined("agent_3_id")>
		<cfset agent_3_id="">
	</cfif>
	<cfif not isdefined("trans_date")>
		<cfset trans_date="">
	</cfif>
	<cfif not isdefined("to_trans_date")>
		<cfset to_trans_date="">
	</cfif>
	<cfif not isdefined("return_due_date")>
		<cfset return_due_date="">
	</cfif>
	<cfif not isdefined("to_return_due_date")>
		<cfset to_return_due_date="">
	</cfif>
	<cfif not isdefined("closed_date")>
		<cfset closed_date="">
	</cfif>
	<cfif not isdefined("to_closed_date")>
		<cfset to_closed_date="">
	</cfif>
	<cfif not isdefined("permit_id")>
		<cfset permit_id="">
	</cfif>
	<cfif not isdefined("permit_num")>
		<cfset permit_num="">
	</cfif>
	<cfif not isdefined("permit_type")>
		<cfset permit_type="">
	</cfif>
	<cfif not isdefined("permit_specific_type")>
		<cfset permit_specific_type="">
	</cfif>
	<cfif not isdefined("specific_type")>
		<cfset specific_type="">
	</cfif>
	<cfif not isdefined("part_name_oper")>
		<cfset part_name_oper="is">
	</cfif>
	<cfif not isdefined("part_name")>
		<cfset part_name="">
	</cfif>
	<cfif not isdefined("part_disp_oper")>
		<cfset part_disp_oper="is">
	</cfif>
	<cfif not isdefined("coll_obj_disposition")>
		<cfset coll_obj_disposition="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("specimen_guid")>
		<cfset specimen_guid="">
	</cfif>
	<cfif not isdefined("parent_loan_number")>
		<cfset parent_loan_number="">
	</cfif>
	<cfif not isdefined("restriction_summary")>
		<cfset restriction_summary="">
	</cfif>
	<cfif not isdefined("benefits_summary")>
		<cfset benefits_summary="">
	</cfif>
	<cfif not isdefined("benefits_provided")>
		<cfset benefits_provided="">
	</cfif>
	<cfif not isdefined("issued_by_id")>
		<cfset issued_by_id="">
	</cfif>
	<cfif not isdefined("issued_to_id")>
		<cfset issued_to_id="">
	</cfif>
	<cfif not isdefined("permit_contact_id")>
		<cfset permit_contact_id="">
	</cfif>
	<cfif not isdefined("IssuedByAgent")>
		<cfset IssuedByAgent="">
	</cfif>
	<cfif not isdefined("IssuedToAgent")>
		<cfset IssuedToAgent="">
	</cfif>
	<cfif not isdefined("permit_contact_agent")>
		<cfset permit_contact_agent="">
	</cfif>
	<cfif not isdefined("estimated_count")>
		<cfset estimated_count="">
	</cfif>
	<cfif not isdefined("shipment_count")>
		<cfset shipment_count="">
	</cfif>
	<cfif not isdefined("foreign_shipments")>
		<cfset foreign_shipments="">
	</cfif>
	<cfif not isdefined("date_entered")>
		<cfset date_entered="">
	</cfif>
	<cfif not isdefined("to_date_entered")>
		<cfset to_date_entered="">
	</cfif>
	<cfif not isdefined("return_acknowledged_date")>
		<cfset return_acknowledged_date="">
	</cfif>
	<cfif not isdefined("to_return_acknowledged_date")>
		<cfset to_return_acknowledged_date="">
	</cfif>
	<cfif NOT isdefined("sovereign_nation")><cfset sovereign_nation=""></cfif>
	<cfif NOT isdefined("country_cde")><cfset country_cde=""></cfif>
	<cfif NOT isdefined("formatted_addr")><cfset formatted_addr=""></cfif>
	<div id="overlaycontainer" style="position: relative;">
	<main id="content">
		<!--- Search form --->
		<section class="container-fluid" role="search">
			<div class="row">
				<div class="col-12 mt-1 pb-3">
					<h1 class="h3 smallcaps mb-1 pl-1">Search Transactions <span class="count font-italic color-green mx-0"><small>(#getCount.cnt# records)</small></span></h1>
					<!--- Tab header div --->
					<div class="tabs card-header tab-card-header px-1 pb-0">
						<cfswitch expression="#action#">
							<cfcase value="findLoans">
								<cfset allTabActive = "">
								<cfset loanTabActive = "active">
								<cfset allTabShow = "hidden">
								<cfset loanTabShow = "">
								<cfset accnTabActive = "">
								<cfset accnTabShow = "hidden">
								<cfset deaccnTabActive = "">
								<cfset deaccnTabShow = "hidden">
								<cfset borrowTabActive = "">
								<cfset borrowTabShow = "hidden">
								<cfset allTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset loanTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset accnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset deaccnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset borrowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="findAccessions">
								<cfset allTabActive = "">
								<cfset loanTabActive = "">
								<cfset allTabShow = "hidden">
								<cfset loanTabShow = "hidden">
								<cfset accnTabActive = "active">
								<cfset accnTabShow = "">
								<cfset deaccnTabActive = "">
								<cfset deaccnTabShow = "hidden">
								<cfset borrowTabActive = "">
								<cfset borrowTabShow = "hidden">
								<cfset allTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset loanTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset accnTabAria = "aria-selected=""true"" tabindex=""0""">
								<cfset deaccnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset borrowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="findDeaccessions">
								<cfset allTabActive = "">
								<cfset loanTabActive = "">
								<cfset allTabShow = "hidden">
								<cfset loanTabShow = "hidden">
								<cfset accnTabActive = "">
								<cfset accnTabShow = "hidden">
								<cfset deaccnTabActive = "active">
								<cfset deaccnTabShow = "">
								<cfset borrowTabActive = "">
								<cfset borrowTabShow = "hidden">
								<cfset allTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset loanTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset accnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset deaccnTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset borrowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="findBorrows">
								<cfset allTabActive = "">
								<cfset loanTabActive = "">
								<cfset allTabShow = "hidden">
								<cfset loanTabShow = "hidden">
								<cfset accnTabActive = "">
								<cfset accnTabShow = "hidden">
								<cfset deaccnTabActive = "">
								<cfset deaccnTabShow = "hidden">
								<cfset borrowTabActive = "active">
								<cfset borrowTabShow = "">
								<cfset allTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset loanTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset accnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset deaccnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset borrowTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>
							<cfdefaultcase>
								<cfset allTabActive = "active">
								<cfset loanTabActive = "">
								<cfset allTabShow = "">
								<cfset loanTabShow = "hidden">
								<cfset accnTabActive = "">
								<cfset accnTabShow = "hidden">
								<cfset deaccnTabActive = "">
								<cfset deaccnTabShow = "hidden">
								<cfset borrowTabActive = "">
								<cfset borrowTabShow = "hidden">
								<cfset allTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset loanTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset accnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset deaccnTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset borrowTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<div class="tab-headers tabList" role="tablist" aria-label="search panel tabs">
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0  #allTabActive#" id="tab-1" tabid="1" role="tab" aria-controls="panel-1" #allTabAria#>All</button>
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0  #loanTabActive#" id="tab-2" tabid="2" role="tab" aria-controls="panel-2" #loanTabAria# >Loans</button>
							<button class="px-5 px-sm-3 px-md-4 col-12 col-md-auto mb-1 mb-md-0  #accnTabActive#" id="tab-3" tabid="3" role="tab" aria-controls="panel-3" #accnTabAria#>Accessions</button> 	
							<button class="px-5 px-sm-3 px-md-4 col-12 col-md-auto mb-1 mb-md-0  #deaccnTabActive#" id="tab-4" tabid="4" role="tab" aria-controls="panel-4" #deaccnTabAria#>Deaccessions</button>
							<button class="px-5 px-sm-3 px-md-4 col-12 col-md-auto mb-1 mb-md-0 #borrowTabActive#" id="tab-5" tabid="5" role="tab" aria-controls="panel-5" #borrowTabAria#>Borrows</button>
						</div>
						<!--- End tab header div ---> 
						<!--- Tab content div --->
						<div class="tab-content"> 
							<!--- All Transactions search tab panel --->
							<div id="panel-1" role="tabpanel" aria-labelledby="tab-1" tabindex="0" class="mx-0 #allTabActive#" #allTabShow#>
								<h2 class="h3 card-title my-0" >Search All Transactions <i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Transaction_Search')" aria-label="help link"></i></h2>
								<form id="searchForm" class="mt-2">
									<input type="hidden" name="method" value="getTransactions" class="keeponclear">
									<div class="form-row px-1 mb-2">
										<div class="col-6 col-md-3 pr-0 pl-1 mr-0">
											<label for="collection_id" class="data-entry-label">Collection Name</label>
											<select name="collection_id" size="1" class="data-entry-prepend-select pr-0" aria-label="collection">
												<option value="-1">any collection</option>
												<cfloop query="ctcollection">
													<cfif ctcollection.collection eq selectedCollection>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctcollection.collection_id#" #selected#>#ctcollection.collection#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-6 col-md-3 pl-0 pr-1 ml-0">
											<cfif not isdefined("number")>
												<cfset number="">
											</cfif>
											<label for="number" class="data-entry-label">Number</label>
											<input id="number" type="text" class="has-clear data-entry-select-input px-2" name="number" aria-label="add a transaction number" placeholder="nnn, yyyy-n-Coll, Byyyy-n-Coll, Dyyyy-n-Coll" value="#number#" title="Example of transaction number formats are nnn, yyyy-n-Collection code, Byyyy-n-Collection code, Dyyyy-n-collection code">
										</div>
										<div class="col-12 col-md-2"> 
											<!--- store a local variable as status may be CGI.status or VARIABLES.status --->
											<cfset pstatus = status>
											<label for="status" class="data-entry-label">Status</label>
											<select name="status" id="status" class="data-entry-select" title="loan status">
												<option value=""></option>
												<cfloop query="ctStatus">
													<cfif pstatus eq ctStatus.status>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctStatus.status#" #selected# >#ctStatus.status#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="shipment_count" class="data-entry-label">Shipments</label>
											<select name="shipment_count" id="shipment_count" class="data-entry-select" title="number of shipments">
												<option value=""></option>
												<cfif shipment_count IS "0"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="0" #scsel#>None</option>
												<cfif shipment_count IS "1"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1" #scsel#>One</option>
												<cfif shipment_count IS "1+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1+" #scsel#>One or more</option>
												<cfif shipment_count IS "2+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="2+" #scsel#>Two or more</option>
												<cfif shipment_count IS "3+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="3+" #scsel#>Three or more</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="foreign_shipments" class="data-entry-label" aria-label="International Shipmements">International Shipment</label>
											<select name="foreign_shipments" id="foreign_shipments" class="data-entry-select" title="transaction has international shipments">
												<option value=""></option>
												<cfif foreign_shipments IS "0"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="0" #fssel#>No</option>
												<cfif foreign_shipments IS "1+"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="1+" #fssel#>Yes</option>
											</select>
										</div>
									</div>
									<div class="bg-light border rounded pt-3 pt-md-2 mx-1 my-3 my-md-2 px-1">
										<div class="form-row px-1 mb-2">
											<div class="col-12 col-md-4">
												<div class="input-group">
													<select name="trans_agent_role_1" id="all_trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend" aria-label="agent role for first agent">
														<option value="">agent role</option>
														<cfloop query="cttrans_agent_role">
															<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
																<cfset selected="selected">
															<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
														</cfloop>
													</select>
													<input type="text" name="agent_1" id="all_agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" placeholder="agent name" >
													<input type="hidden" name="agent_1_id" id="all_agent_1_id" value="#agent_1_id#" >
												</div>
											</div>
											<div class="col-12 col-md-4">
												<div class="input-group">
													<select name="trans_agent_role_2" id="all_trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend" aria-label="agent role for second agent">
														<option value="">agent role</option>
														<cfloop query="cttrans_agent_role">
															<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
																<cfset selected="selected">
															<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
														</cfloop>
													</select>
													<input type="text" name="agent_2" id="all_agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" placeholder="agent name">
													<input type="hidden" name="agent_2_id" id="all_agent_2_id" value="#agent_2_id#" >
												</div>
											</div>
											<div class="col-12 col-md-4">
												<div class="input-group">
													<select name="trans_agent_role_3" id="all_trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend" aria-label="agent role for third agent">
														<option value="">agent role</option>
														<cfloop query="cttrans_agent_role">
															<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
																<cfset selected="selected">
															<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
														</cfloop>
													</select>
													<input type="text" name="agent_3" id="all_agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" placeholder="agent name">
													<input type="hidden" name="agent_3_id" id="all_agent_3_id" value="#agent_3_id#" >
												</div>
											</div>
										</div>
										<script>
											$(document).ready(function() {
												$(makeConstrainedAgentPicker('all_agent_1','all_agent_1_id','transaction_agent'));
												$(makeConstrainedAgentPicker('all_agent_2','all_agent_2_id','transaction_agent'));
												$(makeConstrainedAgentPicker('all_agent_3','all_agent_3_id','transaction_agent'));
											});
										</script> 
									</div>
									<div class="form-row px-1 mr-md-0">
										<div class="col-12 col-md-4 mb-2">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="trans_date">Transaction Date</label>
												<input name="trans_date" id="trans_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#trans_date#" aria-label="start of range for transaction date">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_trans_date">end of search range for transaction date</label>		
												<input type="text" name="to_trans_date" id="to_trans_date" value="#to_trans_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
											</div>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="date_entered">Entered Date</label>
												<input name="date_entered" id="date_entered" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#date_entered#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_date_entered">end of search range for date entered</label>		
												<input type="text" name="to_date_entered" id="to_date_entered" value="#to_date_entered#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
											</div>
										</div>
										<div class="col-12 col-md-2">
											<cfset ppermit_type = permit_type>
											<label for="permit_type" class="data-entry-label mb-0 pb-0">Has Document of Type</label>
											<select name="permit_type" class="data-entry-select" id="permit_type">
												<option value=""></option>
												<cfloop query="ctpermit_type_trans">
													<cfif ppermit_type eq ctpermit_type_trans.permit_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctpermit_type_trans.permit_type#" #selected# >#ctpermit_type_trans.permit_type# (#ctpermit_type_trans.ct# transactions)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2">
											<label for="permit_specific_type" class="data-entry-label mb-0 pb-0">Specific Type</label>
											<select name="permit_specific_type" class="data-entry-select" id="permit_specific_type">
												<option value=""></option>
												<cfloop query="ctspecific_permit_type_trans">
													<cfif permit_specific_type eq ctspecific_permit_type_trans.specific_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctspecific_permit_type_trans.specific_type#" #selected# >#ctspecific_permit_type_trans.specific_type# (#ctspecific_permit_type_trans.permit_type#) [#ctspecific_permit_type_trans.ct# transactions]</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="form-row mt-0 mx-0">
										<div class="col-12 col-md-4">
											<label for="nature_of_material" class="data-entry-label">Nature of Material</label>
											<input id="nature_of_material" type="text" class="has-clear data-entry-select-input px-2" name="nature_of_material" value="#nature_of_material#">
										</div>
										<div class="col-12 col-md-4">
											<label for="trans_remarks" class="data-entry-label">Internal Remarks</label>
											<input id="trans_remarks" type="text" class="has-clear data-entry-select-input px-2" name="trans_remarks" value="#trans_remarks#">
										</div>
										<div class="col-12 col-md-4">
											<label for="tr_permit_num" id="tr_permit_picklist" class="data-entry-label mb-0">Document/Permit Number:</label>
											<div class="input-group">
												<input type="hidden" name="permit_id" id="tr_permit_id" value="#permit_id#">
												<input type="text" name="permit_num" id="tr_permit_num" class="data-entry-addon-input" value="#encodeForHTML(permit_num)#">
												<div class="input-group-append" aria-label="pick a permit"> <span role="button" class="data-entry-addon" tabindex="0" onkeypress="handleAllPermitPickActionTr();" onclick="handleAllPermitPickActionTr();">Pick</span> </div>
												<script>
													function handleAllPermitPickActionTr(event) {
														openfindpermitdialog('tr_permit_num','tr_permit_id','tr_permitpickerdialog');
													}
												</script>
												<div id="tr_permitpickerdialog"></div>
											</div>
											<script>
												$(document).ready(function() {
													$(makePermitPicker('tr_permit_num','tr_permit_id'));
													$('##tr_permit_num').blur( function () {
														// prevent an invisible permit_id from being included in the search.
														if ($('##tr_permit_num').val().trim() == "") { 
														$('##tr_permit_id').val("");
														}
													});
												});
											</script>
										</div>
									</div>
									<div class="form-row mt-2 mx-4">
										<div class="col-12 px-1">
											<button class="btn-xs btn-primary px-3 mr-2" id="searchButton" type="submit" aria-label="Search all transactions">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning mr-2" aria-label="Reset transaction search form to inital values">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new transaction search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findAll';" >New Search</button>
										</div>
									</div>
								</form>
							</div>
							<!--- Loan search tab panel --->
							<div id="panel-2" role="tabpanel" aria-labelledby="tab-2" class="mx-0 #loanTabActive#" tabindex="0" #loanTabShow#>
								<h2 class="h3 card-title my-0">Find Loans <i class="fas fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Search_for_a_Loan')" aria-label="help link"></i></h2>
								<!--- Search for just loans ---->
								<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select coll_obj_disposition from ctcoll_obj_disp
								</cfquery>
								<cfquery name="cttrans_agent_role_loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select MCZBASE.count_transagent_for_role(cttrans_agent_role.trans_agent_role,'loan') cnt, cttrans_agent_role.trans_agent_role
									from cttrans_agent_role
										left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
									where trans_agent_role_allowed.transaction_type = 'Loan'
										or cttrans_agent_role.trans_agent_role = 'entered by'
									group by cttrans_agent_role.trans_agent_role
									order by cttrans_agent_role.trans_agent_role
								</cfquery>
								<script>
									jQuery(document).ready(function() {
										jQuery("##part_name").autocomplete({
											source: function (request, response) { 
												$.ajax({
													url: "/specimens/component/search.cfc",
													data: { term: request.term, method: 'getPartNameAutocompleteMeta' },
													dataType: 'json',
													success : function (data) { response(data); },
													error : function (jqXHR, textStatus, error) {
														handleFail(jqXHR,textStatus,error,"loading part names");
													}
												})
											},
											select: function (event, result) {
												$('##part_name').val(result.item.id);
											},
											minLength: 1
										});
									});
								</script>
								<cfif not isdefined("loan_number")>
									<cfset loan_number="">
								</cfif>
								<form id="loanSearchForm" class="mt-2">
									<input type="hidden" name="method" value="getLoans" class="keeponclear">
									<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
									<div class="form-row px-1 mb-2 mb-xl-2">
										<div class="col-12 col-md-4 mt-0">
											<div class="input-group">
												<div class="col-6 px-0">
													<label for="loan_collection_id" class="data-entry-label">Collection Name</label>
													<select name="collection_id" size="1" class="data-entry-prepend-select" id="loan_collection_id">
														<option value="-1">any collection</option>
														<cfloop query="ctcollection">
															<cfif ctcollection.collection eq selectedCollection>
																<cfset selected="selected">
																<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#collection_id#" #selected#>#collection#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-6 px-0">
													<label for="loan_number" class="data-entry-label mb-0">Number</label>
													<input type="text" name="loan_number" id="loan_number" class="data-entry-select-input" value="#loan_number#" placeholder="yyyy-n-Coll">
												</div>
											</div>
										</div>
										<div class="col-12 col-md-2">
											<cfset ploan_type = loan_type>
											<label for="loan_type" class="data-entry-label mb-0">Type</label>
											<select name="loan_type" id="loan_type" class="data-entry-select">
												<option value=""></option>
												<cfloop query="ctLoanType">
													<cfif ploan_type eq ctLoanType.loan_type>
														<cfset selected="selected">
														<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctLoanType.loan_type#" #selected#>#ctLoanType.loan_type#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2">
											<cfset ploan_status = loan_status>
											<label for="loan_status" class="data-entry-label mb-0">Status</label>
											<select name="loan_status" id="loan_status" class="data-entry-select" >
												<option value=""></option>
												<cfloop query="ctLoanStatus">
													<cfif ploan_status eq ctLoanStatus.loan_status>
														<cfset selected="selected">
														<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctLoanStatus.loan_status#" #selected#>#ctLoanStatus.loan_status#</option>
												</cfloop>
												<option value="not closed">not closed</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="shipment_count" class="data-entry-label">Shipments</label>
											<select name="shipment_count" id="shipment_count" class="data-entry-select" title="number of shipments">
												<option value=""></option>
												<cfif shipment_count IS "0"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="0" #scsel#>None</option>
												<cfif shipment_count IS "1"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1" #scsel#>One</option>
												<cfif shipment_count IS "1+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1+" #scsel#>One or more</option>
												<cfif shipment_count IS "2+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="2+" #scsel#>Two or more</option>
												<cfif shipment_count IS "3+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="3+" #scsel#>Three or more</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="foreign_shipments" class="data-entry-label" aria-label="International Shipmements">International Shipment</label>
											<select name="foreign_shipments" id="foreign_shipments" class="data-entry-select" title="transaction has international shipments">
												<option value=""></option>
												<cfif foreign_shipments IS "0"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="0" #fssel#>No</option>
												<cfif foreign_shipments IS "1+"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="1+" #fssel#>Yes</option>
											</select>
										</div>
									</div>
									<div class="bg-light border rounded p-1 mx-1 my-2">
										<div class="form-row px-1 mb-2 mx-0 my-2">
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_1" id="loan_trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_loan">
														<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_1" id="loan_agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" placeholder="agent name" >
												<input type="hidden" name="agent_1_id" id="loan_agent_1_id" value="#agent_1_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_2" id="loan_trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_loan">
														<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_2" id="loan_agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" placeholder="agent name">
												<input type="hidden" name="agent_2_id" id="loan_agent_2_id" value="#agent_2_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_3" id="loan_trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_loan">
														<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_3" id="loan_agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" placeholder="agent name">
												<input type="hidden" name="agent_3_id" id="loan_agent_3_id" value="#agent_3_id#" >
											</div>
										</div>
										<script>
									$(document).ready(function() {
										$(makeConstrainedAgentPicker('loan_agent_1','loan_agent_1_id','transaction_agent'));
										$(makeConstrainedAgentPicker('loan_agent_2','loan_agent_2_id','transaction_agent'));
										$(makeConstrainedAgentPicker('loan_agent_3','loan_agent_3_id','transaction_agent'));
									});
									</script> 
									</div>
									</div>
									<div class="form-row px-1 mt-1 mb-md-2 my-xl-2">
										<div class="col-12 col-md-6 col-lg-3">
											<div class="date form-row bg-light border pb-2 px-xl-1 mb-2 mb-md-0 pt-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="trans_date">Loan Date</label>
												<input name="trans_date" id="trans_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#trans_date#" aria-label="start of range for loan date">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_trans_date">end of search range for loan date</label>
												<input type='text' name='to_trans_date' id="to_trans_date" value="#to_trans_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-12 col-md-6 col-lg-3">
											<div class="date form-row bg-light border pb-2 px-xl-1 mb-2 mb-md-0 pt-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="return_due_date">Due Date</label>
												<input name="return_due_date" id="return_due_date" type="text" placeholder="start yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-5" value="#return_due_date#" aria-label="start of range for due date">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to">end of range for due date</label>
												<input type='text' name='to_return_due_date' id="to_return_due_date" value="#to_return_due_date#" placeholder="end yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-4" aria-label="due date search range to">
											</div>
										</div>
										<div class="col-12 col-md-6 col-lg-3">
											<div class="date form-row border bg-light pb-2 px-xl-1 mb-2 mb-md-0 pt-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="closed_date">Closed Date</label>
												<input name="closed_date" id="closed_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#closed_date#" aria-label="start of range for closed date">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_closed_date">end of range for closed date </label>
												<input type='text' name='to_closed_date' id="to_closed_date" value="#to_closed_date#" placeholder="end yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-4">
											</div>
										</div>
										<div class="col-12 col-md-6 col-lg-3">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="date_entered">Entered Date</label>
												<input name="date_entered" id="date_entered" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#date_entered#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_date_entered">end of search range for date entered</label>		
												<input type="text" name="to_date_entered" id="to_date_entered" value="#to_date_entered#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
											</div>
										</div>
									</div>
									<script>
										$(document).ready(function() {
											$(makePermitPicker('loan_permit_num','loan_permit_id'));
										});
									</script>
									<div class="form-row px-1">
										<div class="col-md-6">
											<div class="border bg-light rounded pt-2 pb-3 py-md-3 px-md-4 mb-2 px-3">
												<div class="form-row">
													<div class="col-12">
														<label for="permit_num" id="loan_permit_picklist" class="data-entry-label mb-0 pt-0 mt-0">Permit Number</label>
														<div class="input-group">
															<input type="hidden" name="permit_id" id="loan_permit_id" value="#permit_id#">
															<input type="text" name="permit_num" id="loan_permit_num" class="data-entry-addon-input" aria-described-by="permitNumberLabel" value="#permit_num#" aria-label="add permit number">
															<div class="input-group-append"> <span role="button" class="data-entry-addon" tabindex="0" aria-label="pick a permit to add as a search parameter" onkeypress="handleLoanPermitPickAction();" onclick="handleLoanPermitPickAction();" aria-label="loan permit picklist">Pick</span> </div>
															<script>
																function handleLoanPermitPickAction(event) {
																	openfindpermitdialog('loan_permit_num','loan_permit_id','loanpermitpickerdialog');
																}
															</script>
															<div id="loanpermitpickerdialog"></div>
														</div>
													</div>
													<div class="col-12 col-md-6 mt-1">
														<cfset ppermit_type = permit_type>
														<label for="loan_permit_type" class="data-entry-label mb-0 pb-0">Has Document of Type</label>
														<select name="permit_type" class="data-entry-select" id="loan_permit_type">
															<option value=""></option>
															<cfloop query="ctpermit_type_loan">
																<cfif ppermit_type eq ctpermit_type_loan.permit_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctpermit_type_loan.permit_type#" #selected# >#ctpermit_type_loan.permit_type# (#ctpermit_type_loan.ct# loans)</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-6 mt-1">
														<label for="loan_permit_specific_type" class="data-entry-label mb-0 pb-0">Specific Type</label>
														<select name="permit_specific_type" class="data-entry-select" id="loan_permit_specific_type">
															<option value=""></option>
															<cfloop query="ctspecific_permit_type_loan">
																<cfif permit_specific_type eq ctspecific_permit_type_loan.specific_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctspecific_permit_type_loan.specific_type#" #selected# >#ctspecific_permit_type_loan.specific_type# (#ctspecific_permit_type_loan.permit_type#) [#ctspecific_permit_type_loan.ct# loans)</option>
															</cfloop>
														</select>
													</div>
												</div>
											</div>
											<div class="border bg-light rounded px-2 mb-2 mb-md-0 py-3 py-lg-2">
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<div class="col-3 px-0">
														<label for="part_name_oper" class="data-entry-label mb-0">Part</label>
														<cfif part_name_oper IS "is">
															<cfset isselect = "selected">
															<cfset containsselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset containsselect = "selected">
														</cfif>
														<select id="part_name_oper" name="part_name_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="contains" #containsselect#>contains</option>
														</select>
													</div>
													<div class="col-9 px-0">
														<label for="part_name" class="data-entry-label mb-0">Part Name</label>
														<input type="text" id="part_name" name="part_name" class="px-0 data-entry-select-input ui-autocomplete-input" value="#part_name#" autocomplete="off">
													</div>
												</div>
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<div class="col-3 px-0">
														<label for="part_disp_oper" class="data-entry-label mb-0">Disp.</label>
														<cfif part_disp_oper IS "is">
															<cfset isselect = "selected">
															<cfset notselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset notselect = "selected">
														</cfif>
														<select id="part_disp_oper" name="part_disp_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="isnot" #notselect#>is not</option>
														</select>
													</div>
													<div class="col-9 px-0">
														<cfset coll_obj_disposition_array = ListToArray(coll_obj_disposition)>
														<label for="coll_obj_disposition" class="data-entry-label mb-0">Part Disposition</label>
														<div name="coll_obj_disposition" id="coll_obj_disposition" class="w-100"></div>
														<script>
															function setDispositionValues() {
																$('##coll_obj_disposition').jqxComboBox('clearSelection');
																<cfloop query="ctCollObjDisp">
																	<cfif ArrayContains(coll_obj_disposition_array, ctCollObjDisp.coll_obj_disposition)>
																		$("##coll_obj_disposition").jqxComboBox("selectItem","#ctCollObjDisp.coll_obj_disposition#");
																	</cfif>
																</cfloop>
															};
															$(document).ready(function () {
																var dispositionsource = [
																	""
																	<cfloop query="ctCollObjDisp">
																		,"#ctCollObjDisp.coll_obj_disposition#"
																	</cfloop>
																];
																$("##coll_obj_disposition").jqxComboBox({ source: dispositionsource, multiSelect: true, height: '23px', width: '100%' });
																setDispositionValues();
															});
														</script> 
													</div>
												</div>
												<div class="form-row mx-0 mb-0 px-2 px-sm-3">
													<input type="hidden" id="collection_object_id" name="collection_object_id" value="#collection_object_id#">
													<!--- if we were given part collection object id values, look up the catalog numbers for them and display for the user --->
													<!--- used in call from specimen details to find loans from parts. --->
													<cfif isDefined("collection_object_id") AND len(collection_object_id) GT 0>
														<cfquery name="guidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidLookup">
															select distinct guid 
															from #session.flatTableName# flat 
																left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
															where 
																specimen_part.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
														</cfquery>
														<cfloop query="guidLookup">
															<cfif not listContains(specimen_guid,guidLookup.guid)>
																<cfif len(specimen_guid) EQ 0>
																	<cfset specimen_guid = guidLookup.guid>
																<cfelse>
																	<cfset specimen_guid = specimen_guid & "," & guidSearch.guid>
																</cfif>
															</cfif>
														</cfloop>
													</cfif>
													<!--- display the provided guids, backing query will use both these and the hidden collection_object_id for the lookup. --->
													<!--- if user changes the value of the guid list, clear the hidden collection object id field. --->
													<div class="coll-12 col-md-7 px-0 mt-1 mb-2">
														<label for="specimen_guid" class="data-entry-label mb- pb-0">Cataloged Item in Loan</label>
														<input type="text" name="specimen_guid" 
															class="data-entry-input" value="#specimen_guid#" id="specimen_guid" placeholder="MCZ:Coll:nnnnn"
															onchange="$('##collection_object_id').val('');">
													</div>
													<div class="col-12 col-md-5 mt-1">
														<label class="data-entry-label" for="sovereign_nation">
															Sovereign Nation (of specimens)
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##sovereign_nation').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" name="sovereign_nation" id="sovereign_nation" class="data-entry-input" value="#encodeforHTML(sovereign_nation)#">
														<script>
															$(document).ready(function() {
																makeSovereignNationSearchAutocomplete("sovereign_nation");
															});
														</script>
													</div>
												</div>
											</div>
										</div>

										<div class="col-md-6">
											<div class="form-row px-1 mx-0 border bg-light rounded px-2 px-sm-3 mb-0 py-3">
												<div class="col-md-12">
													<label for="nature_of_material" class="data-entry-label mb-0 pb-0">Nature of Material</label>
													<input type="text" name="nature_of_material" class="data-entry-input" value="#encodeForHtml(nature_of_material)#" id="nature_of_material">
												</div>
												<div class="col-md-12 mt-1">
													<label for="loan_description" class="data-entry-label mb-0 pb-0">Description </label>
													<input type="text" name="loan_description" class="data-entry-input" value="#encodeForHtml(loan_description)#" id="loan_description">
												</div>
												<div class="col-md-12 mt-1">
													<label for="loan_instructions" class="data-entry-label mb-0 pb-0">Instructions</label>
													<input type="text" name="loan_instructions" class="data-entry-input" value="#encodeForHtml(loan_instructions)#" id="loan_instructions">
												</div>
												<div class="coll-12 col-md-8 mt-1">
													<label for="loan_trans_remarks" class="data-entry-label mb-0 pb-0">Internal Remarks </label>
													<input type="text" name="trans_remarks" class="data-entry-input" value="#encodeForHtml(trans_remarks)#" id="loan_trans_remarks">
												</div>
												<div class="col-12 col-md-4 mt-1">
													<label class="data-entry-label" for="country_cde">Shipped To Country</label>
													<input type="text" name="country_cde" id="country_cde" class="data-entry-input" value="#encodeforHTML(country_cde)#" >
													<script>
														$(document).ready(function() {
															makeAddrCountryCdeAutocomplete("country_cde");
														});
													</script>
												</div>
												<div class="coll-12 col-md-8 mt-1">
													<label for="parent_loan_number" class="data-entry-label mb-0 pb-0">Master Exhibition Loan Number <span class="small">(find exhibition-subloans)</span> </label>
													<input type="text" name="parent_loan_number" class="data-entry-input" value="#parent_loan_number#" id="parent_loan_number" placeholder="yyyy-n-MCZ" >
												</div>
												<div class="col-12 col-md-4 mt-1">
													<label class="data-entry-label" for="formatted_addr">Shipped To Address</label>
													<input type="text" name="formatted_addr" id="formatted_addr" class="data-entry-input" value="#encodeforHTML(formatted_addr)#" >
												</div>
												<div class="col-md-5 mt-1">
													<label for="loan_insurance_value" class="data-entry-label mb-0 pb-0">Insurance Value <span class="small">(NULL,NOT NULL)</span> </label>
													<input type="text" name="insurance_value" class="data-entry-input" value="#insurance_value#" id="loan_insurance_value">
												</div>
												<div class="col-md-7 mt-1">
													<label for="loan_insurance_maintained_by" class="data-entry-label mb-0 pb-0">Insurance Maintained By <span class="small">(NULL, NOT NULL)</span></label>
													<input type="text" name="insurance_maintained_by" class="data-entry-input" maintained_by="#insurance_maintained_by#" id="loan_insurance_maintained_by">
												</div>
											</div>
										</div>
										<div class="col-12">
											<div class="form-row px-1 mx-0 border bg-light rounded px-2 px-sm-3 mb-0 py-3">
											</div>
										</div>
									</div>	
									<div class="form-row mt-1 mx-4">
										<div class="col-12 text-left">
											<button class="btn-xs btn-primary px-2 mr-2" id="loanSearchButton" type="submit" aria-label="Search loans">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning mr-2" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new loan search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findLoans';" >New Search</button>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new loan" href="/transactions/Loan.cfm?action=newLoan">Create New Loan</a>
										</div>
									</div>
								</form>
							</div><!---tab-pane loan search---> 

							<!--- Accession search tab panel --->
							<div id="panel-3" role="tabpanel" aria-labelledby="tab-3" class="mx-0 #accnTabActive#" tabindex="0" #accnTabShow#>
								<h2 class="h3 card-title my-0">Find Accessions <i class="fas fa-info-circle" onClick="getMCZDocs('Find_Accession')" aria-label="help link"></i></h2>
								<!--- Search for just accessions ---->
								<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select coll_obj_disposition from ctcoll_obj_disp
								</cfquery>
								<cfquery name="cttrans_agent_role_accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select MCZBASE.count_transagent_for_role(cttrans_agent_role.trans_agent_role,'accn') cnt, cttrans_agent_role.trans_agent_role
									from cttrans_agent_role
										left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
									where trans_agent_role_allowed.transaction_type = 'Accn'
										or cttrans_agent_role.trans_agent_role = 'entered by'
									group by cttrans_agent_role.trans_agent_role
									order by cttrans_agent_role.trans_agent_role
								</cfquery>
								<script>
									jQuery(document).ready(function() {
										jQuery("##accn_part_name").autocomplete({
											source: function (request, response) { 
												$.ajax({
													url: "/specimens/component/search.cfc",
													data: { term: request.term, method: 'getPartNameAutocompleteMeta' },
													dataType: 'json',
													success : function (data) { response(data); },
													error : function (jqXHR, textStatus, error) {
														handleFail(jqXHR,textStatus,error,"loading part names");
													}
												})
											},
											select: function (event, result) {
												$('##accn_part_name').val(result.item.id);
											},
											minLength: 1
										});
									});
								</script>
								<cfif not isdefined("accn_number")>
									<cfset accn_number="">
								</cfif>
								<form id="accnSearchForm" class="mt-2">
									<input type="hidden" name="method" value="getAccessions" class="keeponclear">
									<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
									<div class="form-row px-1 mb-2 mb-xl-2">
										<div class="col-12 col-md-4 mt-0">
											<div class="input-group">
												<div class="col-6 px-0">
													<label for="accn_collection_id" class="data-entry-label">Collection Name</label>
													<select name="collection_id" size="1" class="data-entry-prepend-select" id="accn_collection_id">
														<option value="-1">any collection</option>
														<cfloop query="ctcollection">
															<cfif ctcollection.collection eq selectedCollection>
																<cfset selected="selected">
																<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#collection_id#" #selected#>#collection#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-6 px-0">
													<label for="accn_number" class="data-entry-label mb-0">Number 
														<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##accn_number').val('='+$('##accn_number').val());" > (=) <span class="sr-only">prefix with equals sign for exact match search</span></a>
</label>
													<input type="text" name="accn_number" id="accn_number" class="data-entry-select-input" value="#accn_number#" placeholder="99999999">
												</div>
											</div>
										</div>
										<div class="col-12 col-md-2">
											<cfset paccn_type = accn_type>
											<label for="accn_type" class="data-entry-label mb-0">Type</label>
											<select name="accn_type" id="accn_type" class="data-entry-select">
												<option value=""></option>
												<cfloop query="ctAccnType">
													<cfif paccn_type eq ctAccnType.accn_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctAccnType.accn_type#" #selected#>#ctAccnType.accn_type#</option>
												</cfloop>
												<cfloop query="ctAccnType">
													<cfif paccn_type eq '!' & ctAccnType.accn_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="!#ctAccnType.accn_type#" #selected#>not #ctAccnType.accn_type#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2">
											<cfset paccn_status = accn_status>
											<label for="accn_status" class="data-entry-label mb-0">Status</label>
											<select name="accn_status" id="accn_status" class="data-entry-select" >
												<option value=""></option>
												<cfloop query="ctAccnStatus">
													<cfif paccn_status eq ctAccnStatus.accn_status>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctAccnStatus.accn_status#" #selected#>#ctAccnStatus.accn_status#</option>
												</cfloop>
												<cfif ctAccnStatus.recordcount GT 2>
													<!--- not needed unless we add more than two allowed accession status values --->
													<cfloop query="ctAccnStatus">
														<cfif paccn_status eq '!' & ctAccnStatus.accn_status>
															<cfset selected="selected">
														<cfelse>
															<cfset selected="">
														</cfif>
														<option value="!#ctAccnStatus.accn_status#" #selected#>not #ctAccnStatus.accn_status#</option>
													</cfloop>
												</cfif>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="shipment_count" class="data-entry-label">Shipments</label>
											<select name="shipment_count" id="shipment_count" class="data-entry-select" title="number of shipments">
												<option value=""></option>
												<cfif shipment_count IS "0"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="0" #scsel#>None</option>
												<cfif shipment_count IS "1"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1" #scsel#>One</option>
												<cfif shipment_count IS "1+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1+" #scsel#>One or more</option>
												<cfif shipment_count IS "2+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="2+" #scsel#>Two or more</option>
												<cfif shipment_count IS "3+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="3+" #scsel#>Three or more</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="foreign_shipments" class="data-entry-label" aria-label="International Shipmements">International Shipment</label>
											<select name="foreign_shipments" id="foreign_shipments" class="data-entry-select" title="transaction has international shipments">
												<option value=""></option>
												<cfif foreign_shipments IS "0"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="0" #fssel#>No</option>
												<cfif foreign_shipments IS "1+"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="1+" #fssel#>Yes</option>
											</select>
										</div>
									</div>
									<div class="bg-light border rounded p-1 mx-1 my-2">
										<div class="form-row px-1 mb-2 mx-0 my-2">
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_1" id="accn_trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_accn">
														<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_1" id="accn_agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" placeholder="agent name" >
												<input type="hidden" name="agent_1_id" id="accn_agent_1_id" value="#agent_1_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_2" id="accn_trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_accn">
														<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_2" id="accn_agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" placeholder="agent name">
												<input type="hidden" name="agent_2_id" id="accn_agent_2_id" value="#agent_2_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_3" id="accn_trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_accn">
														<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_3" id="accn_agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" placeholder="agent name">
												<input type="hidden" name="agent_3_id" id="accn_agent_3_id" value="#agent_3_id#" >
											</div>
										</div>
										<script>
									$(document).ready(function() {
										$(makeConstrainedAgentPicker('accn_agent_1','accn_agent_1_id','transaction_agent'));
										$(makeConstrainedAgentPicker('accn_agent_2','accn_agent_2_id','transaction_agent'));
										$(makeConstrainedAgentPicker('accn_agent_3','accn_agent_3_id','transaction_agent'));
									});
									</script> 
									</div>
									</div>
									<div class="form-row px-1">
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="accn_trans_date">Accession Date</label>
												<input name="trans_date" id="accn_trans_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#trans_date#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="accn_to_trans_date">end of search range for accession date</label>
												<input type="text" name="to_trans_date" id="accn_to_trans_date" value="#to_trans_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 pt-1 px-0 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="accn_rec_date">Received Date</label>
												<input name="rec_date" id="accn_rec_date" type="text" placeholder="start yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-5" value="#rec_date#" aria-label="start of range for date received">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="accn_to_rec_date">end of range for date received</label>
												<input type="text" name="to_rec_date" id="accn_to_rec_date" value="#to_rec_date#" placeholder="end yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-4">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="accn_date_entered">Entered Date</label>
												<input name="date_entered" id="accn_date_entered" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#date_entered#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="accn_to_date_entered">end of search range for date entered</label>
												<input type="text" name="to_date_entered" id="accn_to_date_entered" value="#to_date_entered#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
									</div>

									<div class="form-row px-1 mt-2">
										<div class="col-md-6">
											<div class="form-row border bg-light rounded py-3 mb-2 px-3 px-md-4">
												<div class="col-12 col-md-12 px-0">
													<label class="data-entry-label px-0 mt-1" for="estimated_count">Estimated Count <span class="small">(accepts: 10, &lt;10, &gt;10, NULL, NOT NULL)</span></label>
													<input type="text" name="estimated_count" class="data-entry-input" value="#estimated_count#" id="estimated_count" placeholder="&gt;100">
												</div>
												<div class="col-12 col-md-6 px-0">
													<label for="a_nature_of_material" class="data-entry-label mb-0 pb-0">Nature of Material</label>
													<input type="text" name="nature_of_material" class="data-entry-input" value="#nature_of_material#" id="a_nature_of_material">
												</div>
												<div class="col-12 col-md-6 pl-1 pr-0">
													<label for="accn_trans_remarks" class="data-entry-label mb-0 pb-0">Internal Remarks</label>
													<input type="text" name="trans_remarks" class="data-entry-input" value="#trans_remarks#" id="accn_trans_remarks">
												</div>
											</div>
											<div class="border bg-light rounded px-2 mb-2 py-3">
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<div class="col-3 px-0">
														<label for="accn_part_name_oper" class="data-entry-label mb-0">Part</label>
														<cfif part_name_oper IS "is">
															<cfset isselect = "selected">
															<cfset containsselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset containsselect = "selected">
														</cfif>
														<select id="accn_part_name_oper" name="part_name_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="contains" #containsselect#>contains</option>
														</select>
													</div>
													<div class="col-9 px-0">
														<label for="accn_part_name" class="data-entry-label mb-0">Part Name</label>
														<input type="text" id="accn_part_name" name="part_name" class="px-0 data-entry-select-input ui-autocomplete-input" value="#part_name#" autocomplete="off">
													</div>
												</div>
												<div class="form-row mx-0 px-2 px-sm-3">
													<div class="col-3 px-0">
														<label for="accn_part_disp_oper" class="data-entry-label mb-0">Disp.</label>
														<cfif part_disp_oper IS "is">
															<cfset isselect = "selected">
															<cfset notselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset notselect = "selected">
														</cfif>
														<select id="accn_part_disp_oper" name="part_disp_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="isnot" #notselect#>is not</option>
														</select>
													</div>
													<div class="col-9 px-0">
														<cfset coll_obj_disposition_array = ListToArray(coll_obj_disposition)>
														<label for="accn_coll_obj_disposition" class="data-entry-label mb-0">Part Disposition</label>
														<div name="coll_obj_disposition" id="accn_coll_obj_disposition" class="w-100"></div>
														<script>
															function setAccnDispositionValues() {
																$('##coll_obj_disposition').jqxComboBox('clearSelection');
																<cfloop query="ctCollObjDisp">
																	<cfif ArrayContains(coll_obj_disposition_array, ctCollObjDisp.coll_obj_disposition)>
																		$("##accn_coll_obj_disposition").jqxComboBox("selectItem","#ctCollObjDisp.coll_obj_disposition#");
																	</cfif>
																</cfloop>
															};
															$(document).ready(function () {
																var dispositionsource = [
																	""
																	<cfloop query="ctCollObjDisp">
																		,"#ctCollObjDisp.coll_obj_disposition#"
																	</cfloop>
																];
																$("##accn_coll_obj_disposition").jqxComboBox({ source: dispositionsource, multiSelect: true, height: '23px', width: '100%' });
																setAccnDispositionValues();
															});
														</script> 
													</div>
												</div>
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<input type="hidden" id="accn_collection_object_id" name="collection_object_id" value="#collection_object_id#">
													<!--- if we were given part collection object id values, look up the catalog numbers for them and display for the user --->
													<!--- used in call from specimen details to find loans from parts. --->
													<cfif isDefined("collection_object_id") AND len(collection_object_id) GT 0>
														<cfquery name="guidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidLookup">
															select distinct guid 
															from #session.flatTableName# flat 
																left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
															where 
																specimen_part.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
														</cfquery>
														<cfloop query="guidLookup">
															<cfif not listContains(specimen_guid,guidLookup.guid)>
																<cfif len(specimen_guid) EQ 0>
																	<cfset specimen_guid = guidLookup.guid>
																<cfelse>
																	<cfset specimen_guid = specimen_guid & "," & guidSearch.guid>
																</cfif>
															</cfif>
														</cfloop>
													</cfif>
													<!--- display the provided guids, backing query will use both these and the hidden collection_object_id for the lookup. --->
													<!--- if user changes the value of the guid list, clear the hidden collection object id field. --->
													<div class="col-md-12 px-0 pb-0 mt-2">
														<label for="accn_specimen_guid" class="data-entry-label mb-0 pb-0">Cataloged Item in Accession</label>
														<input type="text" name="specimen_guid" 
															class="data-entry-input" value="#specimen_guid#" id="accn_specimen_guid" placeholder="MCZ:Coll:nnnnn"
															onchange="$('##collection_object_id').val('');">
													</div>
													<script>
													</script>
												</div>
											</div>
										</div>

										<div class="col-md-6">
											<div class="border bg-light rounded px-0 pt-1 pb-3 mb-0">
												<h3 class="h5 px-3 my-2">Permissions &amp; Rights</h3>
												<div class="col-md-12">
													<label for="a_permit_num" id="a_permit_picklist" class="data-entry-label mb-0 pt-0 mt-0">Document/Permit Number:</label>
													<div class="input-group">
														<input type="hidden" name="permit_id" id="a_permit_id" value="#permit_id#">
														<input type="text" name="permit_num" id="a_permit_num" class="data-entry-addon-input" value="#permit_num#">
														<div class="input-group-append"> <span role="button" class="data-entry-addon" tabindex="0" aria-label="pick a permit" onkeypress="handleAPermitPickAction();" onclick="handleAPermitPickAction();" aria-labelledby="a_permit_picklist">Pick</span> </div>
														<script>
															function handleAPermitPickAction(event) {
																openfindpermitdialog('a_permit_num','a_permit_id','a_permitpickerdialog');
															}
														</script>
														<div id="a_permitpickerdialog"></div>
													</div>
													<script>
														$(document).ready(function() {
															$(makePermitPicker('a_permit_num','a_permit_id'));
															$('##a_permit_num').blur( function () {
																// prevent an invisible permit_id from being included in the search.
																if ($('##a_permit_num').val().trim() == "") { 
																	$('##a_permit_id').val("");
																}
															});
														});
													</script>
												</div>
												<div class="form-row px-0 mx-0 mt-1">
												<div class="col-12 col-md-4 col-xl-4 px-3 pr-md-1 pl-md-3 pl-xl-3 pr-xl-2">
													<label for="a_issued_by_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued By</label>
													<input type="text" name="IssuedByAgent" id="a_issued_by_agent" class="data-entry-input" value="#IssuedByAgent#" placeholder="issued by agent name" >
													<input type="hidden" name="issued_by_id" id="a_issued_by_agent_id" value="#issued_by_id#" >
												</div>
												<div class="col-12 col-md-4 col-xl-4 px-3 px-md-1 px-xl-2">
													<label for="a_issued_to_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued To</label>
													<input type="text" name="IssuedToAgent" id="a_issued_to_agent" class="data-entry-input" value="#IssuedToAgent#" placeholder="issued to agent name" >
													<input type="hidden" name="issued_to_id" id="a_issued_to_agent_id" value="#issued_to_id#" >
												</div>
												<div class="col-12 col-md-4 col-xl-4 ml-0 ml-xl-0 px-3 pl-md-1 pr-md-3 pl-xl-2 pr-xl-3">
													<label for="a_permit_contact_agent" class="data-entry-label mb-0 pt-0 mt-0">Contact Agent</label>
													<input type="text" name="permit_contact_agent" id="a_permit_contact_agent" class="data-entry-input" value="#permit_contact_agent#" placeholder="contact agent name" >
													<input type="hidden" name="permit_contact_id" id="a_permit_contact_agent_id" value="#permit_contact_id#" >
												</div>
												</div>
											
												<script>
													$(document).ready(function() {
														$(makeConstrainedAgentPicker('a_issued_by_agent','a_issued_by_agent_id','permit_issued_by_agent'));
														$(makeConstrainedAgentPicker('a_issued_to_agent','a_issued_to_agent_id','permit_issued_to_agent'));
														$(makeConstrainedAgentPicker('a_permit_contact_agent','a_permit_contact_agent_id','permit_contact_agent'));
													});
												</script>
												<div class="col-md-12 mt-1">
													<label for="accn_restriction_summary" class="data-entry-label mb-0 pb-0">Restrictions <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="restriction_summary" class="data-entry-input" value="#restriction_summary#" id="accn_restriction_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="accn_benefits_summary" class="data-entry-label mb-0 pb-0">Benefits <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_summary" class="data-entry-input" value="#benefits_summary#" id="accn_benefits_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="accn_benefits_provided" class="data-entry-label mb-0 pb-0">Benefits Provided <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_provided" class="data-entry-input" value="#benefits_provided#" id="accn_benefits_provided">
												</div>
												<div class="form-row px-1 px-3">
													<div class="coll-12 col-md-6 mt-1">
														<cfset ppermit_type = permit_type>
														<label for="accn_permit_type" class="data-entry-label mb-0 pb-0">Has Document of Type</label>
														<select name="permit_type" class="data-entry-select" id="accn_permit_type">
															<option value=""></option>
															<cfloop query="ctpermit_type_accn">
																<cfif ppermit_type eq ctpermit_type_accn.permit_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctpermit_type_accn.permit_type#" #selected# >#ctpermit_type_accn.permit_type# (#ctpermit_type_accn.ct# accessions)</option>
															</cfloop>
															<cfloop query="ctpermit_type_accn">
																<cfif ppermit_type eq "!#ctpermit_type_accn.permit_type#" >
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="!#ctpermit_type_accn.permit_type#" #selected# >NO #ctpermit_type_accn.permit_type#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-6 mt-1">
														<label for="accn_permit_specific_type" class="data-entry-label mb-0 pb-0">Specific Type</label>
														<select name="permit_specific_type" class="data-entry-select" id="accn_permit_specific_type">
															<option value=""></option>
															<cfloop query="ctspecific_permit_type_accn">
																<cfif permit_specific_type eq ctspecific_permit_type_accn.specific_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctspecific_permit_type_accn.specific_type#" #selected# >#ctspecific_permit_type_accn.specific_type# (#ctspecific_permit_type_accn.permit_type#) [#ctspecific_permit_type_accn.ct# accessions)</option>
															</cfloop>
															<cfloop query="ctspecific_permit_type_accn">
																<cfif permit_specific_type eq "!#ctspecific_permit_type_accn.specific_type#">
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="!#ctspecific_permit_type_accn.specific_type#" #selected# >NO #ctspecific_permit_type_accn.specific_type# (#ctspecific_permit_type_accn.permit_type#)</option>
															</cfloop>
														</select>
														</select>
													</div>
												</div>
											</div>
										</div>
									</div>	
									<div class="form-row mt-2 mx-4">
										<div class="col-12 text-left">
											<button class="btn-xs btn-primary px-2 mr-2" id="accnSearchButton" type="submit" aria-label="Search Accessions">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning mr-2" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new accession search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findAccessions';" >New Search</button>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new accession" href="/transactions/Accession.cfm?action=new">Create New Accession</a>
										</div>
									</div>
								</form>
							</div><!---tab-pane accession search---> 

							<!--- Deaccession search tab panel --->
							<div id="panel-4" role="tabpanel" aria-labelledby="tab-4" class="mx-0 #deaccnTabActive#" tabindex="0" #deaccnTabShow#>
								<h2 class="h3 card-title my-0">Find Deaccessions <i class="fas fa-info-circle" onClick="getMCZDocs('Find_Accession')" aria-label="help link"></i></h2>
								<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select coll_obj_disposition from ctcoll_obj_disp
								</cfquery>
								<cfquery name="cttrans_agent_role_deacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select MCZBASE.count_transagent_for_role(cttrans_agent_role.trans_agent_role,'deaccession') cnt, cttrans_agent_role.trans_agent_role
									from cttrans_agent_role
										left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
									where trans_agent_role_allowed.transaction_type = 'Deaccn'
										or cttrans_agent_role.trans_agent_role = 'entered by'
									group by cttrans_agent_role.trans_agent_role
									order by cttrans_agent_role.trans_agent_role
								</cfquery>
								<script>
									jQuery(document).ready(function() {
										jQuery("##deacc_part_name").autocomplete({
											source: function (request, response) { 
												$.ajax({
													url: "/specimens/component/search.cfc",
													data: { term: request.term, method: 'getPartNameAutocompleteMeta' },
													dataType: 'json',
													success : function (data) { response(data); },
													error : function (jqXHR, textStatus, error) {
														handleFail(jqXHR,textStatus,error,"loading part names");
													}
												})
											},
											select: function (event, result) {
												$('##deacc_part_name').val(result.item.id);
											},
											minLength: 1
										});
									});
								</script>
								<cfif not isdefined("deacc_number")>
									<cfset deacc_number="">
								</cfif>
								<form id="deaccnSearchForm" class="mt-2">
									<input type="hidden" name="method" value="getDeaccessions" class="keeponclear">
									<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
									<div class="form-row px-1 mb-2 mb-xl-2">
										<div class="col-12 col-md-4 mt-0">
											<div class="input-group">
												<div class="col-6 px-0">
													<label for="deacc_collection_id" class="data-entry-label">Collection Name</label>
													<select name="collection_id" size="1" class="data-entry-prepend-select" id="deacc_collection_id">
														<option value="-1">any collection</option>
														<cfloop query="ctcollection">
															<cfif ctcollection.collection eq selectedCollection>
																<cfset selected="selected">
																<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#collection_id#" #selected#>#collection#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-6 px-0">
													<label for="deacc_number" class="data-entry-label mb-0">Number 
														<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##deacc_number').val('='+$('##deacc_number').val());" > (=) <span class="sr-only">prefix with equals sign for exact match search</span></a>
													</label>
													<input type="text" name="deacc_number" id="deacc_number" class="data-entry-select-input" value="#deacc_number#" placeholder="Dyyyy-n-Col">
												</div>
											</div>
										</div>
										<div class="col-12 col-md-2">
											<cfset pdeacc_type = deacc_type>
											<label for="deacc_type" class="data-entry-label mb-0">Type</label>
											<select name="deacc_type" id="deacc_type" class="data-entry-select">
												<option value=""></option>
												<cfloop query="ctDeaccType">
													<cfif pdeacc_type eq ctDeaccType.deacc_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctDeaccType.deacc_type#" #selected#>#ctDeaccType.deacc_type#</option>
												</cfloop>
												<cfloop query="ctDeaccType">
													<cfif pdeacc_type eq '!' & ctDeaccType.deacc_type>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="!#ctDeaccType.deacc_type#" #selected#>not #ctDeaccType.deacc_type#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2">
											<cfset pdeacc_status = deacc_status>
											<label for="deacc_status" class="data-entry-label mb-0">Status</label>
											<select name="deacc_status" id="deacc_status" class="data-entry-select" >
												<option value=""></option>
												<cfloop query="ctDeaccStatus">
													<cfif pdeacc_status eq ctDeaccStatus.deacc_status>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctDeaccStatus.deacc_status#" #selected#>#ctDeaccStatus.deacc_status#</option>
												</cfloop>
												<cfif ctDeaccStatus.recordcount GT 2>
													<cfloop query="ctDeaccStatus">
														<cfif pdeacc_status eq '!' & ctDeaccStatus.deacc_status>
															<cfset selected="selected">
														<cfelse>
															<cfset selected="">
														</cfif>
														<option value="!#ctDeaccStatus.deacc_status#" #selected#>not #ctDeaccStatus.deacc_status#</option>
													</cfloop>
												</cfif>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="shipment_count" class="data-entry-label">Shipments</label>
											<select name="shipment_count" id="shipment_count" class="data-entry-select" title="number of shipments">
												<option value=""></option>
												<cfif shipment_count IS "0"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="0" #scsel#>None</option>
												<cfif shipment_count IS "1"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1" #scsel#>One</option>
												<cfif shipment_count IS "1+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1+" #scsel#>One or more</option>
												<cfif shipment_count IS "2+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="2+" #scsel#>Two or more</option>
												<cfif shipment_count IS "3+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="3+" #scsel#>Three or more</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="foreign_shipments" class="data-entry-label" aria-label="International Shipmements">International Shipment</label>
											<select name="foreign_shipments" id="foreign_shipments" class="data-entry-select" title="transaction has international shipments">
												<option value=""></option>
												<cfif foreign_shipments IS "0"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="0" #fssel#>No</option>
												<cfif foreign_shipments IS "1+"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="1+" #fssel#>Yes</option>
											</select>
										</div>
									</div>
									<div class="bg-light border rounded p-1 mx-1 my-2">
										<div class="form-row mb-2 mx-0 my-2">
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_1" id="deacc_trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_deacc">
														<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_1" id="deacc_agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" placeholder="agent name" >
												<input type="hidden" name="agent_1_id" id="deacc_agent_1_id" value="#agent_1_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_2" id="deacc_trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_deacc">
														<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_2" id="deacc_agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" placeholder="agent name">
												<input type="hidden" name="agent_2_id" id="deacc_agent_2_id" value="#agent_2_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_3" id="deacc_trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_deacc">
														<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_3" id="deacc_agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" placeholder="agent name">
												<input type="hidden" name="agent_3_id" id="deacc_agent_3_id" value="#agent_3_id#" >
											</div>
										</div>
										<script>
									$(document).ready(function() {
										$(makeConstrainedAgentPicker('deacc_agent_1','accn_agent_1_id','transaction_agent'));
										$(makeConstrainedAgentPicker('deacc_agent_2','accn_agent_2_id','transaction_agent'));
										$(makeConstrainedAgentPicker('deacc_agent_3','accn_agent_3_id','transaction_agent'));
									});
									</script> 
									</div>
									</div>
									<div class="form-row px-1">
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="deacc_trans_date">Deaccession Date</label>
												<input name="trans_date" id="deacc_trans_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#trans_date#" aria-label="start of range for date deaccessioned">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="deacc_to_trans_date">end of search range for date deaccessioned</label>		
												<input type="text" name="to_trans_date" id="deacc_to_trans_date" value="#to_trans_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="date_entered">Entered Date</label>
												<input name="date_entered" id="date_entered" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#date_entered#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_date_entered">end of search range for date entered</label>		
												<input type="text" name="to_date_entered" id="to_date_entered" value="#to_date_entered#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
											</div>
										</div>
										<div class="col-md-2">
											<label class="data-entry-label mb-0" for="deacc_method">Method of Transfer</label>
											<input type="text" name="deacc_method" class="data-entry-input" value="#deacc_method#" id="deacc_method">
										</div>
										<div class="col-md-2">
											<label class="data-entry-label mb-0" for="value">Value</label>
											<input type="text" name="value" class="data-entry-input" value="#value#" id="value">
										</div>
									</div>
									<div class="form-row px-1 mt-2">
										<div class="col-md-6">
											<div class="border bg-light rounded pt-2 pb-3 mb-2 px-3 px-md-4">
												<div class="col-md-12 px-0 mt-1">
													<label for="d_nature_of_material" class="data-entry-label mb-0 pb-0">Nature of Material</label>
													<input type="text" name="nature_of_material" class="data-entry-input" value="#nature_of_material#" id="d_nature_of_material">
												</div>
												<div class="col-md-12 px-0 mt-1">
													<label for="deacc_reason" class="data-entry-label mb-0 pb-0">Reason for Deaccession</label>
													<input type="text" name="deacc_reason" class="data-entry-input" value="#deacc_reason#" id="deacc_reason">
												</div>
												<div class="col-md-12 px-0 mt-1">
													<label for="deacc_trans_remarks" class="data-entry-label mb-0 pb-0">Internal Remarks</label>
													<input type="text" name="trans_remarks" class="data-entry-input" value="#trans_remarks#" id="deacc_trans_remarks">
												</div>
											</div>
											<div class="border bg-light rounded px-2 mb-2 mb-md-0 py-3 py-lg-2">
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<div class="col-3 px-0">
														<label for="deacc_part_name_oper" class="data-entry-label mb-0">Part</label>
														<cfif part_name_oper IS "is">
															<cfset isselect = "selected">
															<cfset containsselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset containsselect = "selected">
														</cfif>
														<select id="deacc_part_name_oper" name="part_name_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="contains" #containsselect#>contains</option>
														</select>
													</div>
													<div class="col-9 px-0">
														<label for="deacc_part_name" class="data-entry-label mb-0">Part Name</label>
														<input type="text" id="deacc_part_name" name="part_name" class="px-0 data-entry-select-input ui-autocomplete-input" value="#part_name#" autocomplete="off">
													</div>
												</div>
												<div class="form-row mx-0 px-2 px-sm-3">
													<div class="col-3 px-0 mt-1">
														<label for="deacc_part_disp_oper" class="data-entry-label mb-0">Disp.</label>
														<cfif part_disp_oper IS "is">
															<cfset isselect = "selected">
															<cfset notselect = "">
															<cfelse>
															<cfset isselect = "">
															<cfset notselect = "selected">
														</cfif>
														<select id="deacc_part_disp_oper" name="part_disp_oper" class="data-entry-prepend-select input-group-prepend">
															<option value="is" #isselect#>is</option>
															<option value="isnot" #notselect#>is not</option>
														</select>
													</div>
													<div class="col-9 px-0 mt-1">
														<cfset coll_obj_disposition_array = ListToArray(coll_obj_disposition)>
														<label for="deacc_coll_obj_disposition" class="data-entry-label mb-0">Part Disposition</label>
														<div name="coll_obj_disposition" id="deacc_coll_obj_disposition" class="w-100"></div>
														<script>
															function setDeaccDispositionValues() {
																$('##coll_obj_disposition').jqxComboBox('clearSelection');
																<cfloop query="ctCollObjDisp">
																	<cfif ArrayContains(coll_obj_disposition_array, ctCollObjDisp.coll_obj_disposition)>
																		$("##deacc_coll_obj_disposition").jqxComboBox("selectItem","#ctCollObjDisp.coll_obj_disposition#");
																	</cfif>
																</cfloop>
															};
															$(document).ready(function () {
																var dispositionsource = [
																	""
																	<cfloop query="ctCollObjDisp">
																		,"#ctCollObjDisp.coll_obj_disposition#"
																	</cfloop>
																];
																$("##deacc_coll_obj_disposition").jqxComboBox({ source: dispositionsource, multiSelect: true, height: '23px', width: '100%' });
																setDeaccDispositionValues();
															});
														</script> 
													</div>
												</div>
												<div class="form-row mx-0 mb-1 px-2 px-sm-3">
													<input type="hidden" id="deacc_collection_object_id" name="collection_object_id" value="#collection_object_id#">
													<!--- if we were given part collection object id values, look up the catalog numbers for them and display for the user --->
													<!--- used in call from specimen details to find loans from parts. --->
													<cfif isDefined("collection_object_id") AND len(collection_object_id) GT 0>
														<cfquery name="guidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidLookup">
															select distinct guid 
															from #session.flatTableName# flat 
																left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
															where 
																specimen_part.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
																OR flat.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
														</cfquery>
														<cfloop query="guidLookup">
															<cfif not listContains(specimen_guid,guidLookup.guid)>
																<cfif len(specimen_guid) EQ 0>
																	<cfset specimen_guid = guidLookup.guid>
																<cfelse>
																	<cfset specimen_guid = specimen_guid & "," & guidSearch.guid>
																</cfif>
															</cfif>
														</cfloop>
													</cfif>
													<!--- display the provided guids, backing query will use both these and the hidden collection_object_id for the lookup. --->
													<!--- if user changes the value of the guid list, clear the hidden collection object id field. --->
													<div class="col-md-12 px-0 pb-1 mt-1">
														<label for="deacc_specimen_guid" class="data-entry-label mb-0 pb-0">Cataloged Item in Deaccession</label>
														<input type="text" name="specimen_guid" 
															class="data-entry-input" value="#specimen_guid#" id="deacc_specimen_guid" placeholder="MCZ:Coll:nnnnn"
															onchange="$('##collection_object_id').val('');">
													</div>
													<script>
													</script>
												</div>
											</div>
										</div>

										<div class="col-md-6">
											<div class="border bg-light rounded px-0 pt-1 mb-0 pb-3">
												<h3 class="h5 px-3 my-xl-3">Permissions &amp; Rights</h3>
												<div class="col-md-12">
													<label for="de_permit_num" id="de_permit_picklist" class="data-entry-label mb-0 pt-0 mt-0">Document/Permit Number:</label>
													<div class="input-group">
														<input type="hidden" name="permit_id" id="de_permit_id" value="#permit_id#">
														<input type="text" name="permit_num" id="de_permit_num" class="data-entry-addon-input" value="#permit_num#">
														<div class="input-group-append"> <span role="button" class="data-entry-addon" aria-label="pick a permit" tabindex="0" onkeypress="handleDePermitPickAction();" onclick="handleDePermitPickAction();" aria-labelledby="de_permit_picklist">Pick</span> </div>
														<script>
															function handleDePermitPickAction(event) {
																openfindpermitdialog('de_permit_num','de_permit_id','de_permitpickerdialog');
															}
														</script>
														<div id="de_permitpickerdialog"></div>
													</div>
													<script>
														$(document).ready(function() {
															$(makePermitPicker('de_permit_num','de_permit_id'));
															$('##de_permit_num').blur( function () {
																// prevent an invisible permit_id from being included in the search.
																if ($('##de_permit_num').val().trim() == "") { 
																	$('##de_permit_id').val("");
																}
															});
														});
													</script>
												</div>
												<div class="form-row px-1 mx-0 mt-1">
												<div class="col-12 col-md-4 col-xl-4 px-3 pl-md-3 pr-md-2">
													<label for="de_issued_by_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued By</label>
													<input type="text" name="IssuedByAgent" id="de_issued_by_agent" class="data-entry-input" value="#IssuedByAgent#" placeholder="issued by agent name" >
													<input type="hidden" name="issued_by_id" id="de_issued_by_agent_id" value="#issued_by_id#" >
												</div>
												<div class="col-12 col-md-4 col-xl-4 px-3 px-md-1 px-xl-2">
													<label for="de_issued_to_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued To</label>
													<input type="text" name="IssuedToAgent" id="de_issued_to_agent" class="data-entry-input" value="#IssuedToAgent#" placeholder="issued to agent name" >
													<input type="hidden" name="issued_to_id" id="de_issued_to_agent_id" value="#issued_to_id#" >
												</div>
												<div class="col-12 col-md-4 col-xl-4 ml-0 ml-xl-0 px-3 pl-xl-2 pr-xl-3">
													<label for="de_permit_contact_agent" class="data-entry-label mb-0 pt-0 mt-0">Contact Agent</label>
													<input type="text" name="permit_contact_agent" id="de_permit_contact_agent" class="data-entry-input" value="#permit_contact_agent#" placeholder="contact agent name" >
													<input type="hidden" name="permit_contact_id" id="de_permit_contact_agent_id" value="#permit_contact_id#" >
												</div>
												</div>
											
												<script>
													$(document).ready(function() {
														$(makeConstrainedAgentPicker('de_issued_by_agent','de_issued_by_agent_id','permit_issued_by_agent'));
														$(makeConstrainedAgentPicker('de_issued_to_agent','de_issued_to_agent_id','permit_issued_to_agent'));
														$(makeConstrainedAgentPicker('de_permit_contact_agent','de_permit_contact_agent_id','permit_contact_agent'));
													});
												</script>
												<div class="col-md-12 mt-1">
													<label for="deacc_restriction_summary" class="data-entry-label mb-0 pb-0">Restrictions <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="restriction_summary" class="data-entry-input" value="#restriction_summary#" id="deacc_restriction_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="deacc_benefits_summary" class="data-entry-label mb-0 pb-0">Benefits <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_summary" class="data-entry-input" value="#benefits_summary#" id="deacc_benefits_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="deacc_benefits_provided" class="data-entry-label mb-0 pb-0">Benefits Provided <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_provided" class="data-entry-input" value="#benefits_provided#" id="deacc_benefits_provided">
												</div>
												<div class="form-row px-3 mt-1">
													<div class="coll-12 col-md-6">
														<cfset ppermit_type = permit_type>
														<label for="deacc_permit_type" class="data-entry-label mb-0 pb-0">Has Document of Type</label>
														<select name="permit_type" class="data-entry-select" id="deacc_permit_type">
															<option value=""></option>
															<cfloop query="ctpermit_type_deaccn">
																<cfif ppermit_type eq ctpermit_type_deaccn.permit_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctpermit_type_deaccn.permit_type#" #selected# >#ctpermit_type_deaccn.permit_type# (#ctpermit_type_deaccn.ct# deaccessions)</option>
															</cfloop>
														</select>
													</div>
													<div class="coll-12 col-md-6">
														<label for="deacc_permit_specific_type" class="data-entry-label mb-0 pb-0">Specific Type</label>
														<select name="permit_specific_type" class="data-entry-select" id="deacc_permit_specific_type">
															<option value=""></option>
															<cfloop query="ctspecific_permit_type_deaccn">
																<cfif permit_specific_type eq ctspecific_permit_type_deaccn.specific_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctspecific_permit_type_deaccn.specific_type#" #selected# >#ctspecific_permit_type_deaccn.specific_type# (#ctspecific_permit_type_deaccn.permit_type#) [#ctspecific_permit_type_deaccn.ct# deaccessions)</option>
															</cfloop>
														</select>
													</div>
												</div>
											</div>
										</div>
									</div>	
									<div class="form-row mt-1 mx-4">
										<div class="col-12 text-left">
											<button class="btn-xs btn-primary px-2 mr-2" id="deaccnSearchButton" type="submit" aria-label="Search Deaccessions">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning mr-2" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new deaccession search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findDeaccessions';" >New Search</button>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new deaccession" href="/transactions/Deaccession.cfm?action=new">Create New Deaccession</a>
										</div>
									</div>
								</form>
							</div><!---tab-pane deaccession search---> 

							<!--- Borrow search tab panel --->
							<div id="panel-5" role="tabpanel" aria-labelledby="tab-5" class="mx-0 #borrowTabActive#" tabindex="0" #borrowTabShow#>
								<h2 class="h3 card-title my-0">Find Borrows <i class="fas fa-info-circle" onClick="getMCZDocs('Find_Borrow')" aria-label="help link"></i></h2>
								<!--- Search for just loans ---->
								<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select coll_obj_disposition from ctcoll_obj_disp
								</cfquery>
								<cfquery name="cttrans_agent_role_borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select MCZBASE.count_transagent_for_role(cttrans_agent_role.trans_agent_role,'borrow') cnt, cttrans_agent_role.trans_agent_role
									from cttrans_agent_role
										left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
									where trans_agent_role_allowed.transaction_type = 'Borrow'
										or cttrans_agent_role.trans_agent_role = 'entered by'
									group by cttrans_agent_role.trans_agent_role
									order by cttrans_agent_role.trans_agent_role
								</cfquery>
								<cfif not isdefined("borrow_number")>
									<cfset borrow_number="">
								</cfif>
								<form id="borrowSearchForm" class="mt-2">
									<input type="hidden" name="method" value="getBorrows" class="keeponclear">
									<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
									<div class="form-row px-1 mb-2 mb-xl-2">
										<div class="col-12 col-md-4 mt-0">
											<div class="input-group">
												<div class="col-6 px-0">
													<label for="borrow_collection_id" class="data-entry-label">Collection Name</label>
													<select name="collection_id" size="1" class="data-entry-prepend-select" id="borrow_collection_id">
														<option value="-1">any collection</option>
														<cfloop query="ctcollection">
															<cfif ctcollection.collection eq selectedCollection>
																<cfset selected="selected">
																<cfelse>
																<cfset selected="">
															</cfif>
															<option value="#collection_id#" #selected#>#collection#</option>
														</cfloop>
													</select>
												</div>
												<div class="col-6 px-0">
													<label for="borrow_number" class="data-entry-label mb-0"><span class="d-none d-xl-inline">MCZ</span> Borrow Number</label>
													<input type="text" name="borrow_number" id="borrow_number" class="data-entry-select-input" value="#borrow_number#" placeholder="Byyyy-n-Coll">
												</div>
											</div>
										</div>
										<div class="col-12 col-md-2">
											<label class="data-entry-label px-3 mx-1 mb-0" for="lenders_trans_num_cde">
												Lender's Loan Number
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##lenders_trans_num_cde').val('='+$('##lenders_trans_num_cde').val());" > (=) <span class="sr-only">prefix with equals sign for exact match search</span></a><!--- ' --->
											</label>
											<input type="text" name="lenders_trans_num_cde" class="data-entry-input" value="#lenders_trans_num_cde#" id="lenders_trans_num_cde">
										</div>
										<div class="col-12 col-md-2">
											<cfset pborrow_status = borrow_status>
											<label for="borrow_status" class="data-entry-label mb-0">Status</label>
											<select name="borrow_status" id="borrow_status" class="data-entry-select" >
												<option value=""></option>
												<cfloop query="ctBorrowStatus">
													<cfif pborrow_status eq ctBorrowStatus.borrow_status>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctBorrowStatus.borrow_status#" #selected#>#ctBorrowStatus.borrow_status#</option>
												</cfloop>
												<cfif ctBorrowStatus.recordcount GT 2>
													<cfloop query="ctBorrowStatus">
														<cfif pborrow_status eq '!' & ctBorrowStatus.borrow_status>
															<cfset selected="selected">
														<cfelse>
															<cfset selected="">
														</cfif>
														<option value="!#ctBorrowStatus.borrow_status#" #selected#>not #ctBorrowStatus.borrow_status#</option>
													</cfloop>
												</cfif>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="shipment_count" class="data-entry-label">Shipments</label>
											<select name="shipment_count" id="shipment_count" class="data-entry-select" title="number of shipments">
												<option value=""></option>
												<cfif shipment_count IS "0"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="0" #scsel#>None</option>
												<cfif shipment_count IS "1"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1" #scsel#>One</option>
												<cfif shipment_count IS "1+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="1+" #scsel#>One or more</option>
												<cfif shipment_count IS "2+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="2+" #scsel#>Two or more</option>
												<cfif shipment_count IS "3+"><cfset scsel="selected"><cfelse><cfset scsel=""></cfif>
												<option value="3+" #scsel#>Three or more</option>
											</select>
										</div>
										<div class="col-12 col-md-2"> 
											<label for="foreign_shipments" class="data-entry-label" aria-label="International Shipmements">International Shipment</label>
											<select name="foreign_shipments" id="foreign_shipments" class="data-entry-select" title="transaction has international shipments">
												<option value=""></option>
												<cfif foreign_shipments IS "0"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="0" #fssel#>No</option>
												<cfif foreign_shipments IS "1+"><cfset fssel="selected"><cfelse><cfset fssel=""></cfif>
												<option value="1+" #fssel#>Yes</option>
											</select>
										</div>
									</div>
									<div class="bg-light border rounded p-1 mx-1 my-2">
										<div class="form-row mb-2 mx-0 my-2">
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_1" id="borrow_trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_borrow">
														<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_1" id="borrow_agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" placeholder="agent name" >
												<input type="hidden" name="agent_1_id" id="borrow_agent_1_id" value="#agent_1_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_2" id="borrow_trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_borrow">
														<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_2" id="borrow_agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" placeholder="agent name">
												<input type="hidden" name="agent_2_id" id="borrow_agent_2_id" value="#agent_2_id#" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_3" id="borrow_trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend">
													<option value="">agent role</option>
													<cfloop query="cttrans_agent_role_borrow">
														<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
													</cfloop>
												</select>
												<input type="text" name="agent_3" id="borrow_agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" placeholder="agent name">
												<input type="hidden" name="agent_3_id" id="borrow_agent_3_id" value="#agent_3_id#" >
											</div>
										</div>
										<script>
									$(document).ready(function() {
										$(makeConstrainedAgentPicker('borrow_agent_1','borrow_agent_1_id','transaction_agent'));
										$(makeConstrainedAgentPicker('borrow_agent_2','borrow_agent_2_id','transaction_agent'));
										$(makeConstrainedAgentPicker('borrow_agent_3','borrow_agent_3_id','transaction_agent'));
									});
									</script> 
									</div>
									</div>

									<div class="form-row px-1">
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 pt-1 px-0 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="borrow_rec_date">Received Date</label>
												<input name="rec_date" id="borrow_rec_date" type="text" placeholder="start yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-5" value="#rec_date#" aria-label="start of range for date received">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="borrow_to_rec_date">end of range for date received</label>
												<input type="text" name="to_rec_date" id="borrow_to_rec_date" value="#to_rec_date#" placeholder="end yyyy-mm-dd or yyyy" class="datetimeinput data-entry-input col-4 col-xl-4">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="borrow_due_date">Due Date</label>
												<input name="due_date" id="borrow_due_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#due_date#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="borrow_to_due_date">end of search range for date entered</label>		
												<input type="text" name="to_due_date" id="borrow_to_due_date" value="#to_due_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="lenders_loan_date">Lender's Loan Date</label>
												<input name="lenders_loan_date" id="lenders_loan_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#loan_date#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="lenders_to_loan_date">end of search range for date entered</label>		
												<input type="text" name="to_loan_date" id="lenders_to_loan_date" value="#to_loan_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
									</div>

									<div class="form-row px-1 mt-2">
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="borrow_trans_date">Borrow Date</label>
												<input name="trans_date" id="borrow_trans_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#trans_date#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="borrow_to_trans_date">end of search range for borrow date</label>		
												<input type="text" name="to_trans_date" id="borrow_to_trans_date" value="#to_trans_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="borrow_date_entered">Entered Date</label>
												<input name="date_entered" id="borrow_date_entered" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#date_entered#" aria-label="start of range for date entered">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="borrow_to_date_entered">end of search range for date entered</label>		
												<input type="text" name="to_date_entered" id="borrow_to_date_entered" value="#to_date_entered#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
										<div class="col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="borrow_return_acknowledged_date">Return Acknowledged Date</label>
												<input name="return_acknowledged_date" id="borrow_return_acknowledged_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#return_acknowledged_date#" aria-label="start of range for date return acknowleged">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="borrow_to_return_acknowledged_date">end of search range for date entered</label>		
												<input type="text" name="to_return_acknowledged_date" id="borrow_to_return_acknowledged_date" value="#to_return_acknowledged_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy">
											</div>
										</div>
									</div>

									<div class="form-row px-1 mt-2">
										<div class="col-md-6">
											<div class="form-row border bg-light rounded pt-2 pb-3 mb-2 px-3 px-md-4">
												<div class="col-12 col-md-6 px-0">
													<label class="data-entry-label mb-0 pb-0" for="no_of_specimens">Total No. of Specimens</label>
													<input type="text" name="no_of_specimens" class="data-entry-input" value="#no_of_specimens#" id="no_of_specimens" placeholder="&gt;100">
												</div>
												<div class="col-12 col-md-6 px-0 pl-md-1">
													<label for="borrow_trans_remarks" class="data-entry-label mb-0 pb-0">Lender Acknowledged Return</label>
													<select name="lenders_invoice_returned" class="data-entry-select" value="#lenders_invoice_returned#" id="lenders_invoice_returned">
														<cfif len(lenders_invoice_returned) EQ 0 >
															<cfset bsel ="selected">
															<cfset ysel ="">
															<cfset nsel ="">
														<cfelseif lenders_invoice_returned EQ 1 >
															<cfset bsel ="">
															<cfset ysel ="selected">
															<cfset nsel ="">
														<cfelse>
															<cfset bsel ="">
															<cfset ysel ="">
															<cfset nsel ="selected">
														</cfif>
														<option value="" #bsel#></option>
														<option value="1" #ysel#>Yes</option>
														<option value="0" #nsel#>No</option>
													</select>
												</div>
												<div class="col-12 col-md-6 px-0">
													<label for="bo_nature_of_material" class="data-entry-label mb-0 pb-0">Nature of Material</label>
													<input type="text" name="nature_of_material" class="data-entry-input" value="#nature_of_material#" id="bo_nature_of_material">
												</div>
												<div class="col-12 col-md-6 px-0 pl-md-1">
													<label for="lenders_instructions" class="data-entry-label mb-0 pb-0">Lender's Instructions</label>
													<input type="text" name="lenders_instructions" class="data-entry-input" value="#lenders_instructions#" id="lenders_instructions">
												</div>
												<div class="col-12 col-md-6 px-0">
													<label for="borrow_description" class="data-entry-label mb-0 pb-0">Borrow Description</label>
													<input type="text" name="borrow_description" class="data-entry-input" value="#borrow_description#" id="borrow_description">
												</div>
												<div class="col-12 col-md-6 px-0 pl-md-1">
													<label for="borrow_trans_remarks" class="data-entry-label mb-0 pb-0">Internal Remarks</label>
													<input type="text" name="trans_remarks" class="data-entry-input" value="#trans_remarks#" id="borrow_trans_remarks">
												</div>
												<div class="col-md-12 px-0">
													<label class="data-entry-label" for="borrow_catalog_number">Catalog Number</label>
													<input type="text" name="borrow_catalog_number" class="data-entry-input" value="#borrow_catalog_number#" id="borrow_catalog_number">
												</div>
												<div class="col-md-12 px-0">
													<label class="data-entry-label" for="borrow_sci_name">Scientific Name</label>
													<input type="text" name="borrow_sci_name" class="data-entry-input" value="#borrow_sci_name#" id="borrow_sci_name" >
												</div>
												<div class="col-md-12 px-0">
													<label class="data-entry-label" for="borrow_spec_prep">Specimen Preparation</label>
													<input type="text" name="borrow_spec_prep" class="data-entry-input" value="#borrow_spec_prep#" id="borrowspec_prep">
												</div>
												<div class="col-md-12 px-0">
													<label class="data-entry-label" for="borrow_type_status">Type Status <span class="small">(NOT NULL)</span></label>
													<input type="text" name="borrow_type_status" class="data-entry-input" value="#borrow_type_status#" id="borrow_type_status" >
												</div>
											</div>
										</div>

										<div class="col-md-6">
											<div class="border bg-light rounded px-0 px-sm-2 pt-1 mb-0 pb-3">
												<h3 class="h5 px-3 my-xl-3">Permissions &amp; Rights</h3>
												<div class="col-md-12">
													<label for="bo_permit_num" id="bo_permit_picklist" class="data-entry-label mb-0 pt-0 mt-0">Document/Permit Number:</label>
													<div class="input-group">
														<input type="hidden" name="permit_id" id="bo_permit_id" value="#permit_id#">
														<input type="text" name="permit_num" id="bo_permit_num" class="data-entry-addon-input" value="#permit_num#">
														<div class="input-group-append"> <span role="button" class="data-entry-addon" tabindex="0" aria-label="pick a permit" onkeypress="handleBorrowPermitPickAction();" onclick="handleBorrowPermitPickAction();" aria-labelledby="bo_permit_picklist">Pick</span> </div>
														<script>
															function handleBorrowPermitPickAction(event) {
																openfindpermitdialog('bo_permit_num','bo_permit_id','bo_permitpickerdialog');
															}
														</script>
														<div id="bo_permitpickerdialog"></div>
													</div>
													<script>
														$(document).ready(function() {
															$(makePermitPicker('bo_permit_num','bo_permit_id'));
															$('##bo_permit_num').blur( function () {
																// prevent an invisible permit_id from being included in the search.
																if ($('##bo_permit_num').val().trim() == "") { 
																	$('##bo_permit_id').val("");
																}
															});
														});
													</script>
												</div>
												<div class="form-row mx-0 mt-1">
												<div class="col-12 col-md-6 col-xl-4 px-3 pl-md-3 pr-md-2">
													<label for="bo_issued_by_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued By</label>
													<input type="text" name="IssuedByAgent" id="bo_issued_by_agent" class="data-entry-input" value="#IssuedByAgent#" placeholder="issued by agent name" >
													<input type="hidden" name="issued_by_id" id="bo_issued_by_agent_id" value="#issued_by_id#" >
												</div>
												<div class="col-12 col-md-6 col-xl-4 px-3 pr-md-3">
													<label for="bo_issued_to_agent" class="data-entry-label mb-0 pt-0 mt-0">Issued To</label>
													<input type="text" name="IssuedToAgent" id="bo_issued_to_agent" class="data-entry-input" value="#IssuedToAgent#" placeholder="issued to agent name" >
													<input type="hidden" name="issued_to_id" id="bo_issued_to_agent_id" value="#issued_to_id#" >
												</div>
												<div class="col-12 col-md-8 col-xl-4 ml-0 ml-xl-0 px-3 pl-xl-2 pr-xl-3">
													<label for="bo_permit_contact_agent" class="data-entry-label mb-0 pt-0 mt-0">Contact Agent</label>
													<input type="text" name="permit_contact_agent" id="bo_permit_contact_agent" class="data-entry-input" value="#permit_contact_agent#" placeholder="contact agent name" >
													<input type="hidden" name="permit_contact_id" id="bo_permit_contact_agent_id" value="#permit_contact_id#" >
												</div>
												</div>
											
												<script>
													$(document).ready(function() {
														$(makeConstrainedAgentPicker('bo_issued_by_agent','bo_issued_by_agent_id','permit_issued_by_agent'));
														$(makeConstrainedAgentPicker('bo_issued_to_agent','bo_issued_to_agent_id','permit_issued_to_agent'));
														$(makeConstrainedAgentPicker('bo_permit_contact_agent','bo_permit_contact_agent_id','permit_contact_agent'));
													});
												</script>
												<div class="col-md-12 mt-1">
													<label for="borrow_restriction_summary" class="data-entry-label mb-0 pb-0">Restrictions <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="restriction_summary" class="data-entry-input" value="#restriction_summary#" id="borrow_restriction_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="borrow_benefits_summary" class="data-entry-label mb-0 pb-0">Benefits <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_summary" class="data-entry-input" value="#benefits_summary#" id="borrow_benefits_summary">
												</div>
												<div class="col-md-12 mt-1">
													<label for="borrow_benefits_provided" class="data-entry-label mb-0 pb-0">Benefits Provided <span class="small">(accepts substring, NULL, NOT NULL)</span></label>
													<input type="text" name="benefits_provided" class="data-entry-input" value="#benefits_provided#" id="borrow_benefits_provided">
												</div>
												<div class="form-row px-3 mt-1">
													<div class="coll-12 col-md-6">
														<cfset ppermit_type = permit_type>
														<label for="borrow_permit_type" class="data-entry-label mb-0 pb-0">Has Document of Type</label>
														<select name="permit_type" class="data-entry-select" id="borrow_permit_type">
															<option value=""></option>
															<cfloop query="ctpermit_type_borrow">
																<cfif ppermit_type eq ctpermit_type_borrow.permit_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctpermit_type_borrow.permit_type#" #selected# >#ctpermit_type_borrow.permit_type# (#ctpermit_type_borrow.ct# borrows)</option>
															</cfloop>
														</select>
													</div>
													<div class="coll-12 col-md-6">
														<label for="borrow_permit_specific_type" class="data-entry-label mb-0 pb-0">Specific Type</label>
														<select name="permit_specific_type" class="data-entry-select" id="borrow_permit_specific_type">
															<option value=""></option>
															<cfloop query="ctspecific_permit_type_borrow">
																<cfif permit_specific_type eq ctspecific_permit_type_borrow.specific_type>
																	<cfset selected="selected">
																<cfelse>
																	<cfset selected="">
																</cfif>
																<option value="#ctspecific_permit_type_borrow.specific_type#" #selected# >#ctspecific_permit_type_borrow.specific_type# (#ctspecific_permit_type_borrow.permit_type#) [#ctspecific_permit_type_borrow.ct# borrows)</option>
															</cfloop>
														</select>
													</div>
												</div>
											</div>
										</div>
									</div>	
									<div class="form-row mt-2 mx-4">
										<div class="col-12 text-left">
											<button class="btn-xs btn-primary px-2 mr-2" id="borrowSearchButton" type="submit" aria-label="Search Borrows">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning mr-2" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new borrow search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findBorrows';" >New Search</button>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new borrow" href="/transactions/Borrow.cfm?action=new">Create New Borrow</a>
										</div>
									</div>
								</form>
							</div><!---tab-pane borrow search---> 
						</div>
						<!--- End tab-content div ---> 
					</div>
				</div>
			</div>	
		</section>													
		<!--- Results table as a jqxGrid. --->
		<section class="container-fluid">
			<div class="row">
				<div class="col-12 mb-5">
					<div class="row mt-1 mb-0 mx-0 px-2 pb-0 jqx-widget-header border">
						<h1 class="h4 pt-2 ml-2 ml-md-1 mt-1">Results: 
							<span class="font-weight-normal pr-2" id="resultCount"></span>
							<span id="resultLink" class="pr-2 font-weight-normal"></span>
						</h1> 
						<div id="saveDialogButton" class=""></div>
						<div id="saveDialog"></div>
						<div id="columnPickDialog">
							<div id="columnPick" class="px-1"></div>
						</div>
						<div id="columnPickDialogButton"></div>
						<div id="resultDownloadButtonContainer"></div>
						<div id="selectModeContainer" class="ml-3" style="display: none;" >
							<script>
								function changeSelectMode(){
									var selmode = $("##selectMode").val();
									$("##searchResultsGrid").jqxGrid({selectionmode: selmode});
									if (selmode=="none") { 
										$("##searchResultsGrid").jqxGrid({enableBrowserSelection: true});
									} else {
										$("##searchResultsGrid").jqxGrid({enableBrowserSelection: false});
									}
								};
							</script>
							<label class="data-entry-label d-inline w-auto mt-1" for="selectMode">Grid Select:</label>
							<select class="data-entry-select d-inline w-auto mt-1" id="selectMode" onChange="changeSelectMode();">
								<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option #selected# value="none">Text</option>
								<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option #selected# value="singlecell">Single Cell</option>
								<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option #selected# value="singlerow">Single Row</option>
								<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
								<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
							</select>
						</div>
						<output id="actionFeedback" class="btn btn-xs btn-transparent my-2 pt-1 px-2 mx-1 border-0"></output>
					</div>
					<div class="row mt-0 mx-0">
						<!--- div id="searchText"></div  not needed?  --->
						<!--Grid Related code is below along with search handlers-->
						<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
						<div id="enableselection"></div>
					</div>
				</div>
			</div>
		</section>															
	</main>
	<cfset cellRenderClasses = "ml-1"><!--- for cell renderers to match default --->
	<script>
	/** createLoanRowDetailsDialog, create a custom loan specific popup dialog to show details for
		a row of loan data from the loan reults grid.
	
		@see createRowDetailsDialog defined in /shared/js/shared-scripts.js for details of use.
	 */
	function createLoanRowDetailsDialog(gridId, rowDetailsTargetId, datarecord, rowIndex) {
		var columns = $('##' + gridId).jqxGrid('columns').records;
		var content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul class='card-columns pl-md-3'>";
		if (columns.length < 21) {
			// don't split into columns for shorter sets of columns.
			content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul>";
		}
		var daysdue = datarecord['dueindays'];
		var loanstatus = datarecord['loan_status'];
		var gridWidth = $('##' + gridId).width();
		var dialogWidth = Math.round(gridWidth/2);
		var pid = datarecord['pid'];
		var transaction_id = datarecord['transaction_id'];
		if (dialogWidth < 299) { dialogWidth = 300; }
		for (i = 1; i < columns.length; i++) {
			var text = columns[i].text;
			var datafield = columns[i].datafield;
			if (datafield == 'loan_number') { 
				if (transaction_id) {
	 				content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a class='btn btn-outline-primary px-2 btn-xs' href='/transactions/Loan.cfm?action=editLoan&transaction_id="+transaction_id+"' target='_blank'>Edit</a> " + datarecord[datafield] + "</li>";
				} else { 
					content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'dueindays') { 
				var daysoverdue = -(datarecord[datafield]);
				if (daysoverdue > 0 && loanstatus != 'closed') {
					var overdue = "";
					if (daysoverdue > 731) { 
						overdue = Math.round(daysoverdue/365.25) + " years";
					} else if (daysoverdue > 365) { 
						overdue = Math.round(daysoverdue/30.44) + " months";
	 				} else {
						overdue = daysoverdue + " days";
					} 
					content = content + "<li class='text-danger pr-3'><strong>Overdue:</strong> <strong>by " + overdue + "</strong></li>";
				} else { 
					content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'return_due_date') { 
				if (daysdue < 0 && loanstatus != 'closed') {
					content = content + "<li class='text-danger pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				} else { 
					content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'project_name') { 
				if (pid) {
					content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a class='btn btn-link btn-xs' href='/ProjectDetail.cfm?project_id="+pid+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
				} else { 
					content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'id_link') {
				// don't show to user (duplicates loan number)
				console.log(datarecord[datafield]);
			} else if (datafield == 'transaction_id') {
				// don't show to user
				console.log(datarecord[datafield]);
			} else {
				content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
			}
		}
		content = content + "</ul>";
		var transaction_id = datarecord['transaction_id'];
		content = content + "<ul class='list-group list-group-horizontal'><li class='list-group-item'><a href='/a_loanItemReview.cfm?transaction_id="+transaction_id+"' class='btn btn-secondary btn-xs' target='_blank'>Review Items</a></li>";
		content = content + "<li class='list-group-item'><a href='/SpecimenSearch.cfm?Action=dispCollObj&transaction_id="+transaction_id+"' class='btn btn-secondary btn-xs' target='_blank'>Add Items</a></li>";
		content = content + "<li class='list-group-item'><a href='/loanByBarcode.cfm?transaction_id="+transaction_id+"' class='btn btn-secondary btn-xs' target='_blank'>Add Items by Barcode</a></li>";
		content = content + "<li class='list-group-item'><a href='/transactions/Loan.cfm?action=editLoan&transaction_id=" + transaction_id +"' class='btn btn-secondary btn-xs' target='_blank'>Edit Loan</a></li></ul>";
		content = content + "</div>";
		$("##" + rowDetailsTargetId + rowIndex).html(content);
		$("##"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
			{
				autoOpen: true,
				buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("##" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
				width: dialogWidth,
				title: 'Loan Details'
			}
		);
		// Workaround, expansion sits below row in zindex.
		var maxZIndex = getMaxZIndex();
		$("##"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
	};
	/** createAccnRowDetailsDialog, create a custom accession specific popup dialog to show details for
		a row of accession data from the accession reults grid.
	
		@see createRowDetailsDialog defined in /shared/js/shared-scripts.js for details of use.
	 */
	function createAccnRowDetailsDialog(gridId, rowDetailsTargetId, datarecord, rowIndex) {
		var columns = $('##' + gridId).jqxGrid('columns').records;
		var content = "<div id='" + gridId + "RowDetailsDialog" + rowIndex + "'><ul class='card-columns'>";
		if (columns.length < 21) {
			// don't split into columns for shorter sets of columns.
			content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul>";
		}
		var gridWidth = $('##' + gridId).width();
		var dialogWidth = Math.round(gridWidth/2);
		var pid = datarecord['pid'];
		var transaction_id = datarecord['transaction_id'];
		if (dialogWidth < 150) { dialogWidth = 150; }
		for (i = 1; i < columns.length; i++) {
			var text = columns[i].text;
			var datafield = columns[i].datafield;
			if (datafield == 'accn_number') { 
				if (transaction_id) {
					content = content + "<li><strong>" + text + ":</strong> <a class='btn btn-link btn-xs' href='/transactions/Accession.cfm?action=edit&transaction_id="+transaction_id+"' target='_blank'>Edit</a> "+ datarecord[datafield] + "</li>";
				} else { 
					content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'project_name') { 
				if (pid) {
					content = content + "<li><strong>" + text + ":</strong> <a class='btn btn-link btn-xs' href='/ProjectDetail.cfm?project_id="+pid+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
				} else { 
					content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
				}
			} else if (datafield == 'permits') { 
				permits = datarecord[datafield];
				if (permits.length > 0) { 
					permits = permits.replaceAll('|','</li><li>');
		 			content = content + "<li><strong>Perm. &amp; Rights Docs:</strong><ul><li>" + permits + "</li></ul></li>";
				}
			} else if (datafield == 'id_link') {
				// don't show to user (duplicates accn number)
				console.log(datarecord[datafield]);
			} else if (datafield == 'transaction_id') {
				// don't show to user
				console.log(datarecord[datafield]);
			} else {
				content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
			}
		}
		content = content + "</ul>";
		var transaction_id = datarecord['transaction_id'];
		var accn_number = datarecord['accn_number'];
		content = content + "<a href='/SpecimenResults.cfm?accn_trans_id="+transaction_id+"' class='btn btn-secondary btn-xs' target='_blank'>Specimen List</a>";
		content = content + "<a href='/findContainer.cfm?autosubmit=true&transaction_id="+transaction_id+"' class='btn btn-secondary btn-xs' target='_blank'>Storage Locations</a>";
		content = content + "<a href='/bnhmMaps/bnhmMapData.cfm?accn_number="+accn_number+"' class='btn btn-secondary btn-xs' target='_blank'>Berkeley Mapper</a>";
		content = content + "<a href='/transactions/Accession.cfm?action=edit&transaction_id=" + transaction_id +"' class='btn btn-secondary btn-xs' target='_blank'>Edit Accession</a>";
		content = content + "</div>";
		$("##" + rowDetailsTargetId + rowIndex).html(content);
		$("##"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
			{
				autoOpen: true,
				buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("##" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
				width: dialogWidth,
				title: 'Accession Details'
			}
		);
		// Workaround, expansion sits below row in zindex.
		var maxZIndex = getMaxZIndex();
		$("##"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
	}

	window.columnHiddenSettings = new Object();
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		lookupColumnVisibilities ('/Transactions.cfm?action=#action#','Default');
	</cfif>


$(document).ready(function() {
	/* Setup date time input controls */
	$(".datetimeinput").datepicker({ 
		defaultDate: null,
		changeMonth: true,
		changeYear: true,
		dateFormat: 'yy-mm-dd', /* ISO Date format, yy is 4 digit year */
		buttonImageOnly: true,
		buttonImage: "/shared/images/calendar_icon.png",
		showOn: "button"
	});

	/* Setup jqxgrid for Transactions Search */
	$('##searchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##overlay").show();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##saveDialogButton').html('');
		$('##selectModeContainer').hide();
		$('##actionFeedback').html('');

		var search =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'trans_date', type: 'string' },
				{ name: 'transaction_type', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'specific_number', type: 'string' },
				{ name: 'type', type: 'string' },
				{ name: 'status', type: 'string' },
				{ name: 'shipment_count', type: 'string' },
				{ name: 'foreign_shipments', type: 'string' },
				{ name: 'entered_by', type: 'string' },
				{ name: 'date_entered', type: 'string' },
				{ name: 'authorized_by', type: 'string' },
				{ name: 'outside_authorized_by', type: 'string' },
				{ name: 'received_by', type: 'string' },
				{ name: 'for_use_by', type: 'string' },
				{ name: 'inhouse_contact', type: 'string' },
				{ name: 'additional_inhouse_contact', type: 'string' },
				{ name: 'additional_outside_contact', type: 'string' },
				{ name: 'recipient_institution', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##searchForm').serialize(),
			timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
			loadError: function(jqXHR, textStatus, error) { 
				$("##overlay").hide();
				handleFail(jqXHR,textStatus,error,"running transaction search");
			},
			async: true
		};

		var dataAdapter = new $.jqx.dataAdapter(search);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div id='rowDetailsTarget" + index + "'></div>");

			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}

		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: 50,
			pagesizeoptions: ['5','50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false, // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: '#defaultSelectionMode#',
			enablebrowserselection: #defaultenablebrowserselection#,
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##searchResultsGrid").jqxGrid('selectrow', 0);
			},
			columns: [
				{text: 'Number', datafield: 'specific_number', width:120, hideable: true, hidden: getColHidProp('specific_number', true) },
				{text: 'Transaction', datafield: 'id_link', width: 120},
				{text: 'transactionID', datafield: 'transaction_id', width: 50, hideable: true, hidden: getColHidProp('transaction_id', true) },
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', width: 80, hideable: true, hidden: getColHidProp('collection', true) },
				{text: 'Transaction', datafield: 'transaction_type', width: 150},
				{text: 'Type', datafield: 'type', width: 80},
				{text: 'Date', datafield: 'trans_date', width: 100},
				{text: 'Status', datafield: 'status', width: 100},
				{text: 'Shipments', datafield: 'shipment_count', width: 80, hideable: true, hidden: getColHidProp('shipment_count', true) },
				{text: 'Foreign Shipments', datafield: 'foreign_shipments', width: 80, hideable: true, hidden: getColHidProp('foreign_shipments', true) },
				{text: 'Entered By', datafield: 'entered_by', width: 100, hideable: true, hidden: getColHidProp('entered_by', false) },
				{text: 'Entered Date', datafield: 'date_entered', width: 100, hideable: true, hidden: getColHidProp('date_entered', false) },
				{text: 'Authorized By', datafield: 'authorized_by', width: 80, hideable: true, hidden: getColHidProp('authorized_by', true) },
				{text: 'Outside Authorized By', datafield: 'outside_authorized_by', width: 80, hideable: true, hidden: getColHidProp('outside_authorized_by', true) },
				{text: 'Received By', datafield: 'received_by', width: 80, hideable: true, hidden: getColHidProp('received_by', true) },
				{text: 'For Use By', datafield: 'for_use_by', width: 80, hideable: true, hidden: getColHidProp('for_use_by', true) },
				{text: 'In-house Contact', datafield: 'inhouse_contact', width: 80, hideable: true, hidden: getColHidProp('inhouse_contact', true) },
				{text: 'Additional In-house Contact', datafield: 'additional_inhouse_contact', width: 80, hideable: true, hidden: getColHidProp('additional_inhouse_contact', true) },
				{text: 'Additional Outside Contact', datafield: 'additional_outside_contact', width: 80, hideable: true, hidden: getColHidProp('additional_outside_contact', true) },
				{text: 'Recipient Institution', datafield: 'recipient_institution', width: 80, hideable: true, hidden: getColHidProp('recipient_institution', true) },
				{text: 'Nature of Material', datafield: 'nature_of_material', width: 130, hideable:true, hidden: getColHidProp('nature_of_material', true) },
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: getColHidProp('trans_remarks', false) }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1 // row details will be placed in popup dialog
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findAll&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','transaction');
		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			// Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##searchResultsGrid').on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});

	});
	/* End Setup jqxgrid for Transactions Search ******************************/


	/* Supporting cell renderers for Loan Search *****************************/
	var dueDateCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var daysdue = rowData['dueindays'];
		var loanstatus = rowData['loan_status'];
		if (daysdue < 0 && loanstatus != 'closed') {
			result = '<span class="text-danger #cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><strong>'+value+'</strong></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};
	var projectCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var pid = rowData['pid'];
		if (pid) {
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/ProjectDetail.cfm?project_id='+pid+'" target="_blank">'+value+'</a></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};
	var itemCountCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var transaction_id = rowData['transaction_id'];
		if (value != "0") {
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/SpecimenResults.cfm?loan_trans_id='+transaction_id+'" target="_blank">'+value+'</a></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};
	var ciationCountCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var transaction_id = rowData['transaction_id'];
		if (value != "0") {
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/SpecimenResults.cfm?type_status=any&loan_trans_id='+transaction_id+'" target="_blank">'+value+'</a></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};
	var overdueCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var daysoverdue = -value;
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var loanstatus = rowData['loan_status'];
		if (daysoverdue > 0 && loanstatus != 'closed') {
			var overdue = "";
			if (daysoverdue > 731) { 
				overdue = Math.round(daysoverdue/365.25) + " years";
			} else if (daysoverdue > 365) { 
				overdue = Math.round(daysoverdue/30.44) + " months";
 			} else {
				overdue = daysoverdue + " days";
			} 
			result = '<span class="text-danger #cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><strong>Overdue '+overdue+'</strong></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};


	/* Setup jqxgrid for Loan Search ******************************************/
	$('##loanSearchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##overlay").show();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##saveDialogButton').html('');
		$('##selectModeContainer').hide();
		$('##actionFeedback').html('');

		var loanSearch =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'trans_date', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'loan_number', type: 'string' },
				{ name: 'loan_type', type: 'string' },
				{ name: 'loan_type_scope', type: 'string' },
				{ name: 'loan_status', type: 'string' },
				{ name: 'shipment_count', type: 'string' },
				{ name: 'foreign_shipments', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'loan_instructions', type: 'string' },
				{ name: 'loan_description', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'return_due_date', type: 'string' },
				{ name: 'dueindays', type: 'string' },
				{ name: 'closed_date', type: 'string' },
				{ name: 'auth_agent', type: 'string' },
				{ name: 'ent_agent', type: 'string' },
				{ name: 'rec_agent', type: 'string' },
				{ name: 'foruseby_agent', type: 'string' },
				{ name: 'inHouse_agent', type: 'string' },
				{ name: 'addInhouse_agent', type: 'string' },
				{ name: 'addOutside_agent', type: 'string' },
				{ name: 'recip_inst', type: 'string' },
				{ name: 'project_name', type: 'string' },
				{ name: 'pid', type: 'string' },
				{ name: 'item_count', type: 'string' },
				{ name: 'citation_count', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##loanSearchForm').serialize(),
			timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
			loadError: function(jqXHR, textStatus, error) { 
				$("##overlay").hide();
				handleFail(jqXHR,textStatus,error,"running loan search");
			},
			async: true
		};
		var loanDataAdapter = new $.jqx.dataAdapter(loanSearch);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div tabindex='0' role='button' id='rowDetailsTarget" + index + "'></div>");

			createLoanRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}
		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: loanDataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: 50,
			pagesizeoptions: ['5','50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false, // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: '#defaultSelectionMode#',
			enablebrowserselection: #defaultenablebrowserselection#,
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##searchResultsGrid").jqxGrid('selectrow', 0);
			},
			columns: [
				{text: 'Loan Number', datafield: 'loan_number', width: 120, hideable: true, hidden: getColHidProp('loan_number', true) },
				{text: 'Loan', datafield: 'id_link', width: 120}, // datafield name referenced in createLoanRowDetaisDialog
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', hideable: true, hidden: getColHidProp('collection', true) },
				{text: 'Loan Items', datafield: 'item_count', width: 100, hideable: true, hidden: getColHidProp('item_count', true), cellsrenderer: itemCountCellRenderer },
				{text: 'Citation Count', datafield: 'citation_count', width: 110, hideable: true, hidden: getColHidProp('citation_count', true), cellsrenderer: ciationCountCellRenderer },
				{text: 'Type', datafield: 'loan_type', width: 100},
				{text: 'Status', datafield: 'loan_status', width: 100},
				{text: 'Date', datafield: 'trans_date', width: 100},
				{text: 'Due Date', datafield: 'return_due_date', width: 100, cellsrenderer: dueDateCellRenderer}, // datafield name referenced in createLoanRowDetailsDialog
				{text: 'Due in (days)', datafield: 'dueindays', hideable: true, hidden: getColHidProp('dueindays', true), cellsrenderer: overdueCellRenderer }, // datafield name referenced in row details dialog
				{text: 'Closed', datafield: 'closed_date', width: 100},
				{text: 'To', datafield: 'rec_agent', width: 100},
				{text: 'Recipient', datafield: 'recip_inst', width: 100},
				{text: 'Authorized By', datafield: 'auth_agent', hideable: true, hidden: getColHidProp('auth_agent', true) },
				{text: 'For Use By', datafield: 'foruseby_agent', hideable: true, hidden: getColHidProp('foruseby_agent', true) },
				{text: 'In-house contact', datafield: 'inHouse_agent', hideable: true, hidden: getColHidProp('inHouse_agent', true) },
				{text: 'Additional in-house contact', datafield: 'addInhouse_agent', hideable: true, hidden: getColHidProp('addInhouse_agen', true) },
				{text: 'Additional outside contact', datafield: 'addOutside_agent', hideable: true, hidden: getColHidProp('addOutside_agent', true) },
				{text: 'Entered By', datafield: 'ent_agent', width: 100},
				{text: 'Shipments', datafield: 'shipment_count', width:  80, hideable: true, hidden: getColHidProp('shipment_count', true) },
				{text: 'Foreign Shipments', datafield: 'foreign_shipments',  width: 80, hideable: true, hidden: getColHidProp('foreign_shipments', true) },
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: getColHidProp('trans_remarks', true) },
				{text: 'Scope', datafield: 'loan_type_scope', hideable: true, hidden: getColHidProp('loan_type_scope', true) },
				{text: 'Instructions', datafield: 'loan_instructions', hideable: true, hidden: getColHidProp('loan_instructions', true) },
				{text: 'Description', datafield: 'loan_description', hideable: true, hidden: getColHidProp('loan_description', true) },
				{text: 'Project', datafield: 'project_name', hideable: true, hidden: getColHidProp('project_name', true), cellsrenderer: projectCellRenderer }, // datafield name referenced in row details dialog
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: getColHidProp('transaction_id', true) }, // datafield name referenced in createLoanRowDetailsDialog
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: getColHidProp('nature_of_material', false) }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findLoans&execute=true&' + $('##loanSearchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','loan');
		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			// Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createLoanRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##searchResultsGrid').on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});

	});
	/* End Setup jqxgrid for Loan Search ******************************/


	/* Supporting cell renderers for Accession Search *****************************/
	var catitemsCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var transaction_id = rowData['transaction_id'];
		if (value > 0) {
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/SpecimenResults.cfm?accn_trans_id='+transaction_id+'" target="_blank">'+value+'</a></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};


	/* Setup jqxgrid for Accession Search ******************************************/
	$('##accnSearchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##overlay").show();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##saveDialogButton').html('');
		$('##selectModeContainer').hide();
		$('##actionFeedback').html('');

		var accnSearch =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'date_entered', type: 'string' },
				{ name: 'accession_date', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'accn_number', type: 'string' },
				{ name: 'accn_type', type: 'string' },
				{ name: 'received_date', type: 'string' },
				{ name: 'accn_status', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'estimated_count', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'auth_agent', type: 'string' },
				{ name: 'outside_auth_agent', type: 'string' },
				{ name: 'ent_agent', type: 'string' },
				{ name: 'rec_from_agent', type: 'string' },
				{ name: 'rec_agent', type: 'string' },
				{ name: 'inHouse_agent', type: 'string' },
				{ name: 'addInhouse_agent', type: 'string' },
				{ name: 'outside_agent', type: 'string' },
				{ name: 'addOutside_agent', type: 'string' },
				{ name: 'permits', type: 'int' },
				{ name: 'item_count', type: 'int' },
				{ name: 'shipment_count', type: 'string' },
				{ name: 'foreign_shipments', type: 'string' },
				{ name: 'project_name', type: 'string' },
				{ name: 'pid', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'accnRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##accnSearchForm').serialize(),
			timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
			loadError: function(jqXHR, textStatus, error) { 
				$("##overlay").hide();
				handleFail(jqXHR,textStatus,error,"running accession search");
			},
			async: true
		};
		var accnDataAdapter = new $.jqx.dataAdapter(accnSearch);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div tabindex='0' role='button' id='rowDetailsTarget" + index + "'></div>");

			createAccnRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}
		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: accnDataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: 50,
			pagesizeoptions: ['5','50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false, // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: '#defaultSelectionMode#',
			enablebrowserselection: #defaultenablebrowserselection#,
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##searchResultsGrid").jqxGrid('selectrow', 0);
			},
			columns: [
				{text: 'Accn Number', datafield: 'accn_number', width: 120, hideable: true, hidden: getColHidProp('accn_number', true) },
				{text: 'Accession', datafield: 'id_link', width: 100}, // datafield name referenced in createLoanRowDetaisDialog
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', hideable: true, hidden: getColHidProp('collection', true) },
				{text: 'Shipments', datafield: 'shipment_count', width: 80, hideable: true, hidden: getColHidProp('shipment_count', true) },
				{text: 'Foreign Shipments', datafield: 'foreign_shipments', width: 80, hideable: true, hidden: getColHidProp('foreign_shipment', true) },
				{text: 'Cat. Items', datafield: 'item_count', hideable: true, hidden: getColHidProp('item_count', false), width: 90, cellsrenderer: catitemsCellRenderer },
				{text: 'Est. Count', datafield: 'estimated_count', hideable: true, hidden: getColHidProp('estimated_count', false), width: 90 },
				{text: 'Type', datafield: 'accn_type', hidable: true, hidden: getColHidProp('accn_type', false), width: 100},
				{text: 'Status', datafield: 'accn_status', hideable: true, hidden: getColHidProp('accn_status', false), width: 100},
				{text: 'Entered Date', datafield: 'date_entered', width: 100, hidable: true, hidden: getColHidProp('date_entered', true) },
				{text: 'Accn. Date', datafield: 'accession_date', width: 100, hidable: true, hidden: getColHidProp('date_entered', true) },
				{text: 'Received Date', datafield: 'received_date', width: 100, hideable: true, hidden: getColHidProp('received_date', false) },
				{text: 'Received From', datafield: 'rec_from_agent', width: 100, hidable: true, hidden: getColHidProp('rec_from_agent', false) },
				{text: 'outside contact', datafield: 'outside_agent', hideable: true, hidden: getColHidProp('outside_agent', true) },
				{text: 'Received By', datafield: 'rec_agent', width: 100, hidable: true, hidden: getColHidProp('rec_agent', true) },
				{text: 'Authorized By', datafield: 'auth_agent', hideable: true, hidden: getColHidProp('auth_agent', true) },
				{text: 'Outside Authorized By', datafield: 'outside_auth_agent', hideable: true, hidden: getColHidProp('outside_auth_agnent', true) },
				{text: 'In-house contact', datafield: 'inHouse_agent', hideable: true, hidden: getColHidProp('inHouse_agent', true) },
				{text: 'Additional in-house contact', datafield: 'addInhouse_agent', hideable: true, hidden: getColHidProp('addInhouse_agent', true) },
				{text: 'Additional outside contact', datafield: 'addOutside_agent', hideable: true, hidden: getColHidProp('addOutside_agent', true) },
				{text: 'Entered By', datafield: 'ent_agent', width: 100},
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: getColHidProp('trans_remarks', true) },
				{text: 'PandRDocs', datafield: 'permits', hideable: true, hidden: getColHidProp('permits', true) }, // datafield name referenced in row details dialog
				{text: 'Project', datafield: 'project_name', hideable: true, hidden: getColHidProp('project_name', true), cellsrenderer: projectCellRenderer }, // datafield name referenced in row details dialog
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: getColHidProp('transaction_id', true) }, // datafield name referenced in createLoanRowDetailsDialog
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: getColHidProp('nature_of_material', false) }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findAccessions&execute=true&' + $('##accnSearchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','accn');


		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			// Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createAccnRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##searchResultsGrid').on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});

	});

	/* Supporting cell renderers for Deaccession Search *****************************/
	var catitemsDeaccCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var result = "";
		var transaction_id = rowData['transaction_id'];
		if (value > 0) {
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/a_deaccItemReview.cfm?transaction_id='+transaction_id+'" target="_blank">'+value+'</a></span>';
		} else { 
			result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
		return result;
	};
	/* Setup jqxgrid for Deccession Search ******************************************/
	$('##deaccnSearchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##overlay").show();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##saveDialogButton').html('');
		$('##selectModeContainer').hide();
		$('##actionFeedback').html('');

		var deaccessionSearch =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'date_entered', type: 'string' },
				{ name: 'deaccession_date', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'deacc_remarks', type: 'string' },
				{ name: 'deacc_number', type: 'string' },
				{ name: 'deacc_type', type: 'string' },
				{ name: 'deacc_status', type: 'string' },
				{ name: 'deacc_reason', type: 'string' },
				{ name: 'method', type: 'string' },
				{ name: 'value', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'auth_agent', type: 'string' },
				{ name: 'ent_agent', type: 'string' },
				{ name: 'recipient_institution_agent', type: 'string' },
				{ name: 'rec_agent', type: 'string' },
				{ name: 'inHouse_agent', type: 'string' },
				{ name: 'addInhouse_agent', type: 'string' },
				{ name: 'outside_agent', type: 'string' },
				{ name: 'addOutside_agent', type: 'string' },
				{ name: 'permits', type: 'int' },
				{ name: 'item_count', type: 'int' },
				{ name: 'shipment_count', type: 'string' },
				{ name: 'foreign_shipments', type: 'string' },
				{ name: 'project_name', type: 'string' },
				{ name: 'pid', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'deaccessionRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##deaccnSearchForm').serialize(),
			timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
			loadError: function(jqXHR, textStatus, error) { 
				$("##overlay").hide();
				handleFail(jqXHR,textStatus,error,"running deaccession search");
			},
			async: true
		};
		var deaccDataAdapter = new $.jqx.dataAdapter(deaccessionSearch);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div tabindex='0' role='button' id='rowDetailsTarget" + index + "'></div>");

			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}
		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: deaccDataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: 50,
			pagesizeoptions: ['5','50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false, // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: '#defaultSelectionMode#',
			enablebrowserselection: #defaultenablebrowserselection#,
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##searchResultsGrid").jqxGrid('selectrow', 0);
			},
			columns: [
				{text: 'Deacc Number', datafield: 'deacc_number', width: 120, hideable: true, hidden: getColHidProp('deacc_number', true) },
				{text: 'Deaccession', datafield: 'id_link', width: 120}, // datafield name referenced in createDeaccRowDetaisDialog
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', hideable: true, hidden: getColHidProp('collection', true) },
				{text: 'Shipments', datafield: 'shipment_count', width: 80, hideable: true, hidden: getColHidProp('shipment_count', true) },
				{text: 'Foreign Shipments', datafield: 'foreign_shipments', width: 80, hideable: true, hidden: getColHidProp('foreign_shipments', true) },
				{text: 'Cat. Items', datafield: 'item_count', hideable: true, hidden: getColHidProp('item_count', false), width: 90, cellsrenderer: catitemsDeaccCellRenderer},
				{text: 'Type', datafield: 'deacc_type', hidable: true, hidden: getColHidProp('deacc_type', false), width: 100},
				{text: 'Status', datafield: 'deacc_status', hideable: true, hidden: getColHidProp('deacc_status', false), width: 90},
				{text: 'Deaccession Reason', datafield: 'deacc_reason', hideable: true, hidden: getColHidProp('deacc_reason', true), width: 150},
				{text: 'Method of Transfer', datafield: 'method', hideable: true, hidden: getColHidProp('method', true), width: 90},
				{text: 'Value', datafield: 'value', hideable: true, hidden: getColHidProp('value', true), width: 90},
				{text: 'Entered Date', datafield: 'date_entered', width: 100, hidable: true, hidden: getColHidProp('date_entered', true) },
				{text: 'Deaccession Date', datafield: 'deaccession_date', width: 100, hidable: true, hidden: getColHidProp('deaccession_date', true) },
				{text: 'Recipient Institution', datafield: 'recipient_institution_agent', width: 100, hidable: true, hidden: getColHidProp('recipient_institution_agent', false) },
				{text: 'outside contact', datafield: 'outside_agent', hideable: true, hidden: getColHidProp('outside_agent', true) },
				{text: 'Received By', datafield: 'rec_agent', width: 100, hidable: true, hidden: getColHidProp('rec_agent', true) },
				{text: 'Authorized By', datafield: 'auth_agent', hideable: true, hidden: getColHidProp('auth_agent', true) },
				{text: 'In-house contact', datafield: 'inHouse_agent', hideable: true, hidden: getColHidProp('inHouse_agent', true) },
				{text: 'Additional in-house contact', datafield: 'addInhouse_agent', hideable: true, hidden: getColHidProp('addInhouse_agent', true) },
				{text: 'Additional outside contact', datafield: 'addOutside_agent', hideable: true, hidden: getColHidProp('addOutside_agent', true) },
				{text: 'Entered By', datafield: 'ent_agent', width: 100},
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: getColHidProp('trans_remarks', true) },
				{text: 'Deaccession Remarks', datafield: 'deacc_remarks', hideable: true, hidden: getColHidProp('deacc_remarks', true)},
				{text: 'PandRDocs', datafield: 'permits', hideable: true, hidden: getColHidProp('permits', true) }, // datafield name referenced in row details dialog
				{text: 'Project', datafield: 'project_name', hideable: true, hidden: getColHidProp('project_name', true), cellsrenderer: projectCellRenderer }, // datafield name referenced in row details dialog
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: getColHidProp('transaction_id', true) }, // datafield name referenced in createLoanRowDetailsDialog
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: getColHidProp('nature_of_material', false) }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findDeaccessions&execute=true&' + $('##deaccnSearchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','deacc');

		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			// Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##searchResultsGrid').on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});
	});

	/* Supporting cell renderers for Borrow Search *****************************/
	var trueYesCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var v = String(value);
		if (v.toUpperCase().trim()=='TRUE') { v = 'Yes'; }
		if (v.toUpperCase().trim()=='FALSE') { v = 'No'; }
		if (v.toUpperCase().trim()=='YES') { 
			color = 'text-success'; 
			bg = '';
		} else { 
			color = 'text-danger font-weight-bold'; 
			bg = ''; 
		} 
		return '<span class="#cellRenderClasses# '+bg+'" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><span class="'+color+'">'+v+'</span></span>';
	};
	var returnAckCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var borrowstatus = rowData['borrow_status'];
		var v = String(value);
		if (v.toUpperCase().trim()=='TRUE') { v = 'Yes'; }
		if (v.toUpperCase().trim()=='FALSE') { v = 'No'; }
		if (v.toUpperCase().trim()=='YES') { 
			color = 'text-success'; 
			bg = '';
		} else { 
			if(borrowstatus.toUpperCase().trim()=='RETURNED') { 
				color = 'text-danger font-weight-bold'; 
			} else {
				color = 'text-dark'; 
			}
			bg = ''; 
		} 
		return '<span class="#cellRenderClasses# '+bg+'" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><span class="'+color+'">'+v+'</span></span>';
	};
	/* Setup jqxgrid for borrow Search ******************************************/
	$('##borrowSearchForm').bind('submit', function(evt){
		evt.preventDefault();
		$("##overlay").show();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##saveDialogButton').html('');
		$('##selectModeContainer').hide();
		$('##actionFeedback').html('');

		var borrowSearch =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'date_entered', type: 'string' },
				{ name: 'borrow_date', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'borrow_number', type: 'string' },
				{ name: 'lender_loan_type', type: 'string' },
				{ name: 'lenders_trans_num_cde', type: 'string' },
				{ name: 'lenders_invoice_returned', type: 'string' },
				{ name: 'lenders_instructions', type: 'string' },
				{ name: 'due_date', type: 'string' },
				{ name: 'received_date', type: 'string' },
				{ name: 'return_acknowledged_date', type: 'string' },
				{ name: 'lenders_loan_date', type: 'string' },
				{ name: 'borrow_status', type: 'string' },
				{ name: 'no_of_specimens', type: 'string' },
				{ name: 'ret_acknowledged_by', type: 'string' },
				{ name: 'description_of_borrow', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'auth_agent', type: 'string' },
				{ name: 'outside_auth_agent', type: 'string' },
				{ name: 'ent_agent', type: 'string' },
				{ name: 'borrowoverseenby_agent', type: 'string' },
				{ name: 'foruseby_agent', type: 'string' },
				{ name: 'lending_institution_agent', type: 'string' },
				{ name: 'rec_agent', type: 'string' },
				{ name: 'recfrom_agent', type: 'string' },
				{ name: 'inHouse_agent', type: 'string' },
				{ name: 'addInhouse_agent', type: 'string' },
				{ name: 'outside_agent', type: 'string' },
				{ name: 'addOutside_agent', type: 'string' },
				{ name: 'permits', type: 'int' },
				{ name: 'item_count', type: 'int' },
				{ name: 'shipment_count', type: 'string' },
				{ name: 'foreign_shipments', type: 'string' },
				{ name: 'project_name', type: 'string' },
				{ name: 'pid', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'borrowRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##borrowSearchForm').serialize(),
			timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
			loadError: function(jqXHR, textStatus, error) { 
				$("##overlay").hide();
				handleFail(jqXHR,textStatus,error,"running borrow search");
			},
			async: true
		};
		var borrowDataAdapter = new $.jqx.dataAdapter(borrowSearch);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div tabindex='0' role='button' id='rowDetailsTarget" + index + "'></div>");

			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}
		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: borrowDataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: 50,
			pagesizeoptions: ['5','50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false, // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: '#defaultSelectionMode#',
			enablebrowserselection: #defaultenablebrowserselection#,
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##searchResultsGrid").jqxGrid('selectrow', 0);
			},
			columns: [
				{text: 'Borrow Number', datafield: 'borrow_number', width: 120, hideable: true, hidden: getColHidProp('borrow_number', true) },
				{text: 'Borrow', datafield: 'id_link', width: 120}, // datafield name referenced in createDeaccRowDetaisDialog
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', hideable: true, hidden: getColHidProp('collection', true) },
				{text: 'Shipments', datafield: 'shipment_count', width: 80, hideable: true, hidden: getColHidProp('shipment_count', true) },
				{text: 'Foreign Shipments', datafield: 'foreign_shipments', width: 80, hideable: true, hidden: getColHidProp('foreign_shipments', true) },
				{text: 'Item Count', datafield: 'item_count', hideable: true, hidden: getColHidProp('item_count', false), width: 90 },
				{text: 'No. of Spec.', datafield: 'no_of_specimens', hideable: true, hidden: getColHidProp('no_of_specimens', false), width: 90 },
				{text: 'Lender Loan Type', datafield: 'lender_loan_type', hidable: true, hidden: getColHidProp('lender_loan_type', true), width: 100},
				{text: 'Lender Loan Num.', datafield: 'lenders_trans_num_cde', hidable: true, hidden: getColHidProp('lenders_trans_num_cde', false), width: 110},
				{text: 'Status', datafield: 'borrow_status', hideable: true, hidden: getColHidProp('borrow_status', false), width: 90},
				{text: 'Entered Date', datafield: 'date_entered', width: 100, hidable: true, hidden: getColHidProp('date_entered', true) },
				{text: 'Borrow Date', datafield: 'borrow_date', width: 100, hidable: true, hidden: getColHidProp('borrow_date', true) },
				{text: 'Loan Date', datafield: 'lenders_loan_date', width: 100, hideable: true, hidden: getColHidProp('lenders_loan_date', false) },
				{text: 'Received Date', datafield: 'received_date', width: 100, hideable: true, hidden: getColHidProp('received_date', true) },
				{text: 'Due Date', datafield: 'due_date', width: 100, hideable: true, hidden: getColHidProp('due_date', false) },
				{text: 'Return Acknowedged', datafield: 'lenders_invoice_returned', width: 80, hideable: true, hidden: getColHidProp('lenders_invoice_returned', false), cellsrenderer: returnAckCellRenderer },
				{text: 'Return Ack. Date', datafield: 'return_acknowledged_date', width: 100, hideable: true, hidden: getColHidProp('return_acknowledged_date', false) },
				{text: 'Ret. Ack. By', datafield: 'ret_acknowleded_by', hideable: true, hidden: getColHidProp('ret_acknowledged_by', true), width: 150},
				{text: 'Loaning Institution', datafield: 'lending_institution_agent', width: 150, hidable: true, hidden: getColHidProp('lending_institution_agent', false) },
				{text: 'Outside contact', datafield: 'outside_agent', hideable: true, hidden: getColHidProp('outside_agent', true) },
				{text: 'Received By', datafield: 'rec_agent', width: 100, hidable: true, hidden: getColHidProp('rec_agent', false) },
				{text: 'Overseen By', datafield: 'borrowoverseenby_agent', width: 100, hidable: true, hidden: getColHidProp('borrowoverseenby_agent', false) },
				{text: 'For Use By', datafield: 'foruseby_agent', width: 100, hidable: true, hidden: getColHidProp('foruseby_agent', false) },
				{text: 'Received From', datafield: 'recfrom_agent', width: 100, hidable: true, hidden: getColHidProp('recfrom_agent', true) },
				{text: 'Authorized By', datafield: 'auth_agent', hideable: true, hidden: getColHidProp('auth_agent', true) },
				{text: 'Outside Authorized By', datafield: 'outside_auth_agent', hideable: true, hidden: getColHidProp('outside_auth_agent', true) },
				{text: 'In-house contact', datafield: 'inHouse_agent', hideable: true, hidden: getColHidProp('inHouse_agent', true) },
				{text: 'Additional in-house contact', datafield: 'addInhouse_agent', hideable: true, hidden: getColHidProp('addInhouse_agent', true) },
				{text: 'Additional outside contact', datafield: 'addOutside_agent', hideable: true, hidden: getColHidProp('addOutside_agent', true) },
				{text: 'Entered By', datafield: 'ent_agent', hideable: true, hidden: getColHidProp('ent_agent', false), width: 100 },
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: getColHidProp('trans_remarks', true) },
				{text: 'Instructions', datafield: 'lenders_instructions', hideable: true, hidden: getColHidProp('lenders_instructions', false), width: 120 },
				{text: 'Description', datafield: 'description_of_borrow', hideable: true, hidden: getColHidProp('description_of_borrow', true)},
				{text: 'PandRDocs', datafield: 'permits', hideable: true, hidden: getColHidProp('permits', true) }, // datafield name referenced in row details dialog
				{text: 'Project', datafield: 'project_name', hideable: true, hidden: getColHidProp('project_name', true), cellsrenderer: projectCellRenderer }, // datafield name referenced in row details dialog
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: getColHidProp('transaction_id', true) }, // datafield name referenced in createLoanRowDetailsDialog
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: getColHidProp('nature_of_material', false) }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findBorrows&execute=true&' + $('##borrowSearchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','borrow');

		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			// Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##searchResultsGrid').on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});
	});

	// If requested in uri, execute search immediately.
	<cfif isdefined("execute")>
		<cfswitch expression="#execute#">
			<cfcase value="accn">
				$('##accnSearchForm').submit();
			</cfcase>
			<cfcase value="loan">
				$('##loanSearchForm').submit();
			</cfcase>
			<cfcase value="deaccession">
				$('##deaccnSearchForm').submit();
			</cfcase>
			<cfcase value="borrow">
				$('##borrowSearchForm').submit();
			</cfcase>
			<cfcase value="all">
				$('##searchForm').submit();
			</cfcase>
		</cfswitch>
	</cfif>

});

function populateSaveSearch(targetAction) { 
	// set up a dialog for saving the current search.
	var targetForm = "searchForm";
	if (targetAction=="findLoans") { targetForm = "loanSearchForm"; };
	if (targetAction=="findBorrows") { targetForm = "borrowSearchForm"; };
	if (targetAction=="findAccessions") { targetForm = "accnSearchForm"; };
	if (targetAction=="findDeaccessions") { targetForm = "deaccnSearchForm"; };

	var uri = "/Transactions.cfm?execute=true&action=" + targetAction + "&" + $("##"+targetForm+" :input").filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
	$("##saveDialog").html(
		"<div class='row'>"+ 
		"<form id='saveForm'> " + 
		" <input type='hidden' value='"+uri+"' name='url'>" + 
		" <div class='col-12'>" + 
		"  <label for='search_name_input'>Search Name</label>" + 
		"  <input type='text' id='search_name_input'  name='search_name' value='' class='data-entry-input reqdClr' placeholder='Your name for this search' maxlength='60' required>" + 
		" </div>" + 
		" <div class='col-12'>" + 
		"  <label for='execute_input'>Execute Immediately</label>"+
		"  <input id='execute_input' type='checkbox' name='execute' checked>"+
		" </div>" +
		"</form>"+
		"</div>"
	);
}

function gridLoaded(gridId, searchType) { 
	var targetAction = "findAll"
	if (searchType == "transaction") { targetAction = "findAll"; }
	if (searchType == "loan") { targetAction = "findLoans"; }
	if (searchType == "accn") { targetAction = "findAccessions"; }
	if (searchType == "deacc") { targetAction = "findDeaccessions"; }
	if (searchType == "borrow") { targetAction = "findBorrows"; }
	if (Object.keys(window.columnHiddenSettings).length == 0) { 
		window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			saveColumnVisibilities('/Transactions.cfm?action=' + targetAction,window.columnHiddenSettings,'Default');
		</cfif>
	}
	$("##overlay").hide();
	var now = new Date();
	var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
	var filename = searchType + '_results_' + nowstring + '.csv';
	// display the number of rows found
	var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
	var rowcount = datainformation.rowscount;
	var items = "";
	// TODO: Find number of objects in results, display link to those through specimen search: 
	if (searchType == 'accn') { 
		item_summary = $('##' + gridId).jqxGrid('getcolumnaggregateddata', 'item_count', ['sum','count','min','max','avg','stdev']);
		if (item_summary['sum']==1){ 
			items = ' ' + item_summary['sum'] + ' cataloged_item';
		} else {
			items = ' ' + item_summary['sum'] + ' cataloged_items';
		}
		// TODO: e.g. "View 13769 items in these 5 Accessions" https://mczbase-test.rc.fas.harvard.edu/SpecimenResults.cfm?accn_trans_id=497052,497061,497072,497073,497177 invocation of accn_trans_id search on specimens in accession search results found on current editAccn.cfm search results list.
		// /Specimens.cfm?accn_number={list of numbers}&execute=true&action=fixedSearch
		// $('##specimensLink').html('<a href="/Specimens.cfm?action=fixedSearch&execute=true&accn_number='+ +'">View ' + items +  ' in these '+ rowcount + 'Accessions</a>');
	}
	if (searchType == 'deacc') { 
		item_summary = $('##' + gridId).jqxGrid('getcolumnaggregateddata', 'item_count', ['sum','count','min','max','avg','stdev']);
		if (item_summary['sum']==1){ 
			items = ' ' + item_summary['sum'] + ' cataloged_item';
		} else {
			items = ' ' + item_summary['sum'] + ' cataloged_items';
		}
	}
	if (rowcount == 1) {
		$('##resultCount').html('Found ' + rowcount + ' ' + searchType + items);
	} else { 
		$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's' + items);
	}
	// set maximum page size
	if (rowcount > 100) { 
		$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount], pagesize: 50});
	} else if (rowcount > 50) { 
		$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount], pagesize: 50});
	} else { 
		$('##' + gridId).jqxGrid({ pageable: false });
	}
	// add a control to show/hide columns
	var columns = $('##' + gridId).jqxGrid('columns').records;
	var columnListSource = [];
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		var hideable = columns[i].hideable;
		var hidden = columns[i].hidden;
		var show = ! hidden;
		if (hideable == true) { 
			var listRow = { label: text, value: datafield, checked: show };
			columnListSource.push(listRow);
		}
	} 
	$("##columnPick").jqxListBox({ source: columnListSource, autoHeight: true, width: '260px', checkboxes: true });
	$("##columnPick").on('checkChange', function (event) {
		$("##" + gridId).jqxGrid('beginupdate');
		if (event.args.checked) {
			$("##" + gridId).jqxGrid('showcolumn', event.args.value);
		} else {
			$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
		}
		$("##" + gridId).jqxGrid('endupdate');
	});
	$("##columnPickDialog").dialog({ 
		height: 'auto', 
		title: 'Show/Hide Columns',
		autoOpen: false,
		modal: true, 
		reszable: true, 
		buttons: { 
			Ok: function(){ 
				window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					saveColumnVisibilities('/Transactions.cfm?action='+targetAction,window.columnHiddenSettings,'Default');
				</cfif>
				$(this).dialog("close");
			 }
		},
		open: function (event, ui) { 
			var maxZIndex = getMaxZIndex();
			// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
			$('.ui-dialog').css({'z-index': maxZIndex + 4 });
			$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
		} 
	});
	$("##columnPickDialogButton").html(
		"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-xs btn-secondary px-2 my-2 mx-1' >Show/Hide Columns</button>"
	);
	$("##saveDialog").dialog({
		height: 'auto',
		width: 'auto',
		adaptivewidth: true,
		title: 'Save Search',
		autoOpen: false,
		modal: true,
		reszable: true,
		buttons: [
			{
				text: "Save",
				click: function(){
					var url = $('##saveForm :input[name=url]').val();
					var execute = $('##saveForm :input[name=execute]').is(':checked');
					var search_name = $('##saveForm :input[name=search_name]').val();
					saveSearch(url, execute, search_name,"actionFeedback");
					$(this).dialog("close"); 
				},
				tabindex: 0
			},
			{
				text: "Cancel",
				click: function(){ 
					$(this).dialog("close"); 
				},
				tabindex: 0
			}
		],
		open: function (event, ui) {
			var maxZIndex = getMaxZIndex();
			// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
			$('.ui-dialog').css({'z-index': maxZIndex + 4 });
			$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
		}
	});
	$("##saveDialogButton").html(
	`<button id="`+gridId+`saveDialogOpener"
			onclick=" populateSaveSearch('`+targetAction+`'); $('##saveDialog').dialog('open'); " 
			class="btn btn-xs btn-secondary mx-1 my-2 px-2" >Save Search</button>
	`);
	// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
	// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
	var maxZIndex = getMaxZIndex();
	$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
	$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
	$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
	$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
	$('##selectModeContainer').show();
	changeSelectMode();
}

	</script> 
	<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
		<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
			<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
			<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>	
		</div>
	</div>	
	</div><!--- overlaycontainer --->
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
