<cfinclude template="/includes/_pickHeader.cfm">
<!------------------------------------------------------------------->

<cfif #Action# is "itemLabels">
<!---
For this action:
Author: Peter DeVore, based on work by Dusty
Email: pdevore@berkeley.edu
Extended by Paul J. Morris, mole@morris.net for MCZbase.

Description:
	Used to make printable labels for specimens from Loan page.
	Malacology format is for drawer tags to place in trays of specimens
	that are on loan, and follows the MCZ Malacology small box size.
Parameters:
	transaction_id
	format
--->
<cfoutput>
<p>
	<a href="/temp/loaninvoice_#cookie.cfid#_#cookie.cftoken#.pdf" target="_blank">Get the PDF</a>
</p>
<cfparam default="Bird/Mammal" name="format">
<cfif format is "Malacology">
   <cfset displayFormat = "MCZ 1x2 drawer tag">
<cfelseif format is "Malacology2">
   <cfset displayFormat = "Malacology 1x2 with container">
<cfelse>
   <cfset displayFormat = "#format#">
</cfif>
Current format: #displayFormat#<br/>
<form action='MCZDrawerTags.cfm' method="POST">
	<input type='hidden' name='action' value='itemLabels'>
	<input type='hidden' name='transaction_id' value='#transaction_id#'>
Change to: <select name="format">
		<option value="Bird/Mammal">Bird/Mammal</option>
		<option value="Mammalogy">Mammalogy 3"x2" drawer tag</option>
		<option value="Herp">Herp</option>
		<option value="Malacology">MCZ 1"x2" drawer tag</option>
		<option value="Malacology2">Malacology 1"x2" with container</option>
		<!---  <option value="Cryo">Cryogenic Locator List</option>  --->
		<option value="Cryo-Sheet">Cryogenic Spreadsheet</option>
		<option value="Cryo-Sheet-R">Cryogenic Spreadsheet with remarks</option>
		<option value="Storage">Storage Locations</option>
	</select>
	<input type='submit' value='Change Format' />
