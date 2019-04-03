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
    order by
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray',''), 
        cat.collection_cde || ':' || cat.cat_num
    </cfquery>

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset orientiation = 'portrait'>
    <cfset maxRow = 4>
    <cfset labelWidth = 'width: 3.8in;'>
    <cfset labelHeight = 'height: 2.4in;'>
   
    <cfset numRecordsPerPage = maxCol * maxRow>
    <cfset curPage = 1>
    <cfset curRecord = 1>

    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>

    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0" '>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0" '>

    <cfset pageHeader='
    <table #outerTableParams#>
       <tr><td>
    <table #innerTableParams#>
       <tr><td>
    '>

    <cfset pageFooter = '
       </td>
       </tr>
    </table>
       </td>
       </tr>
    </table>
    '>

    <cfset textClass = "times10">
    <cfset dateStyle = "yyyy-mmm-dd">
    <cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'>

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
    <cfset curItem = 0 >  <!--- counter to track if we are at the end of the record set yet --->
    <!--- accumulators for values to display in the label ---> 
    <cfset lastTray = ''>
    <cfset lastIdent = ''>
    <cfset idents = ''>
    <cfset iseparator = ''>
    <cfset catnums = ''>
    <!--- count of current column and row location to know when to start a new column and a new page --->
    <cfset rowCount = 0>
    <cfset colCount = 0>
    <cfloop query="getItems">
       <!--- loop through all of the cataloged items (sorted by tray and scientific name --->
       <cfset curItem = curItem + 1>
       <cfset currentTray=tray>
       <cfif currentTray NEQ lastTray OR curItem EQ getItems.recordCount> 
            <!--- output previous tray ---> 
            <cfif curItem gt 1> 
               <cfset rowCount = rowCount + 1>
    	       <div style="#labelStyle#">
    		  <table>
    		      <tr>
    		         <td><span class="#textClass#">#header_text#<strong> #lastTray#</strong></span></td>
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
            <!--- Begin a new tray --->
            <cfset idents = ''>
            <cfset catnums = ''>
            <cfset lastIdent = ''>
            <cfset iseparator = ''>
            <cfset lastTray=tray>
              <!--- If at end of column, add next column --->
          	<cfif rowCount EQ maxRow >
                    <cfset colCount = colCount + 1>
                    <cfset rowCount = 0>
          	    </td></tr></table></td>
          	    <!--- But only add a new column if that wasn't the last record AND we aren't at a page break --->
          	    <cfif curItem LT getItems.recordCount AND colCount LT maxCol>
          		<td valign='top'><table #innerTableParams#><tr><td>
          	    </cfif>
          	</cfif>
      
              <!--- If at end of page, add new page set to first column --->
          	<cfif colCount EQ maxCol OR curItem EQ getItems.recordcount >
                 <cfset curPage = curPage + 1> <!--- currently not used, could be used for page x of y --->
                 <cfset rowCount = 0> <!--- restart row and column counters for new page --->
                 <cfset colCount = 0>
          	   <!--- end the old table--->
            	   #pageFooter#
                 <cfif curItem LT getItems.recordCount>
          		<!--- pagebreak begin new table--->
                      <cfdocumentitem type="pagebreak"></cfdocumentitem>
          		#pageHeader#
                 </cfif>
          	</cfif>
       </cfif>
       
       <!---  Iterate Through Trays, one label per tray, accumulating identifications and catalog numbers in tray ---> 
       <!---  Within Tray, accumulate list of distinct taxa and list of catalog numbers --->
       <cfif lastIdent NEQ ident >
           <cfset idents = '#idents##iseparator##ident#'>
           <cfset iseparator = '; '>
       </cfif>
       <cfset lastIdent = ident>

       <cfset catnums = '#catnums# #cat_num#'>

    </cfloop>
    </cfoutput>
    </cfdocument>
</cfif>  <!-- End SCSlideTray  -->
       
<cfinclude template="/includes/_pickFooter.cfm">
