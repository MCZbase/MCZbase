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
<cfelseif format is "SCSlideTrayFront">
   <cfset displayFormat = "SC Slide Tray Front (all)">
<cfelse>
   <cfset displayFormat = "#format#">
</cfif>
Current format: #displayFormat#<br/>
<form action='ContainerLabels.cfm' method="POST">
<span><label for='header_text'>Header Text:</label> <input name='header_text' type='text' value='#header_text#' size='40' /></span>
<span><label for='format'>Change to:</label> <select name="format">
		<option value="SCSlideTray">SC Slide Tray Content (all)</option>
		<option value="SCSlideTrayFront">SC Slide Tray Front (all)</option>
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
       cp.label,
       cat.collection_cde,
       to_number(regexp_replace(cat.cat_num,'[^0-9]','')) as cat_num_numeric,
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
       cp.label, cat.collection_cde, to_number(regexp_replace(cat.cat_num,'[^0-9]',''))
    </cfquery>

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset orientiation = 'portrait'>
    <cfset maxRow = 4>
    <cfset labelWidth = 'width: 4.0in; display: block; '>
    <cfset labelHeight = 'height: 2.4in;'>
   
    <cfset numRecordsPerPage = maxCol * maxRow>
    <cfset curPage = 1>
    <cfset curRecord = 1>

    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>

    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0" '>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="0" style="border: none;"   '>

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

    <cfset textClass = "times12">
    <cfset dateStyle = "yyyy-mmm-dd">
    <cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder# font: times,serif;'>

    <cfdocument
    	format="pdf"
    	pagetype="letter"
    	margintop=".25"
    	marginbottom=".25"
    	marginleft=".25"
    	marginright=".25"
    	orientation="#orientiation#"
    	fontEmbed="yes"
    	filename="#Application.webDirectory#/temp/#targetfile#"
    	overwrite="yes">
    <cfoutput>