</form>
</cfoutput>
<cfif format is "Cryo-Sheet" or format is "Cryo-Sheet-R">
	<cfset NOT_SUBSAMPLE = "The Vial, Not A Subsample">
	<cftry>
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT * 
			FROM (
				select
				   cataloged_item.collection_cde,
				   cataloged_item.cat_num,
				   cataloged_item.collection_object_id,
				   identification.scientific_name as sciName,
				   MCZBASE.concatotherid(cataloged_item.collection_object_id) as otherids,
				   c5.barcode as rack,
				   c4.barcode as slot,
				   c3.barcode as box,
				   c2.label as position,
				   c1.barcode as vial,
				   corem.coll_object_remarks as part_remarks,
				   pcorem.coll_object_remarks as sampled_from_part_remarks
				from
					loan_item
					left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
					left join coll_object_remark corem on loan_item.collection_object_id = corem.collection_object_id
					left join coll_object_remark pcorem on specimen_part.sampled_from_obj_id = pcorem.collection_object_id
					left join coll_obj_cont_hist on specimen_part.sampled_from_obj_id = coll_obj_cont_hist.collection_object_id
					left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
					left join identification on cataloged_item.collection_object_id = identification.collection_object_id
					left join MCZBASE.container c  on coll_obj_cont_hist.container_id = c.container_id
					left join MCZBASE.container c1 on c.parent_container_id = c1.container_id
					left join MCZBASE.container c2 on c1.parent_container_id = c2.container_id
					left join MCZBASE.container c3 on c2.parent_container_id = c3.container_id
					left join MCZBASE.container c4 on c3.parent_container_id = c4.container_id
					left join MCZBASE.container c5 on c4.parent_container_id = c5.container_id
				where identification.accepted_id_fg = 1 AND
					coll_obj_cont_hist.current_container_fg = 1 AND
					specimen_part.sampled_from_obj_id is not null AND
					loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				UNION	  
				select
				   cataloged_item.collection_cde,
				   cataloged_item.cat_num,
				   cataloged_item.collection_object_id,
				   identification.scientific_name as sciName,
				   MCZBASE.concatotherid(cataloged_item.collection_object_id) as otherids,
				   c5.barcode as rack,
				   c4.barcode as slot,
				   c3.barcode as box,
				   c2.label as position,
				   c1.barcode as vial,
				   corem.coll_object_remarks as part_remarks,
				   '#NOT_SUBSAMPLE#' sampled_from_part_remarks
				from
					loan_item
					left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
					left join coll_object_remark corem on loan_item.collection_object_id = corem.collection_object_id
					left join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
					left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
					left join identification on cataloged_item.collection_object_id = identification.collection_object_id
					left join MCZBASE.container c  on coll_obj_cont_hist.container_id = c.container_id
					left join MCZBASE.container c1 on c.parent_container_id = c1.container_id
					left join MCZBASE.container c2 on c1.parent_container_id = c2.container_id
					left join MCZBASE.container c3 on c2.parent_container_id = c3.container_id
					left join MCZBASE.container c4 on c3.parent_container_id = c4.container_id
					left join MCZBASE.container c5 on c4.parent_container_id = c5.container_id
				where identification.accepted_id_fg = 1 AND
					coll_obj_cont_hist.current_container_fg = 1 AND
					specimen_part.sampled_from_obj_id is null AND
					loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			)
			ORDER BY 
				rack, slot, box, 
				decode(LENGTH(TRIM(TRANSLATE(position, '0123456789',' '))),null,to_number(position),position), 
				vial, cat_num
		</cfquery>
	<cfcatch>
		<cfoutput>
			<h3>Query Error obtaining item/container records for spreadsheet.</h3>
			<strong>#cfcatch.message#</strong>
			<strong>#cfcatch.detail#</strong>
			<cfif cfcatch.detail contains 'ORA-01722: invalid number'>
				<h3>It is likely that a part is not placed correctly in the container heirarchy, or this report is not applicable to this material.  This report expects that all parts are vials in a position within a box, slot, and rack.</h3>
				<!--- repeat the query, but without the decimal sort --->
		     <cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
      		select
		           cataloged_item.collection_cde,
      		     cataloged_item.cat_num,
		           cataloged_item.collection_object_id,
      		     identification.scientific_name as sciName,
		           MCZBASE.concatotherid(cataloged_item.collection_object_id) as otherids,
		           c5.barcode as rack,
      		     c4.barcode as slot,
		           c3.barcode as box,
      		     c2.label as position,
		           c1.barcode as vial,
      		     corem.coll_object_remarks as part_remarks,
		           pcorem.coll_object_remarks as sampled_from_part_remarks
		      from
      		   loan_item
		            left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
      		      left join coll_object_remark corem on loan_item.collection_object_id = corem.collection_object_id
		            left join coll_object_remark pcorem on specimen_part.sampled_from_obj_id = pcorem.collection_object_id
      		      left join coll_obj_cont_hist on specimen_part.sampled_from_obj_id = coll_obj_cont_hist.collection_object_id
		            left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
      		      left join identification on cataloged_item.collection_object_id = identification.collection_object_id
		            left join MCZBASE.container c  on coll_obj_cont_hist.container_id = c.container_id
      		      left join MCZBASE.container c1 on c.parent_container_id = c1.container_id
		            left join MCZBASE.container c2 on c1.parent_container_id = c2.container_id
      		      left join MCZBASE.container c3 on c2.parent_container_id = c3.container_id
		            left join MCZBASE.container c4 on c3.parent_container_id = c4.container_id
      		      left join MCZBASE.container c5 on c4.parent_container_id = c5.container_id
		      where identification.accepted_id_fg = 1 AND
      		      coll_obj_cont_hist.current_container_fg = 1 AND
            		loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		      ORDER BY c5.barcode, c4.barcode, c3.barcode, c1.barcode, cat_num
		     </cfquery>
				<p>Check for one or more non-numeric position values on the list of parts below</p>
				<ul>
						<li>cat_num rack:slot:box:<strong>position</strong>:vial part_remarks</li>
					<cfloop query="getItems">
						<li>#cat_num# #rack#:#slot#:#box#:<strong>#position#</strong>:#vial# #part_remarks#</li>
					</cfloop>
				</ul>
			</cfif>
		</cfoutput>
	</cfcatch>
	</cftry>
    <cfset maxRow = 28>
    <cfset maxCol = 1>
    <cfset labelWidth = 'width: 1100px;'>
    <cfset orientiation = 'landscape'>
    <cfset textClass = "times12">
    <cfset textHClass = "times12b">
    <cfset dateStyle = "dd mmm<br>yyyy"><!--- " --->
    <cfset dateWidth = "width: 60px;">

	 <cfif format is "Cryo-Sheet-R">
       <cfset numRecordsPerPage = 12>
	 <cfelseif format is "Cryo-Sheet">
       <cfset numRecordsPerPage = 25>
    <cfelse>
       <cfset numRecordsPerPage = maxCol * maxRow>
    </cfif>
    <cfset maxPage = (getItems.recordcount-1) \ numRecordsPerPage + 1>
    <cfset curPage = 1>
    <cfset curRecord = 1>


    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>
    <cfset labelStyle = 'height: 17px; #labelWidth# #labelBorder#'>
    <cfset tableStyle = 'border-width: 1px 1px 1px 1px; border-spacing: 0px; border-style: solid solid solid solid; border-color: black black black black; border-collapse: collapse; '>
    <cfset thStyle = 'style = "	border-width: 1px 1px 1px 1px; border-style: solid; border-color: gray;"'>
    <cfset tdStyle = 'style = "	border-width: 1px 1px 1px 1px; border-style: solid; border-color: gray;"'>
    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="4" border="0"'>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="4" border="0"'>
    <cfset pageHeader='
    <div style="position:static; top:0; left:0; width:100%;">
    	<span style="position:relative; left:0px; top:0px;  width:35%; font-size:10px; font-weight:600;">
    	Page #curPage# of #maxPage#
    	</span>
    </div>
    '>
    <cfset pageFooter = '
    </table>
    '><!--- ' --->

    <!--- Document tags --->
    <cfdocument
    	format="pdf"
    	pagetype="letter"
    	margintop=".25"
    	marginbottom=".25"
    	marginleft=".25"
    	marginright=".25"
    	orientation="#orientiation#"
    	fontembed="yes"
    	filename="#Application.webDirectory#/temp/loaninvoice_#cookie.cfid#_#cookie.cftoken#.pdf"
    	overwrite="yes">
    <cfoutput>
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
    <cfset pageHeader = replace(pageHeader,'Page #curPage-1# of','Page #curPage# of')>
    #pageHeader#
    <table #outerTableParams# style="#tableStyle#" >
    		      <tr>
    		         <th #thStyle#><span class="#textHClass#"><strong>Catalog Number</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Other Numbers</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Freezer Rack</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Rack Slot</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Freezer Box</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Position</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Cryovial</strong></span></th>
						<cfif format is "Cryo-Sheet-R">
    		            <th #thStyle#><span class="#textHClass#"><strong>Part Remarks</strong></span></th>
    		            <th #thStyle#><span class="#textHClass#"><strong>Sampled From Part Remarks</strong></span></th>
						</cfif>
    	 	     </tr>

    <!--- Main loop --->
    <cfloop query="getItems">
    <!--- Data manipulation --->
    <!--- End data manipulation --->

    	<!--- here is where I could insert a div tag so that I could limit the space
    	allotted per item, but make sure that the div tag size is a function or which format is chosen--->
    		      <tr>
    		         <td #tdStyle#><span class="#textClass#">#collection_cde# #cat_num#</span></td>
    		         <td #tdStyle#><span class="#textClass#">#otherids#</span></td>
    		         <td #tdStyle#><span class="#textClass#"><strong>#rack#</strong></span></td>
    		         <td #tdStyle#><span class="#textClass#"><strong>#slot#</strong></span></td>
    		         <td #tdStyle#><span class="#textClass#">#box#</span></td>
    		         <td #tdStyle#><span class="#textClass#"><strong>#position#</strong></span></td>
    		         <td #tdStyle#><span class="#textClass#">
							#vial#
							<cfif sampled_from_part_remarks EQ NOT_SUBSAMPLE>
								(Not a Subsample)
							</cfif>
						</span></td>
						<cfif format is "Cryo-Sheet-R">
    		         	<td #tdStyle#><span class="#textClass#">#part_remarks#</span></td>
    		         	<td #tdStyle#><span class="#textClass#">#sampled_from_part_remarks#</span></td>
						</cfif>
    	 	     </tr>
    	<!--- Page break --->
    	<cfif curRecord mod numRecordsPerPage is 0 AND curRecord lt getItems.recordcount>
    		<cfset curPage = curPage + 1>
    		<!--- end the old table, pagebreak, and begin the new one--->
    		</table><cfdocumentitem type="pagebreak"></cfdocumentitem>
    		<cfset pageHeader = replace(pageHeader,'Page #curPage-1# of','Page #curPage# of')>
    		#pageHeader#
                <table #outerTableParams# style="#tableStyle#" >
    		      <tr>
    		         <th #thStyle#><span class="#textHClass#"><strong>Catalog Number</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Other Numbers</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Freezer Rack</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Rack Slot</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Freezer Box</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Position</strong></span></th>
    		         <th #thStyle#><span class="#textHClass#"><strong>Cryovial</strong></span></th>
						<cfif format is "Cryo-Sheet-R">
    		            <th #thStyle#><span class="#textHClass#"><strong>Part Remarks</strong></span></th>
    		            <th #thStyle#><span class="#textHClass#"><strong>Sampled From Part Remarks</strong></span></th>
						</cfif>
    	 	     </tr>

    	</cfif>
    	<!--- and finish our current record --->
    	<cfset curRecord=#curRecord#+1>
    </cfloop>
    </table>
    </cfoutput>
    </cfdocument>
    <cfinclude template = "../includes/_footer.cfm">

