<cfinclude template="/includes/_pickHeader.cfm">
<!------------------------------------------------------------------->
<cfset filename="containerlabels_#cfid#_#cftoken#.pdf" >
<p>
	<a href="/temp/#filename#" target="_blank">Get the PDF</a>
</p>
<cfparam default="SCSlideTray" name="format">
<cfif format is "SlideTray">
   <cfset displayFormat = "Slide Tray Content">
<cfelseif format is "SlideTrayFront">
   <cfset displayFormat = "Slide Tray Front">
<cfelseif format is "SCSlideTray">
   <cfset displayFormat = "SC Slide Tray Content (all)">
<cfelse>
   <cfset displayFormat = "#format#">
</cfif>
Current format: #displayFormat#<br/>
<form action='ContainerLabels.cfm' method="POST">
	<input type='hidden' name='table_name' value='#table_name#'>
Change to: <select name="format">
		<option value="SCSlideTray">SC Slide Tray Content (all)</option>
		<option value="SlideTray">Slide Tray Content</option>
		<option value="SlideTrayFront">SlideTrayFront</option>
	</select>
	<input type='submit' value='Change Format' />
</form>
</cfoutput>

<cfif format is "CFSlideTray">

    <cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select distinct 
       get_scientific_name(cat.collection_object_id) as ident, 
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray','') as tray, 
       cat.collection_cde || ':' || cat.cat_num as cat_num
    from container cc left join container cp on cc.parent_container_id = cp.container_id
       left join coll_obj_cont_hist ch on cc.container_id = ch.container_id
       left join specimen_part sp on ch.COLLECTION_OBJECT_ID = sp.COLLECTION_OBJECT_ID
       left join cataloged_item cat on sp.DERIVED_FROM_CAT_ITEM = cat.COLLECTION_OBJECT_ID
    where cp.barcode like 'Shared_slide-cab-%'
        and ch.current_container_fg = 1
        and cat.collection_cde = 'SC'
    order by
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray',''), 
        cat.collection_cde || ':' || cat.cat_num
    </cfquery>
    </cfif>

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset labelWidth = 'width: 368px;'>
    <cfset orientiation = 'portrait'>
    <cfset maxRow = 6>
   
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

    <cfset labelWidth = 'width: 2.0in;'>
    <cfset labelBorder = 'border: 0px;'>
    <cfset textClass = "times10">
    <cfset dateStyle = "yyyy-mmm-dd">
    <cfset labelStyle = 'height: 1.0in; #labelWidth# #labelBorder#'>
    <cfset pageHeader='
    <table #outerTableParams#>
    <tr>
    <td valign="top">
    <table #innerTableParams#>
    '>

    <cfdocument
    	format="pdf"
    	pagetype="letter"
    	margintop=".25"
    	marginbottom=".25"
    	marginleft=".25"
    	marginright=".25"
    	orientation="#orientiation#"
    	fontembed="yes"
    	filename="#Application.webDirectory#/temp/loaninvoice_#cfid#_#cftoken#.pdf"
    	overwrite="yes">
    <cfoutput>
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
    #pageHeader#
    <!--- Main loop --->
    <cfloop query="getItems">

    	<tr><td>
    	<div style="#labelStyle#">
    		   <table>
    		      <tr>
    		         <td><span class="#textClass#"><i>#ident#</i> <strong>#tray# #cat_num#</strong></span></td>
    		      </tr>
    	<!--- End Column? Do it after every #maxRow# labels --->
    	<cfif curRecord mod maxRow is 0>
    		</table></td>
    		<!--- But only add a new column if that wasn't the last record AND we aren't at a page break --->
    		<cfif curRecord lt getItems.recordCount and curRecord mod numRecordsPerPage is not 0>
    			<td valign='top'><table #innerTableParams#>
    		</cfif>
    	</cfif>
    	<!--- Page break --->
    	<cfif curRecord mod numRecordsPerPage is 0 AND curRecord lt getItems.recordcount>
    		<cfset curPage = curPage + 1>
    		<!--- end the old table, pagebreak, and begin the new one--->
    		#pageFooter#<cfdocumentitem type="pagebreak"></cfdocumentitem>
    		#pageHeader#
    	</cfif>
    	<!--- and finish our current record --->
    	<cfset curRecord=#curRecord#+1>
    </cfloop>
    #pageFooter#
    </cfoutput>
    </cfdocument>
</cfif>  <!-- End SCSlideTray  -->
</cfif>  <!-- End Action -->
       
<cfinclude template="/includes/_pickFooter.cfm">
