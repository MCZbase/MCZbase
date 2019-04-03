<cfinclude template="/includes/_pickHeader.cfm">
<!------------------------------------------------------------------->
<cfif not isdefined("header_text")>
   <cfset header_text = 'Museum of Comparative Zoology'>
</cfif>
<cfset targetfile="containerlabels_#cfid#_#cftoken#.pdf" >
<cfoutput>
<p>
	<a href="/temp/#targetfile#" target="_blank">Get the PDF</a>
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
<span><label for='header_text'>Header Text:</label> <input name='header_text' type='text' value='#header_text#'/></span>
<span><label for='format'>Change to:</label> <select name="format">
		<option value="SCSlideTray">SC Slide Tray Content (all)</option>
		<option value="SlideTray">Slide Tray Content</option>
		<option value="SlideTrayFront">SlideTrayFront</option>
	</select></span>
	<input type='submit' value='Change Format' />
</form>
</cfoutput>

<cfif format is "SCSlideTray">

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
and rownum < 10
    order by
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray',''), 
        cat.collection_cde || ':' || cat.cat_num
    </cfquery>

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset labelWidth = 'width: 368px;'>
    <cfset orientiation = 'portrait'>
    <cfset maxRow = 6>
   
    <cfset numRecordsPerPage = maxCol * maxRow>
    <cfset curPage = 1>
    <cfset curRecord = 1>

    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>
    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0"'>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0"'>
    <cfset pageHeader='
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
    	filename="#Application.webDirectory#/temp/#targetfile#"
    	overwrite="yes">
    <cfoutput>
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
    #pageHeader#
    <!--- Main loop --->
    <cfset lastTray = ''>
    <cfset curItem = 0 >
    <cfset curTray = 0 >
    <cfset lastIdent = ''>
    <cfset idents = ''>
    <cfset catnums = ''>
    <cfloop query="getItems">
       <cfset curItem = curItem + 1>
       <cfset newTray = false>
        <cfset currentTray=tray>
        <cfif currentTray EQ lastTray> 
            <!--- Begin a new tray --->
            <cfset newTray = true>
            <cfset curTray = curTray + 1 >
            <cfset idents = ''>
            <cfset catnums = ''>
            <cfset lastIdent = ''>
            <cfset iseparator = ''>
        </cfif>
       
        <!---  Iterate Through Trays, one label per tray ---> 
        <!---  Within Tray, accumulate list of distinct taxa and list of catalog numbers --->
        <cfif lastIdent NEQ ident >
           <cfset idents = '#idents##iseparator##ident#'>
           <cfset iseparator = '; '>
        </cfif>
        <cfset catnums = '#catnums# #cat_num#'>

        <!--- if Last Item or new tray, then Produce label for tray --->
        <cfif newTray EQ true OR curItem EQ getItems.recordCount>
    	<div style="#labelStyle#">
    		   <table>
    		      <tr>
    		         <td><span class="#textClass#">#header_text#<strong> #tray#</strong></span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#"><i>#idents#</i></span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#">#catnums#</span></td>
    		      </tr>
               </table>
        </div>
        </cfif> 

        <cfset lastIdent = ident>
        <cfset lastTray=tray>

        <!--- If at end of column, add next column --->
    	<cfif curTray mod maxRow is 0>
    		</table></td>
    		<!--- But only add a new column if that wasn't the last record AND we aren't at a page break --->
    		<cfif curItem lt getItems.recordCount and curTray mod numRecordsPerPage is not 0>
    			<td valign='top'><table #innerTableParams#>
    		</cfif>
    	</cfif>

        <!--- If at end of page, add new page set to first column --->
    	<cfif curTray mod numRecordsPerPage is 0 OR  curItem EQ getItems.recordcount >
    		<cfset curPage = curPage + 1>
    	    #pageFooter#<cfdocumentitem type="pagebreak"></cfdocumentitem>
    		<!--- end the old table, pagebreak, and begin the new one--->
    		#pageHeader#
    	</cfif>

    </cfloop>
    </cfoutput>
    </cfdocument>
</cfif>  <!-- End SCSlideTray  -->
       
<cfinclude template="/includes/_pickFooter.cfm">