<cfelse>

    <!-- Cases other than Cryo-Sheet -->
    <cfif format is "Cryo">
    <cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
          select
               cataloged_item.collection_cde,
               cataloged_item.cat_num,
               cataloged_item.collection_object_id,
               identification.scientific_name as sciName,
               MCZBASE.concatotherid(cataloged_item.collection_object_id) as otherids,
               c5.barcode || ' (' ||  c5.container_type || ')<BR>&nbsp;&nbsp;&nbsp;' ||
               c4.barcode || ' (' ||  c4.container_type || ')<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' ||
               c3.barcode || ' (' || c3.container_type  || ')<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' ||
               c2.label || ' (' || c2.container_type  || ')<BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' ||
               c1.barcode || ' (' || c1.container_type  || ')'
               as container
          from
             loan_item
                left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
                left join coll_obj_cont_hist on specimen_part.sampled_from_obj_id = coll_obj_cont_hist.collection_object_id
                left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
                left join identification on cataloged_item.collection_object_id = identification.collection_object_id
                left join MCZBASE.container c  on coll_obj_cont_hist.container_id = c.container_id
                left join MCZBASE.container c1 on c.parent_container_id = c1.container_id
                left join MCZBASE.container c2 on c1.parent_container_id = c2.container_id
                left join MCZBASE.container c3 on c2.parent_container_id = c3.container_id
                left join MCZBASE.container c4 on c3.parent_container_id = c4.container_id
                left join MCZBASE.container c5 on c4.parent_container_id = c5.container_id
          where identification.accepted_id_fg = 1 AND
                coll_obj_cont_hist.current_container_fg = 1 AND
    	    		 loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
    	ORDER BY c5.barcode, c4.barcode, c3.barcode, decode(LENGTH(TRIM(TRANSLATE(c2.label, '0123456789',' '))),null,to_number(c2.label),c2.label), c1.barcode, cat_num
    </cfquery>
    <cfelse>
    <cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    	select distinct
    	    cataloged_item.collection_cde,
                MCZBASE.get_storage_parentage(container.container_id) as container,
    		cataloged_item.cat_num,
    		cataloged_item.collection_object_id,
                MCZBASE.get_top_typestatus(cataloged_item.collection_object_id) as typestatus,
    		identification.scientific_name,
    		loan.loan_number,
    		trans.trans_date,
    		preferred_agent_name.agent_name,
	        specimen_part.part_name,
                MCZBASE.GET_PART_PREP(specimen_part.collection_object_id) as part_prep,
                MCZBASE.GET_PARENTCONTAINERLABEL(specimen_part.collection_object_id) as parentcontainer,
                MCZBASE.GET_PART_COUNT_MOD_FOR_PART(specimen_part.collection_object_id) as lot_count_mod,
    		get_taxonomy(cataloged_item.collection_object_id,'family') as family,
    		get_taxonomy(cataloged_item.collection_object_id,'phylum') as phylum,
			Decode(substr(loan_number, instr(loan_number, '-',1, 2)+1),
				'Herp', 'Herpetology Collection',
				'Mamm', 'Mammalogy Collection',
				'IZ', 'Invertebrate Zoology Collection',
				'Mala', 'Malacology Collection',
				'VP','Vertebrate Paleontology Collection',
				'SC','Special Collections',
				'MCZ','MCZ Collections',
				'IP','Invertebrate Paleontology Collection',
				'Ich','Ichthyology Collection',
				'Orn','Ornithology Collection',
				'Cryo','Cryogenic Collection',
				'Ent','Entomology Collection',
				'[Unable to identify collection from loan number]' || substr(loan_number, instr(loan_number, '-',1, 2)+1)
				) as collection
    	 from
    		loan_item,
    		loan,
    		specimen_part,
    		cataloged_item,
    		identification,
    		collecting_event,
    		preferred_agent_name,
    		trans,
    		trans_agent,
                coll_obj_cont_hist,
                container
    	WHERE
    		loan_item.collection_object_id = specimen_part.collection_object_id AND
                loan_item.collection_object_id = coll_obj_cont_hist.collection_object_id AND
                coll_obj_cont_hist.container_id = container.container_id AND 
    		loan.transaction_id = loan_item.transaction_id AND
    		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
    		cataloged_item.collection_object_id = identification.collection_object_id AND
    		identification.accepted_id_fg = 1 AND
    		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
    		trans.transaction_id = loan_item.transaction_id AND
    		trans.transaction_id = trans_agent.transaction_id and
    		trans_agent.trans_agent_role = 'received by' and
    		trans_agent.agent_id = preferred_agent_name.agent_id AND
                coll_obj_cont_hist.current_container_fg = 1 and
    	        loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
    	ORDER BY cat_num
    </cfquery>
    </cfif>

    <!--- Set up the necessary variables --->

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset labelWidth = 'width: 368px;'>
    <cfset orientiation = 'landscape'>
    <cfif format is "Bird/Mammal">
    	<cfset maxRow = 15>
    </cfif>
    <cfif format is "Herp">
    	<cfset maxRow = 30>
    </cfif>
    <cfif format is "Malacology">
    	<cfset maxRow = 7>
    </cfif>
    <cfif format is "Malacology2">
    	<cfset maxRow = 7>
    </cfif>
    <cfif format is "Mammalogy">
    	<cfset maxRow = 6>
    </cfif>
    <cfif format is "Cryo" or format is "Storage">
    	<cfset maxRow = 9>
            <cfset maxCol = 2>
            <cfset labelWidth = 'width: 368px;'>
    	<cfset orientiation = 'portrait'>
    </cfif>
    <cfset numRecordsPerPage = maxCol * maxRow>
    <cfset maxPage = (getItems.recordcount-1) \ numRecordsPerPage + 1>
    <cfset curPage = 1>
    <cfset curRecord = 1>


    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>
    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0"'>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0"'>
    <cfset pageHeader='
    <div style="position:static; top:0; left:0; width:100%;">
    	<span style="position:relative; left:0px; top:0px;  width:35%; font-size:10px; font-weight:600;">
    	Page #curPage# of #maxPage#
    	</span>
    </div>
    <table #outerTableParams#>
    <tr>
    <td valign="top">
    <table #innerTableParams#>
    '>
    <cfset pageFooter = '
    </table>
    </td>
    </tr>
    </table>
    '>
    <cfif format is "Cryo" or format is "Storage">
    	<cfset textClass = "times10">
    	<cfset dateStyle = "dd mmm<br>yyyy">
    	<cfset labelStyle = 'height: 17px; #labelWidth# #labelBorder#'>
    	<!--- This width is smaller because this date occupies two lines--->
    	<cfset dateWidth = "width: 40px;">
    </cfif>
    <cfif format is "Bird/Mammal">
    	<cfset textClass = "times10">
    	<cfset dateStyle = "dd mmm<br>yyyy">
    	<cfset labelStyle = 'height: 32px; #labelWidth# #labelBorder#'>
    	<!--- This width is smaller because this date occupies two lines--->
    	<cfset dateWidth = "width: 40px;">
    </cfif>
    <cfif format is "Herp">
    	<cfset textClass = "times8">
    	<cfset dateStyle = "dd mmm yyyy">
    	<cfset labelStyle = 'height: 17px; #labelWidth# #labelBorder#'>
    	<!--- This width is larger because this date occupies one line--->
    	<cfset dateWidth = "width: 50px;">
    </cfif>
    <cfif format is "Malacology">
    	<cfset labelWidth = 'width: 2.0in;'>
        <cfset labelBorder = 'border: 0px;'>
    	<cfset textClass = "times10">
    	<cfset dateStyle = "dd mmm yyyy">
    	<cfset labelStyle = 'height: 1.0in; #labelWidth# #labelBorder#'>
    	<cfset dateWidth = "width: 60px;"><!--- unused --->
        <cfset pageHeader='
         <table #outerTableParams#>
         <tr>
         <td valign="top">
         <table #innerTableParams#>
        '>
        <cfset orientiation = 'portrait'>
    </cfif>
    <cfif format is "Malacology2">
    	<cfset labelWidth = 'width: 2.1in;'>
        <cfset labelBorder = 'border: 0px;'>
    	<cfset textClass = "times8">
    	<cfset dateStyle = "dd mmm yyyy">
    	<cfset labelStyle = 'height: 1.0in; #labelWidth# #labelBorder#'>
    	<cfset dateWidth = "width: 60px;"><!--- unused --->
        <cfset pageHeader='
         <table #outerTableParams#>
         <tr>
         <td valign="top">
         <table #innerTableParams#>
        '>
        <cfset orientiation = 'portrait'>
    </cfif>
    <cfif format is "Mammalogy">
    	<cfset labelWidth = 'width: 3.3in;'>
        <cfset labelBorder = 'border: 0px;'>
    	<cfset textClass = "times12">
    	<cfset dateStyle = "dd mmm yyyy">
    	<cfset labelStyle = 'height: 1.4in; #labelWidth# #labelBorder#'>
    	<cfset dateWidth = "width: 60px;"><!--- unused --->
        <cfset pageHeader='
         <table #outerTableParams#>
         <tr>
         <td valign="top">
         <table #innerTableParams#>
        '>
        <cfset orientiation = 'portrait'>
    </cfif>


    <!--- Document tags --->
    <!--- TODO: figure out WHY the pdf i download from the link above is not getting changed...
    sent email to dusty about it.
    update -- seems to work now, I have no idea what fixed it... --->
    <cfdocument
    	format="pdf"
    	pagetype="letter"
    	margintop=".25"
    	marginbottom=".25"
    	marginleft=".25"
    	marginright=".25"
    	orientation="#orientiation#"
    	fontembed="yes"
    	filename="#Application.webDirectory#/temp/loaninvoice_#cookie.cfid#_#cookie.cftoken#.pdf"
    	overwrite="yes">
    <cfoutput>
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
    <cfif format is "Malacology" or format is "Mammalogy" or format is "Malacology2">
    	<!--- omit page count in header for malacology format --->
    <cfelse>
        <cfset pageHeader = replace(pageHeader,'Page #curPage-1# of','Page #curPage# of')>
    </cfif>
    #pageHeader#
    <!--- Main loop --->
    <cfloop query="getItems">

    <!--- Data manipulation --->
    <cfif format is "Bird/Mammal">
    	<cfset sciName = #replace(scientific_name," ","&nbsp;","all")#>
    	<!--- complicated and stupid, but it should work.
    	The idea is to find all the spaces in the scientific name. Then find the
    	one that is closest to the center of the string. Change that space to a
    	newline.
    	--Peter DeVore --->
    	<!--- Find the space locations --->
    	<cfset thingToReplace = "&nbsp;">
    	<cfset curLoc = 0>
    	<cfset spaceLocs = "">
    	<cfset loopin = true>
    	<cfloop condition="loopin">
    		<cfif find(thingToReplace,sciName,curLoc+1) is 0>
    			<cfset loopin = false>
    		<cfelse>
    			<cfset curLoc = find(thingToReplace,sciName,curLoc+1)>
    			<cfset spaceLocs = ListAppend(spaceLocs,curLoc)>
    		</cfif>
    	</cfloop>

    	<!--- If there are no spaces, then no need to do anything else! --->
    	<cfif len(spaceLocs) gt 0>
    		<!--- Convert the space locations into distances from center --->
    		<cfset convertedSpaceLocs = "">
    		<cfloop list="#spaceLocs#" index="loc">
    			<cfset convertedSpaceLocs = abs(loc - (len(sciName)/2))>
    		</cfloop>

    		<!--- Sort those distances --->
    		<cfset convertedSpaceLocs = ListSort(convertedSpaceLocs,"numeric")>

    		<!--- Have not replaced a space yet --->
    		<cfset replacedSpace = false>

    		<!--- Try inserting newline if the closest space is after the center --->
    		<cfset position = (len(sciName)/2) + ListFirst(convertedSpaceLocs)>
    		<cfif find(thingToReplace, sciName, position) is position and not replacedSpace>
    			<cfset sciName = insert("<br>", sciName, position-1)>
    			<cfset replacedSpace = true>
    		</cfif>

    		<!--- Try inserting newline if the closest space is before the center --->
    		<cfset position = (len(sciName)/2) - ListFirst(convertedSpaceLocs)>
    		<cfif find(thingToReplace, sciName, position) is position and not replacedSpace>
    			<cfset sciName = insert("<br>", sciName, position-1)>
    			<cfset replacedSpace = true>
    		</cfif>
    	</cfif>
    </cfif>
    <cfif format is "Herp" or format is "Storage">
    	<cfset sciName = #replace(scientific_name," ","&nbsp;","all")#>
    </cfif>
    <cfif format is "Malacology" or format is "Malacology2">
    	<cfset sciName = #replace(scientific_name," ","&nbsp;","all")#>
    	<cfset higherTaxa = "#phylum#&nbsp;#family#">
        <cfif len(sciName) GT 26>
    	   <cfset higherTaxa = left("#phylum#&nbsp;#family#",25) & "...">
        </cfif>
    </cfif>
    <cfif format is "Mammalogy">
    	<cfset sciName = #scientific_name#>
    </cfif>
    <!--- End data manipulation --->

    	<tr><td>
    	<!--- here is where I could insert a div tag so that I could limit the space
    	allotted per item, but make sure that the div tag size is a function or which format is chosen--->
    	<div style="#labelStyle#">
    		<cfif format is "Cryo" >
    		   <table>
    		      <tr>
    		         <td><span class="#textClass#"><i>#sciName#</i> <strong>#collection_cde# #cat_num#</strong></span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#">#otherids#</span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#">#container#</span></td>
    	 	     </tr>
    	          </table>
                    <cfelse>
    		<cfif format is "Storage" >
    		   <table>
    		      <tr>
    		         <td colspan="2" align="center"><span class="#textClass#">
    			      <strong>Loan Number:</strong> #getItems.loan_number# &nbsp;
                              <strong>On Loan To:</strong> #agent_name#
                         </span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#"><i>#sciName#</i> <strong>#collection_cde# #cat_num#</strong></span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#">#container#</span></td>
    	 	     </tr>
    	          </table>
    		<cfelseif format is "Malacology">
    		      <table>
    		      <tr>
    		         <td colspan="2"><span class="#textClass#"><strong>#collection_cde# #cat_num#</strong></span>&nbsp;<span align="right" class="#textClass#">#higherTaxa#</span></td>
    			  </tr>
    			  <tr>
    		         <td colspan="2"><div class="#textClass#"><i>#sciName#</i> <span style="float: right;"><strong>#typestatus#</strong></span></div></td>
    			  </tr>
    			 <tr>
    			 </tr>
    			 <tr>
    		        <td>
    			      <span class="#textClass#"><strong>Loan Number:</strong> #getItems.loan_number#</span>
    		        </td>
    		        <td>
    			       <div class="#textClass#">#dateformat(trans_date,dateStyle)#</div>
    		        </td>
    			</tr>
    			  <tr>
    		         <td colspan="2" align="center"><div class="#textClass#"><strong>Museum of Comparative Zoology</span></strong></td>
    		      </tr>
    	              </table>
   		   <cfelseif format is "Malacology2">
    		      <table style="font-size: smaller; line-height: 85%; padding: 0px;">
    		      <tr style="padding: 0px; margin: 0px;">
    		         <td colspan="2"><span class="#textClass#"><strong>#collection_cde#&nbsp;#cat_num#</strong></span>&nbsp;<span align="right" class="#textClass#">#higherTaxa#</span></td>
    			  </tr>
    		      <tr style="padding: 0px; margin: 0px;">
    		         <td colspan="2"><div class="#textClass#"><i>#sciName#</i> <span style="float: right;"><strong>#typestatus#</strong></span></div></td>
    			  </tr>
    		      <tr style="padding: 0px; margin: 0px;">
                         <cfif parentcontainer eq "The Museum of Comparative Zoology">
                            <cfset parentcontainer_c = ''>
                         <cfelse>
                            <cfset parentcontainer_c = parentcontainer>
                         </cfif>
    		         <td colspan="2"><span class="#textClass#">#parentcontainer_c# #part_prep# #lot_count_mod#</span></td>
    			  </tr>
    		      <tr style="padding: 0px; margin: 0px;">
    		         <td colspan="2" align="center"><span class="#textClass#"><strong>On Loan To:</strong> #agent_name#</span></td>
    			 </tr>
    		      <tr style="padding: 0px; margin: 0px;">
    		        <td>
    			      <span class="#textClass#"><strong>Loan Number:</strong> #getItems.loan_number#</span>
    		        </td>
    		        <td>
    			       <div class="#textClass#" >#replace(dateformat(trans_date,dateStyle),' ','&nbsp;','all')#</div>
    		        </td>
    			</tr>
    		      <tr style="padding: 0px; margin: 0px;">
    		         <td colspan="2" align="center"><div class="#textClass#"><strong>Museum of Comparative Zoology</span></strong></td>
    		      </tr>
    	              </table>
   		   <cfelse >
    		      <cfif format is "Mammalogy">
    			<table width="100%" style="border: 1px solid black; " class="labeltableclass">
    			  <tr>
    		         <td colspan="2" align="center"><div class="#textClass#"><strong>MCZ #collection#</span></strong></td>
    		      </tr>
    			 <tr>
    		        <td>
    			      <span class="#textClass#"><strong>Loan No.:</strong> #getItems.loan_number#</span>
    		        </td>
    		        <td>
    			       <div class="#textClass#"><strong>Date:</strong>#dateformat(trans_date,dateStyle)#</div>
    		        </td>
    			</tr>
    		      <tr>
    		        <td colapan="2">
				       <span class="#textClass#"><strong>MCZ #collection_cde# #cat_num#</strong></span>
					 </td>
    			  </tr>
    			  <tr>
    		         <td colspan="2"><div class="#textClass#"><i>#sciName#</i></span></td>
    			  </tr>
    			 <tr>
    		         <td colspan="2"><span class="#textClass#"><strong>Nature:</strong> #part_name#</span></td>
    			 </tr>
    			 <tr>
    		         <td colspan="2"><span class="#textClass#"><strong>Borrower:</strong> #agent_name#</span></td>
    			 </tr>
    	       </table>
    		<cfelse >
    	<table><tr>
    		<td>
    			<span class="#textClass#">#cat_num#</span>
    		</td>
    <!--- there is a sciname width problem (sample: transaction_id=11062560 in dev)
    where it can be too big and force the slips onto the next line.
    not much i can do about it: i tried limiting the width of it, but if you want
    one line slips, then its going to take that much room and that's that.
    --Peter DeVore--->
    		<td>
    			<div class="#textClass#"><i>#sciName#</i></span>
    		</td>
    		<td>
    			<span class="#textClass#">#getItems.loan_number#</span>
    		</td>
    		<td>
    		<!--- mmm is Aug, while mmmm is August (diff formats)--->
    			<div class="#textClass#" style="#dateWidth#">#dateformat(trans_date,dateStyle)#</div>
    		</td>
    		<td>
    			<span class="#textClass#">#agent_name#</span>
    		</td>
    	</tr></table>
    		</cfif>
	        </cfif>
            </cfif>
    	</div>
    	</td></tr>
    	<!--- End Column? Do it after every #maxRow# labels --->
    	<cfif curRecord mod maxRow is 0>
    		</table></td>
    		<!--- But only add a new column if that wasn't the last record AND we aren't at a page break --->
    		<cfif curRecord lt getItems.recordCount and curRecord mod numRecordsPerPage is not 0>
    			<td valign='top'><table #innerTableParams#>
    		</cfif>
    	</cfif>
    	<!--- Page break? --->
    	<cfif curRecord mod numRecordsPerPage is 0 AND curRecord lt getItems.recordcount>
    		<cfset curPage = curPage + 1>
    		<!--- end the old table, pagebreak, and begin the new one--->
    		#pageFooter#<cfdocumentitem type="pagebreak"></cfdocumentitem>
    		<cfif format is "Malacology" or format is "Malacology2">
    	       <!--- omit page header for malacology format --->
            <cfelse>
    		   <cfset pageHeader = replace(pageHeader,'Page #curPage-1# of','Page #curPage# of')>
    		</cfif>
    		#pageHeader#
    	</cfif>
    	<!--- and finish our current record --->
    	<cfset curRecord=#curRecord#+1>
    </cfloop>
    #pageFooter#
    </cfoutput>
    </cfdocument>
    <cfinclude template = "../includes/_footer.cfm">