<!---
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
--->
    #pageHeader#
    <!--- Main loop --->
    <cfset curItem = 0 >  <!--- counter to track if we are at the end of the record set yet --->
    <!--- accumulators for values to display in the label ---> 
    <cfset lastTray = ''>
    <cfset identArray = ArrayNew(1) >
    <cfset idents = ''>
    <cfset iseparator = ''>
    <cfset catnums = ''>
    <!--- count of current column and row location to know when to start a new column and a new page --->
    <cfset rowCount = 0>
    <cfset colCount = 0>
    <cfset curItemInTray=0>
    <cfloop query="getItems">
       <!--- loop through all of the cataloged items (sorted by tray and scientific name --->
       <cfset curItem = curItem + 1>
       <cfset currentTray=tray>
       <cfif currentTray NEQ lastTray OR curItem EQ getItems.recordCount> 
            <!--- output previous tray ---> 
            <cfif curItem gt 1> 
               <cfset rowCount = rowCount + 1>
               <!--- Finish off row --->
               <cfif curItemInTray mod 7 NEQ 0>
                   <!--- fill in blank cells in row of table --->
                   <cfloop condition= "curItemInTray mod 7 NEQ 0">
                       <cfset catnums = '#catnums#<td style="width: 3em;">&nbsp; </td>'>
                       <cfset curItemInTray = curItemInTray +1>
                   </cfloop>
               </cfif>
               <!--- finish the table row ---> 
               <cfset catnums = '#catnums#</tr>'>
               <!--- reset the cell counter ---> 
               <cfset curItemInTray=0>
<!---    	       <div style="#labelStyle# font-size: 12pt; ">  ---->
    		  <table style="width:100%; height: 2.6in; border: 1px solid black;">
    		      <tr style="height: 0.1in; ">
    		         <td style="width: 4.0in; border: none; vertical-align: top; "><span style="float: left; font-size: 12pt; padding-right: 0; margin-right: 0;">#header_text#</span><span style="float: right; padding-left: 0; margin-left: 0; font-size: 12pt;"><strong> #lastTray#</strong></span></td>
    		      </tr>
    		      <tr style="height: 0.1in;">
    		         <td style="vertical-align: top; border: none;"><span style="line-height: 0px;" ><i>#trim(idents)#</i></span></td>
    		      </tr>
    		      <tr style="width: 4in; height: 4.4in; max-height: 4.4in; overflow: hidden;">
    		         <td style="vertical-align: top; border: none; max-height: 2.4in; overflow: hidden; "><div style="height: 2.4in;%; vertical-align: top;"><table style="width: 4in; border: none; ">#catnums#</table></div></td>
    		      </tr>
                  </table>
<!---               </div> --->
            </cfif>
            <!--- Begin a new tray --->
            <cfset idents = ''>
            <cfset catnums = ''>
            <cfset identArray = ArrayNew(1) >
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
       <cfif NOT ArrayContains(identArray,ident) >
           <cfset idents = '#idents##iseparator##ident#'>
           <cfset iseparator = '; '>
           <cfscript>ArrayAppend(identArray,ident);</cfscript>
       </cfif>

       <cfset curItemInTray=curItemInTray+1>
       <cfset catnums = '#catnums#<td>#cat_num#</td>'>
       <cfif curItemInTray mod 7 EQ 0>
           <cfif curItemInTray mod 14 NEQ 0>
              <cfset catnums = '#catnums#</tr><tr style="background-color: ##f0f0f0;}">' >
           <cfelse>
              <cfset catnums = '#catnums#</tr><tr style="background-color: ##ffffff;}">' >
           </cfif>
       </cfif>

    </cfloop>
    </cfoutput>
    </cfdocument>
</cfif>  <!-- End SCSlideTray  -->
       
<cfif format is "SCSlideTrayFront">

    <cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select distinct 
       get_scientific_name(cat.collection_object_id) as ident, 
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray','') as tray,
        cp.barcode
    from container cc left join container cp on cc.parent_container_id = cp.container_id
       left join coll_obj_cont_hist ch on cc.container_id = ch.container_id
       left join specimen_part sp on ch.COLLECTION_OBJECT_ID = sp.COLLECTION_OBJECT_ID
       left join cataloged_item cat on sp.DERIVED_FROM_CAT_ITEM = cat.COLLECTION_OBJECT_ID
    where cp.barcode like 'Shared_slide-cab-%'
        and ch.current_container_fg = 1
        and cat.collection_cde = 'SC'
    order by
       'tray ' || replace(replace(replace(cp.label,'Shared_slide-cab-',''),'_col',''),'_tray',''),
       get_scientific_name(cat.collection_object_id) 
    </cfquery>

    <!--- Layout parameters --->
    <cfset maxCol = 2>
    <cfset orientiation = 'portrait'>
    <cfset maxRow = 20>
    <cfset labelWidth = 'width: 77mm;'>
    <cfset labelHeight = 'height: 10mm;'>
   
    <cfset numRecordsPerPage = maxCol * maxRow>
    <cfset curPage = 1>
    <cfset curRecord = 1>

    <!--- Formatting parameters --->
    <cfset labelBorder = 'border: 1px solid black;'>
    <cfset outerTableParams = 'width="100%" cellspacing="0" cellpadding="0" border="0" '>
    <cfset innerTableParams = 'width="100%" cellspacing="0" cellpadding="2mm" border="0" '>
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
    	fontEmbed="yes"
    	filename="#Application.webDirectory#/temp/#targetfile#"
    	overwrite="yes">
    <cfoutput>
    <link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
    #pageHeader#
    <!--- Main loop --->
    <cfset curItem = 0 >  <!--- counter to track if we are at the end of the record set yet --->
    <!--- count of current column and row location to know when to start a new column and a new page --->
    <cfset rowCount = 0>
    <cfset colCount = 0>
    <cfloop query="getItems">
       <!--- loop through all of the cataloged items (sorted by tray and scientific name --->
       <cfset curItem = curItem + 1>

        <!---  For each tray, get the list of scientific names, in order by other id --->
        <cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select distinct
           get_scientific_name(cat.collection_object_id) as ident,
           MCZBASE.get_single_other_id_concat(cat.collection_object_id, 'other number') as othernumber
        from container cc left join container cp on cc.parent_container_id = cp.container_id
           left join coll_obj_cont_hist ch on cc.container_id = ch.container_id
           left join specimen_part sp on ch.COLLECTION_OBJECT_ID = sp.COLLECTION_OBJECT_ID
           left join cataloged_item cat on sp.DERIVED_FROM_CAT_ITEM = cat.COLLECTION_OBJECT_ID
        where cp.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getItems.barcode#">
            and ch.current_container_fg = 1
        order by
           MCZBASE.get_single_other_id_concat(cat.collection_object_id, 'other number'),
           get_scientific_name(cat.collection_object_id)
        </cfquery>

        <cfset idents = ''>
        <cfset iseparator = ''>
        <cfloop query="getTaxa">
            <!--- Accumulate list of distinct taxon names --->
            <cfset ident = getTaxa.ident>
            <cfif Find(ident,idents) GT 0>
                <cfset idents = '#idents##iseparator##ident#'>
                <cfset iseparator = '; '>
            </cfif>
        </cfloop>

        <cfset rowCount = rowCount + 1>
    	<div style="#labelStyle# margin-bottom: 2mm; margin-right: 1.0in; font-size: 12pt;">
    		  <table >
    		      <tr>
    		         <td><span class="#textClass#" style="padding-bottom: 0px; margin-bottom:0px" >#header_text#<strong> #getItems.tray#</strong></span></td>
    		      </tr>
    		      <tr>
    		         <td><span class="#textClass#"><i>#idents#</i></span></td>
    		      </tr>
                  </table>
        </div>
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
       
       <!---  Iterate Through Trays, one label per tray, accumulating identifications in tray---> 
       <!---  taxa are distinct in query, just append them to list.  --->

    </cfloop>
    </cfoutput>
    </cfdocument>
</cfif>  <!-- End SCSlideTrayFront  -->

<cfinclude template="/includes/_pickFooter.cfm">