</cfif>  <!-- End not Cryo-Sheet  -->
</cfif>  <!-- End Action -->


<!---

<!------------------------------------------------------------------->
<cfif #Action# is "shippingLabel">
<cfinclude template='../includes/_header.cfm'>
<!---
For this action:
Author: Peter DeVore
Email: pdevore@berkeley.edu

Description:
	Used to make printable shipping labels for specimens from Loan.cfm page.
Parameters:
	transaction_id
Based on:
	other actions in this page
--->

	<cfparam name="shipped_to_addr" default = "">
	<cfparam name="shipped_to_addr_id" default = "">
	<cfparam name="shipped_from_addr" default = "">
	<cfparam name="shipped_from_addr_id" default = "">
	<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * 
		from shipment 
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>
	<!--- Test to see if there are shipping addresses. --->
	<cfif ship.recordcount gt 0>
		<cfquery name="shipped_to_addr_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select formatted_addr from addr where
			addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ship.shipped_to_addr_id#">
		</cfquery>
		<cfset shipped_to_addr = "#shipped_to_addr_id.formatted_addr#">
		<cfquery name="shipped_from_addr_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select formatted_addr from addr where
			addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ship.shipped_from_addr_id#">
		</cfquery>
		<cfset shipped_from_addr = "#shipped_from_addr_id.formatted_addr#">
		<cfoutput>
			<p>
				<a href="/temp/loaninvoice_#cookie.cfid#_#cookie.cftoken#.pdf" target="_blank">Get the PDF</a>
			</p>
		</cfoutput>

<!--- Define formatting params --->
<cfset fromToClass = "times9b">
<cfset fromAddrClass = "times10">
<cfset toAddrClass = "times12b">
<cfset addrStyle = "text-align: center;">
<cfset checkboxTextClass = 'times10'>
<cfset checkboxStyle = "border: 1px solid black; padding: -.25em 0em -.25em 0em;">
<!--- End formatting params --->
<cfdocument
	format="pdf"
	pagetype="letter"
	margintop=".25"
	marginbottom=".25"
	marginleft=".25"
	marginright=".25"
	orientation="portrait"
	fontembed="yes"
	filename="#Application.webDirectory#/temp/loaninvoice_#cookie.cfid#_#cookie.cftoken#.pdf"
	overwrite="yes">
<cfoutput>
<link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
<!--- we want two copies of the label, so we do a loop that runs twice --->
<cfloop from="0" index="whatever" to="1">
<div style="width: 300px; height: 195px; border: 1px black dashed; padding: 5px;">
	<table><tr><td valign="top"><span class="#fromToClass#">From:</span></td>
	<td><div class="#fromAddrClass#" style="#addrStyle#">
		<blockquote>
			#replace(shipped_from_addr,"#chr(10)#","<br>","all")#
		</blockquote>
	</div></td></tr></table>
	<hr>
	<table><tr><td valign="top"><span class="#fromToClass#">To:</span></td>
	<td><div class="#toAddrClass#" style="#addrStyle#">
		<blockquote>
			#replace(shipped_to_addr,"#chr(10)#","<br>","all")#
		</blockquote>
	</div></td></tr></table>
	<!--- It seems that, as of Coldfusion 7, cfdocument does not support Times
	New Roman White Box character. From this, I assume that it cannot support
	one other non keyboard characters.Thus to make a checkbox I put in spaces
	and surround it with a black border. I then adjust the padding until it is
	the right size/shape. Thankfully, this does not need be cross-browser
	compatible because it is made ONLY at the Arctos server. Thus, this only
	needs to be updated if the font of the text around it changes or if the
	server changes its HTML formatting drastically.
	--Peter DeVore, 2008-02-06 --->
	<!--- previously tried any of the following (numbers were for spacing them to test)
	<cfoutput>
	-2 #charsetEncode(binaryDecode("e296a1","hex"),"utf-8")#
	-1 &##9633;
	0 &##x2610;
	1 &##9744;
	2 #charsetEncode(binaryDecode("feff25A1","hex"),"utf-16")#
	3 &##x25a1;
	These are the unicode characters for different boxes. See above comment as
	to why I don't use them.
	</cfoutput>--->
	<span class="#checkboxTextClass#"><span style='#checkboxStyle#'>&nbsp;&nbsp;</span>
	Printed Matter</span><br/>
	<span class="#checkboxTextClass#"><span style='#checkboxStyle#'>&nbsp;&nbsp;</span>
	Scientific Specimens/No endangered species/No commercial value</span><br/>
	<span class="#checkboxTextClass#"><span style='#checkboxStyle#'>&nbsp;&nbsp;</span>
	Insured</span><br/>
	<div class="#checkboxTextClass#" style="text-align: center;">Value _____________</div>
</div>
</cfloop>
</cfoutput>
</cfdocument>
<cfelse>
No Addresses for this loan to make a shipping label from!
</cfif>
<cfinclude template = "../includes/_footer.cfm">
</cfif>



<!------------------------------------------------------------------->
<cfif #Action# is "itemList">
<cfoutput>
Splitting pages up is tricky. There is no automatic wrap function, and the data vary widely between loans. 15 rows per page (17 on pages other than the first) works well most of the time. If there are problems with wrapping pages, select a new value in the form below, submit the query, and check the new PDF that will be generated.
<p></p>
Number of rows to print per page:
<p></p>
<form name="a" method="post" action="MCZDrawerTags.cfm">
	<input type="hidden" name="action" value="itemList" />
	<input type="hidden" name="transaction_id" value="#transaction_id#" />
	Rows: <input type="text" name="numRowsFPage" value="15" />
	<input type="submit" />


</form>
<p>
	<a href="/temp/LoanInvoice.pdf" target="_blank">Get the PDF</a>
</p>
</cfoutput>
<!----


	---->
	<cfdocument
	format="pdf"
	pagetype="letter"
	margintop=".25"
	marginbottom=".25"
	marginleft=".25"
	marginright=".25"
	orientation="landscape"
	fontembed="yes"
	 filename="#Application.webDirectory#/temp/LoanInvoice.pdf"
	 overwrite="yes" >

<link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">

<cfoutput>
<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select
		cat_num,
		cataloged_item.collection_object_id,
		collection.collection,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		concatattributevalue(cataloged_item.collection_object_id,'sex') as sex,
		decode (sampled_from_obj_id,
			null,part_name,
			part_name || ' sample') part_name,
		 part_modifier,
		 preserve_method,
		condition,
		 item_instructions,
		 loan_item_remarks,
		 coll_obj_disposition,
		 scientific_name,
		 Encumbrance,
		 agent_name,
		 loan_number,
		 spec_locality,
		 higher_geog,
		 orig_lat_long_units,
		 lat_deg,
		 lat_min,
		 lat_sec,
		 long_deg,
		 long_min,
		 long_sec,
		 dec_lat_min,
		 dec_long_min,
		 lat_dir,
		 long_dir,
		 dec_lat,
		 dec_long,
		 max_error_distance,
		 max_error_units,
		 decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_lat) || '&deg; ',
				'deg. min. sec.', to_char(lat_deg) || '&deg; ' || to_char(lat_min) || '&acute; ' || to_char(lat_sec) || '&acute;&acute; ' || lat_dir,
				'degrees dec. minutes', to_char(lat_deg) || '&deg; ' || to_char(dec_lat_min) || '&acute; ' || lat_dir
			)  VerbatimLatitude,
			decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_long) || '&deg;',
				'deg. min. sec.', to_char(long_deg) || '&deg; ' || to_char(long_min) || '&acute; ' || to_char(long_sec) || '&acute;&acute; ' || long_dir,
				'degrees dec. minutes', to_char(long_deg) || '&deg; ' || to_char(dec_long_min) || '&acute; ' || long_dir
			)  VerbatimLongitude
	 from
		loan_item,
		loan,
		specimen_part,
		coll_object,
		cataloged_item,
		coll_object_encumbrance,
		encumbrance,
		agent_name,
		identification,
		collecting_event,
		locality,
		geog_auth_rec,
		accepted_lat_long,
		collection
	WHERE
		loan_item.collection_object_id = specimen_part.collection_object_id AND
		loan.transaction_id = loan_item.transaction_id AND
		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
		specimen_part.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
		coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
		encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		collecting_event.locality_id = locality.locality_id AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		locality.locality_id = accepted_lat_long.locality_id (+) AND
		cataloged_item.collection_id = collection.collection_id AND
	  loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	  ORDER BY cat_num
</cfquery>
<cfquery name="one" dbtype="query">
	select
		cat_num,
		customid,
		collection_object_id,
		collection,
		sex,
		scientific_name,
		Encumbrance,
		agent_name,
		loan_number,
		spec_locality,
		higher_geog,
		orig_lat_long_units,
		lat_deg,
		lat_min,
		lat_sec,
		long_deg,
		long_min,
		long_sec,
		dec_lat_min,
		dec_long_min,
		lat_dir,
		long_dir,
		dec_lat,
		dec_long,
		max_error_distance,
		max_error_units,
		VerbatimLatitude,
		VerbatimLongitude
	FROM
		getItems
	GROUP BY
		cat_num,
		customid,
		collection_object_id,
		collection,
		sex,
		scientific_name,
		Encumbrance,
		agent_name,
		loan_number,
		spec_locality,
		higher_geog,
		orig_lat_long_units,
		lat_deg,
		lat_min,
		lat_sec,
		long_deg,
		long_min,
		long_sec,
		dec_lat_min,
		dec_long_min,
		lat_dir,
		long_dir,
		dec_lat,
		dec_long,
		max_error_distance,
		max_error_units,
		VerbatimLatitude,
		VerbatimLongitude
	ORDER BY cat_num
</cfquery>
<cfquery name="more" dbtype="query">
	select
		collection_object_id,
		part_name,
		part_modifier,
		preserve_method,
		condition,
		item_instructions,
		loan_item_remarks,
		coll_obj_disposition
	from
		getItems
	GROUP BY
		collection_object_id,
		part_name,
		part_modifier,
		preserve_method,
		condition,
		item_instructions,
		loan_item_remarks,
		coll_obj_disposition
</cfquery>
<!--- get number of pages we'll have
	<cfset lChars = 0>
	<cfset numberOfPages = 1>
	<cfloop query="one">
		<cfset lChars = #lChars# + len(#higher_geog#) + len(#spec_locality#)>
		<cfif #numberOfPages# is 1>
			<cfif #lChars# gte 1000>
				<cfset numberOfPages = #numberOfPages# + 1>
				<cfset lChars=0>
			</cfif>
		<cfelse>
			<cfif #lChars# gte 1100>
				<cfset numberOfPages = #numberOfPages# + 1>
				<cfset lChars=0>
			</cfif>
		</cfif>
	</cfloop>

	--->
	<cfif not isdefined("numRowsFPage")>
		<cfset numRowsFPage = 15>
	</cfif>
	<cfif not isdefined("numRowsNPage")>
		<cfset numRowsNPage = #numRowsFPage# + 2>
	</cfif>
	<!--- 12 rows on the first page --->
	<cfif one.recordcount lte #numRowsFPage#>
		<cfset numberOfPages = 1>
	<cfelse>
		<!--- 14 rows on other pages --->
		<cfset numberOfPages = ceiling((one.recordcount + 1) / #numRowsFPage#)>
	</cfif>

	<cfset i=1>
	<cfset pageRow = 1>
	<cfset page_num = 1>

<div style="position:absolute; left:5px; top:5px;font-size:10px; font-weight:600;">
	Page 1 of #numberOfPages#
</div>
<div style="position:absolute; right:5px; top:5px; font-size:10px; font-weight:600;">
	Loan&nbsp;##&nbsp;#getItems.loan_number#
</div>
<div style=" width:100%; " align="center">
         <b><font face="Arial, Helvetica, sans-serif">SPECIMEN&nbsp;&nbsp;INVOICE <br>

	<font size="+2"> Museum of Vertebrate Zoology <br>
    University of California, Berkeley</font></font></b> <br>
        <cfquery name="shipDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select shipped_date 
					from shipment 
					where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transactioN_id#">
        </cfquery>
   <b> #dateformat(shipDate.shipped_date,"dd mmmm yyyy")#</b>
   <br>
      <font face="Courier New, Courier, mono"><b>Item List</b></font>
</div>
<table width="100%" cellspacing="0" cellpadding="0" id="goodborder">
	<tr>
		<td align="center">
			<span class="times12b">CN</span>
		</td>
		<td align="center">
			<span class="times12b">#session.CustomOtherIdentifier#</span>
		</td>
		<td align="center">
			<span class="times12b">Scientific Name</span>
		</td>
		<td align="center">
			<span class="times12b">Sex</span>
		</td>
		<td align="center">
			<span class="times12b">Locality</span>
		</td>
		<td align="center">
			<span class="times12b">Item</span>
		</td>
		<td align="center">
			<span class="times12b">Condition</span>
		</td>

		<td align="center">
			<span class="times12b">More?</span>
		</td>

	</tr>

	<cfloop query="one">
	<cfquery name="items" dbtype="query">
		select * 
		from more 
		where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	</cfquery>
	<cfset numItemsForThisSpec = #items.recordcount#>
	<cfset isMore = "">


	<tr	#iif(i MOD 2,DE("style='background-color:E5E5E5'"),DE("style='background-color:FFFFFF'"))#	>
		<td rowspan="#numItemsForThisSpec#">
			<span class="times10">#collection#&nbsp;#cat_num#</span>
		</td>
		<td rowspan="#numItemsForThisSpec#">
			#CustomID#&nbsp;
		</td>

		<td rowspan="#numItemsForThisSpec#">
			<span class="times10"><i>#replace(scientific_name," ","&nbsp;","all")#</i></span>
		</td>
		<td rowspan="#numItemsForThisSpec#">
			<span class="times10">#sex#</span>
		</td>
		<td rowspan="#numItemsForThisSpec#">
			<!---
			<cfset p=#p# + len(#higher_geog#) + len(#spec_locality#)>
			--->
			<span class="times10">
				#higher_geog#. <br>#spec_locality#<br />
			<cfif len(#VerbatimLatitude#) gt 0 and len(#VerbatimLongitude#) gt 0>
				#VerbatimLatitude#/#VerbatimLongitude# &##177; #max_error_distance# #max_error_units#
			<cfelse>
				Not georeferenced.
			</cfif>
			</span>
		</td>
		<cfset thisItemRow = 1>
		<cfloop query="items">
		<cfif #thisItemRow# gt 1>
			<tr	#iif(i MOD 2,DE("style='background-color:CCCCCC'"),DE("style='background-color:FFFFFF'"))#	>
		</cfif>
		<td >
			<span class="times10">
				#items.part_modifier# #items.part_name#
				<cfif len(#items.preserve_method#) gt 0>
					(#items.preserve_method#)&nbsp;
				</cfif>
			</span>


		</td>
		<td >
			<span class="times10">
				<cfif len(#items.Condition#) gt 15>
				See attached.
			  <cfelse>
			  	#items.Condition#
			</cfif>&nbsp;
			</span>

		</td>
		<td >
			<div class="times10" style="width:100%; text-align:center;">
			<cfif len(#items.Condition#) gt 15 OR len(#one.Encumbrance#) gt 0>
				X
			</cfif>
			</div>
		</td>
		<cfif #thisItemRow# gt 1>
			</tr>
		</cfif>
		<cfset thisItemRow = #thisItemRow#+1>
		</cfloop>
	</tr>
	<cfset i=#i#+1>
	<cfset pageRow=#pageRow# + 1>
	<!---
	<cfif #page_num# is 199999 AND #pageRow# is #numRowsFPage#>
		<cfset pageBreakNow = "true">
	<cfelseif #page_num# gt 1 AND #pageRow# is #numRowsNPage#>
		<cfset pageBreakNow = "true">
	<cfelse>
		<cfset pageBreakNow = "false">
	</cfif>
	--->
	<cfif #page_num# is 1 AND #pageRow# is #numRowsFPage# AND #i# lte #one.recordcount#>
		<cfset pageBreakNow = "true">
	<cfelseif #page_num# gt 1 AND #pageRow# is #numRowsNPage# AND #i# lte #one.recordcount#>
		<cfset pageBreakNow = "true">
	<cfelse>
		<cfset pageBreakNow = "false">
	</cfif>



	<cfif #pageBreakNow# is "true">
		</table>
		<!---

		<hr />#i# - #pageRow# - #page_num# - first pagebreak<hr />

		---->
	&nbsp;


		<cfdocumentitem type="pagebreak"></cfdocumentitem>
		<cfset page_num = #page_num# + 1>
		<cfset pageRow=0>
		<!--- end the old table --->
		<div style="position:static; top:0; left:0; width:100%;">
			<span style="position:relative; left:0px; top:0px;  width:35%; font-size:10px; font-weight:600;">
					Page #page_num# of #numberOfPages#
				</span>
				<span style="position:relative; right:0px; top:0px; float:right;  width:35%; text-align:right; font-size:10px; font-weight:600;">
					Loan ## #getItems.loan_number#
				</span>
		</div>

		<!--- start a new page and table
		<div style="position:static; top:0; left:0; width:100%;">
				<span style="position:relative; left:0px; top:0px;  width:35%; font-size:10px; font-weight:600;">
					Page #page_num# of #numberOfPages#
				</span>
				<span style="position:relative; right:0px; top:0px; float:right;  width:35%; text-align:right; font-size:10px; font-weight:600;">
					Loan ## #getItems.loan_num_prefix#.#getItems.loan_num# #getItems.loan_num_suffix#
				</span>
			</div>
 --->
			<table width="100%" border="1" cellspacing="0" cellpadding="0"  id="goodborder">
	<tr>
		<td align="center">
			<span class="times12b">CN</span>
		</td>
		<td align="center">
			<span class="times12b">#session.CustomOtherIdentifier#</span>
		</td>
		<td align="center">
			<span class="times12b">Scientific Name</span>
		</td>
		<td align="center">
			<span class="times12b">Sex</span>
		</td>
		<td align="center">
			<span class="times12b">Locality</span>
		</td>
		<td align="center">
			<span class="times12b">Item</span>
		</td>
		<td align="center">
			<span class="times12b">Condition</span>
		</td>

		<td align="center">
			<span class="times12b">More?</span>
		</td>

	</tr>

	</cfif>
</cfloop></table>

</cfoutput>

</cfdocument>
<!---

--->

</cfif>
<!------------------------------------------------------------------->
<!------------------------------------------------------------------->
<cfif #Action# is "showCondition">
<cfoutput>
<cfdocument
	format="pdf"
	pagetype="letter"
	margintop=".25"
	marginbottom=".25"
	marginleft=".25"
	marginright=".25"
	orientation="landscape"
	fontembed="yes" >

<link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select
		cat_num,
		collection,
		part_name,
		 part_modifier,
		 preserve_method,
		condition,
		loan_number,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID
	 from
		loan_item,
		loan,
		specimen_part,
		coll_object,
		cataloged_item,
		collection
	WHERE
		loan_item.collection_object_id = specimen_part.collection_object_id AND
		loan.transaction_id = loan_item.transaction_id AND
		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
		cataloged_item.collection_id = collection.collection_id AND
		specimen_part.collection_object_id = coll_object.collection_object_id AND
		loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	ORDER BY cat_num
</cfquery>
<!--- get number of pages we'll have --->
	<cfset lChars = 0>
	<cfset numberOfPages = 1>
	<cfloop query="getItems">
		<cfset lChars = #lChars# + len(#condition#)>
		<cfif #numberOfPages# is 1>
			<cfif #lChars# gte 1200>
				<cfset numberOfPages = #numberOfPages# + 1>
				<cfset lChars=0>
			</cfif>
		<cfelse>
			<cfif #lChars# gte 1100>
				<cfset numberOfPages = #numberOfPages# + 1>
				<cfset lChars=0>
			</cfif>
		</cfif>
	</cfloop>
<div style="position:absolute; left:5px; top:5px; font-size:10px; font-weight:600;">
	Page 1 of #numberOfPages#
</div>
<div style="position:absolute; right:5px; top:5px; font-size:10px; font-weight:600;" >
	Loan&nbsp;##&nbsp;#getItems.loan_number#
</div>

<div style=" width:100%; " align="center">
         <b><font face="Arial, Helvetica, sans-serif">SPECIMEN&nbsp;&nbsp;INVOICE <br>
   <font size="+2"> Museum of Vertebrate Zoology <br>
    University of California, Berkeley</font></font></b> <br>
        <cfquery name="shipDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                select shipped_date 
					from shipment 
					where transaction_id = #transactioN_id#<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=">
        </cfquery>
   <b> #dateformat(shipDate.shipped_date,"dd mmmm yyyy")#</b>
   <br>
      <font face="Courier New, Courier, mono"><b>Condition Appendix</b></font>
</div>


<table width="100%"  border="1" cellspacing="0" cellpadding="0">
	<tr>
		<td align="center">
			<span class="times12b">CN</span>
		</td>
		<td align="center">
			<span class="times12b">#session.CustomOtherIdentifier#</span>
		</td>
		<td align="center">
			<span class="times12b">Item</span>
		</td>
		<td align="center">
			<span class="times12b">Condition</span>
		</td>

	</tr>
	<cfset i=1>
	<cfset p = 1>
	<cfloop query="getItems">

<cfif len(#Condition#) gt 15>



	<tr>
		<td>
			<span class="times10">
			#collection# #cat_num#&nbsp;
			</span>
		</td>
		<td>
			<span class="times10">
			#customID#&nbsp;
			</span>
		</td>

		<td>
			<span class="times10">
			#part_modifier# #part_name#
			<cfif len(#preserve_method#) gt 0>
				(#preserve_method#)&nbsp;
			</cfif>
			</span>
		</td>
		<td>
				<span class="times10">
				#Condition#
				</span>
		</td>

	</tr>
	<cfset i=#i#+1>

</cfif>
</cfloop>
</table>
</cfdocument>
</cfoutput>

</cfif>

--->


<cfinclude template="/includes/_pickFooter.cfm">
