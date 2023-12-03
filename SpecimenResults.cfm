<cfinclude template="/includes/_header.cfm">
<script type='text/javascript' language="javascript" src='/includes/SpecimenResults.js'></script>
<cfif len(session.displayrows) is 0>
	<cfset session.displayrows=20>
</cfif>
<cfhtmlhead text="<title>Specimen Results</title>">
<cfoutput>
<script type="text/javascript" language="javascript">
jQuery( function($) {

	$("##customizeButton").live('click', function(e){
		var bgDiv = document.createElement('div');
		bgDiv.id = 'bgDiv';
		bgDiv.className = 'bgDiv';
		bgDiv.setAttribute('onclick','closeCustomNoRefresh()');
		document.body.appendChild(bgDiv);
		var type=this.type;
		var type=$(this).attr('type');
		var dval=$(this).attr('dval');
		var theDiv = document.createElement('div');
		theDiv.id = 'customDiv';
		theDiv.className = 'customBox';
		document.body.appendChild(theDiv);
		var guts = "/info/SpecimenResultsPrefs.cfm";
		$('##customDiv').load(guts,{},function(){
			viewport.init("##customDiv");
			viewport.init("##bgDiv");
		});
	});

	$(".browseLink").live('click', function(e){
		var bgDiv = document.createElement('div');
		bgDiv.id = 'bgDiv';
		bgDiv.className = 'bgDiv';
		bgDiv.setAttribute('onclick','closeBrowse()');
		document.body.appendChild(bgDiv);
		var type=this.type;
		var type=$(this).attr('type');
		var dval=$(this).attr('dval');
		var theDiv = document.createElement('div');
		theDiv.id = 'browseDiv';
		theDiv.className = 'sscustomBox';
		theDiv.style.position="absolute";
		ih='<span onclick="closeBrowse()" class="likeLink" style="position:absolute;top:0;right:0;color:red;">Close Window</span>';
		ih+='<p>Search for ' + type + '....</p>'
		ih+='<p>LIKE <a href="/SpecimenResults.cfm?' + type + '=' + dval + '"> ' + decodeURI(dval) + '</a></p>';
		ih+='<p>IS <a href="/SpecimenResults.cfm?' + type + '==' + dval + '"> ' + decodeURI(dval) + '</a></p>';
		theDiv.innerHTML=ih;
		document.body.appendChild(theDiv);
		viewport.init("##browseDiv");
		viewport.init("##bgDiv");
	});
	$("##sPrefs").live('click',function(e){
		var id=this.id;
		var theDiv = document.createElement('div');
		theDiv.id = 'helpDiv';
		theDiv.className = 'helpBox';
		theDiv.innerHTML='<span onclick="removeHelpDiv()" class="docControl">X</span>';

		theDiv.innerHTML+='<label for="displayRows">Rows Per Page</label>';
		theDiv.innerHTML+='<select name="displayRows" id="displayRows" onchange="changedisplayRows(this.value);" size="1"><option <cfif #session.displayRows# is "10"> selected </cfif> value="10">10</option><option  <cfif #session.displayRows# is "20"> selected </cfif> value="20" >20</option><option  <cfif #session.displayRows# is "50"> selected </cfif> value="50">50</option><option  <cfif #session.displayRows# is "100"> selected </cfif> value="100">100</option></select>';
		var resultList=document.getElementById('resultList').value;
		var customID=document.getElementById('customID').value;
		var result_sort=document.getElementById('result_sort').value;
		var displayRows=document.getElementById('displayRows').value;

		theDiv.innerHTML+='<label for="result_sort">Primary Sort</label>';
		var temp='<select name="result_sort" id="result_sort" onchange=";changeresultSort(this.value);" size="1">';
		if (customID.length > 0) {
			temp+='<option value="' + customID + '">' + customID + '</option>';
		}
		var rAry=resultList.split(',');
		for (i = 0; i < rAry.length; i++) {
			temp+='<option value="' + rAry[i] + '">' + rAry[i] + '</option>';
		}
		temp+='</select>';
		theDiv.innerHTML+=temp;

		theDiv.innerHTML+='<label for="result_sort">Remove Rows</label>';
		var temp='<input type="checkbox" name="killRows" id="killRows" onchange=";changekillRows();" <cfif session.killrow is 1>checked="checked"</cfif>>';
		theDiv.innerHTML+=temp;
		theDiv.innerHTML+='<span style="font-size:small">(Requires Refresh)</span>';

		document.body.appendChild(theDiv);
		document.getElementById('result_sort').value=result_sort;
		document.getElementById('displayRows').value=displayRows;
		$("##helpDiv").css({position:"absolute", top: e.pageY, left: e.pageX});

	});
});
function closeBrowse(){
	var theDiv = document.getElementById('browseDiv');
	document.body.removeChild(theDiv);
	var theDiv = document.getElementById('bgDiv');
	document.body.removeChild(theDiv);
}
function removeHelpDiv() {
	if (document.getElementById('helpDiv')) {
		jQuery('##helpDiv').remove();
	}
}
</script>
</cfoutput>
<div id="loading" style="position:absolute;top:50%;right:50%;z-index:999;background-color:green;color:white;font-size:large;font-weight:bold;padding:15px;">
	Page loading....
</div>
<cfflush>
	<cfoutput>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset flatTableName = "flat">
<cfelse>
	<cfset flatTableName = "filtered_flat">
</cfif>
<cfif not isdefined("detail_level") OR len(#detail_level#) is 0>
	<cfif isdefined("session.detailLevel") AND #session.detailLevel# gt 0>
		<cfset detail_level = #session.detailLevel#>
	<cfelse>
		<cfset detail_level = 1>
	</cfif>
</cfif>
<cfif not isdefined("displayrows")>
	<cfset displayrows = session.displayrows>
</cfif>
<cfif not isdefined("SearchParams")>
	<cfset SearchParams = "">
</cfif>
<cfif not isdefined("sciNameOper")>
	<cfset sciNameOper = "LIKE">
</cfif>
<cfif not isdefined("oidOper")>
	<cfset oidOper = "LIKE">
</cfif>
<cfif not isdefined("mapurl")>
	<cfset mapurl = "null">
</cfif>
<cfif #action# contains ",">
	<cfset action = #left(action,find(",",action)-1)#>
</cfif>
<cfif #detail_level# contains ",">
	<cfset detail_level = #left(detail_level,find(",",detail_level)-1)#>
</cfif>

<!--- make sure session.resultColumnList has all the required stuff here --->
<cfif not isdefined("session.resultColumnList")>
	<cfset session.resultColumnList=''>
</cfif>
<cfquery name="r_d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select * from cf_spec_res_cols order by disp_order
</cfquery>
<cfquery name="reqd" dbtype="query">
	select * from r_d where category='required'  and column_name not in ('cat_num_prefix', 'cat_num_integer')
</cfquery>
<cfloop query="reqd">
	<cfif not ListContainsNoCase(session.resultColumnList,COLUMN_NAME)>
		<cfset session.resultColumnList = ListAppend(session.resultColumnList, COLUMN_NAME)>
	</cfif>
</cfloop>
<cfset basSelect = " SELECT distinct #session.flatTableName#.collection_object_id">
<cfif len(session.CustomOtherIdentifier) gt 0>
	<cfset basSelect = "#basSelect#
		,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		'#session.CustomOtherIdentifier#' as myCustomIdType,
		to_number(ConcatSingleOtherIdInt(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#')) AS CustomIDInt">
</cfif>
<cfloop query="r_d">
	<cfif left(column_name,1) is not "_" and (
		ListContainsNoCase(session.resultColumnList,column_name) OR category is 'required')>
		<cfset basSelect = "#basSelect#,#evaluate("sql_element")# #column_name#">
	</cfif>
</cfloop>

<!--- things that start with _ need special handling
they also need special handling at TAG:SORTRESULT (do find in this document)--->
<!--- this special handling is how to add it to the select statement --->
<!--- 
<cfif ListContainsNoCase(session.resultColumnList,"_elev_in_m")>
	<cfset basSelect = "#basSelect#,min_elev_in_m,max_elev_in_m">
</cfif>
--->
<cfif ListContainsNoCase(session.resultColumnList,"_day_of_ymd")>
	<cfset basSelect = "#basSelect#,getYearCollected(#session.flatTableName#.began_date,#session.flatTableName#.ended_date) YearColl,
		getMonthCollected(#session.flatTableName#.began_date,#session.flatTableName#.ended_date) MonColl,
		getDayCollected(#session.flatTableName#.began_date,#session.flatTableName#.ended_date) DayColl">
</cfif>
<cfif ListContainsNoCase(session.resultColumnList,"_original_elevation")>
	<cfset basSelect = "#basSelect#,MINIMUM_ELEVATION,MAXIMUM_ELEVATION,ORIG_ELEV_UNITS">
</cfif>
	<cfset basFrom = " FROM #session.flatTableName#">
	<cfset basJoin = "INNER JOIN cataloged_item ON (#session.flatTableName#.collection_object_id =cataloged_item.collection_object_id)">
	<cfset basWhere = " WHERE #session.flatTableName#.collection_object_id IS NOT NULL ">

	<cfset basQual = "">
	<cfset basOrder = "">
	<cfset mapurl="">
	<cfinclude template="includes/SearchSql.cfm">
	<!--- wrap everything up in a string --->
	<cfset SqlString = "#basSelect# #basFrom# #basJoin# #basWhere# #basQual# #basOrder#">

	<cfset sqlstring = replace(sqlstring,"flatTableName","#session.flatTableName#","all")>

<!---cfoutput>[#sqlstring#]</cfoutput--->

	<!--- require some actual searching --->
	<cfset srchTerms="">
	<cfloop list="#mapurl#" delimiters="&" index="t">
		<cfset tt=listgetat(t,1,"=")>
		<cfset srchTerms=listappend(srchTerms,tt)>
	</cfloop>
	<!--- remove standard criteria that kill Oracle... --->
	<cfif listcontains(srchTerms,"ShowObservations")>
		<cfset srchTerms=listdeleteat(srchTerms,listfindnocase(srchTerms,'ShowObservations'))>
	</cfif>
	<cfif listcontains(srchTerms,"collection_id")>
		<cfset srchTerms=listdeleteat(srchTerms,listfindnocase(srchTerms,'collection_id'))>
	</cfif>
	<!--- ... and abort if there's nothing left --->
	<cfif len(srchTerms) is 0>
		<CFSETTING ENABLECFOUTPUTONLY=0>
		<font color="##FF0000" size="+2">You must enter some search criteria!</font>
		<cfabort>
	</cfif>
<cfset thisTableName = "SearchResults_#cfid#_#cftoken#">
<!--- try to drop an existing temp table with this name --->
<cftry>
	<cftransaction>
	<cfquery name="tableexistscheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
		select count(*) as ct from user_tables where table_name = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.SpecSrchTab#">)
	</cfquery>
	<cfif tableexistscheck.ct EQ 0>
		<!--- not there, so what? --->
		<!--- expected condition for first search after login, no session search table. No action needed --->
	<cfelseif tableexistscheck.ct EQ 1>
		<!--- session search table exists, drop it to recreate with new search below --->
		<!--- Note: Drop of SpecSrchTab is used to generate query statistics from entries in dba_recyclebin --->
		<cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			drop table #session.SpecSrchTab#
		</cfquery>
	<cfelse>
		<!--- shouldn't be able to reach this block.  --->
		<cfthrow message="Error: More than one match to session.SpecSrchTab.">
	</cfif>
	</cftransaction>
	<cfcatch>
		<!--- if the session search table exists, the user should be able to delete it, if not, there is a problem --->
		<!--- Note: ORA-21561 would suggest a network name problem --->
		<cfrethrow> 
	</cfcatch>
</cftry>
<!---- build a temp table --->
<cfset checkSql(SqlString)>
<cfif isdefined("debug") and debug is true>
	#preserveSingleQuotes(SqlString)#
</cfif>
<!--- Note: SpecSrchTab is used to generate query statistics from entries in dba_recyclebin as well as passing search results --->
<cfset SqlString = "create table #session.SpecSrchTab# AS #SqlString#">
    <cfset linguisticFlag = false>
    <cfif isdefined("accentInsensitive") AND accentInsensitive EQ 1><cfset linguisticFlag=true></cfif>
    <cfif linguisticFlag >
        <cftransaction>
        <!--- Set up the session to run an accent insensitive search --->
        <cfquery  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            ALTER SESSION SET NLS_COMP = LINGUISTIC
        </cfquery>
        <cfquery  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            ALTER SESSION SET NLS_SORT = GENERIC_M_AI
        </cfquery> 
        <!--- Run the query --->
	<cfquery name="buildIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
		#preserveSingleQuotes(SqlString)#
	</cfquery>
        <!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. ---> 
        <cfquery  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            ALTER SESSION SET NLS_COMP = BINARY
        </cfquery>
        </cftransaction>
    <cfelse>
	<cfquery name="buildIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
		#preserveSingleQuotes(SqlString)#
	</cfquery>
    </cfif>
<form name="defaults">
	<input type="hidden" name="killrow" id="killrow" value="#session.killrow#">
	<input type="hidden" name="displayrows" id="displayrows" value="#session.displayrows#">
	<input type="hidden" name="action" id="action" value="#action#">
	<input type="hidden" name="mapURL" id="mapURL" value="#mapURL#">
	<cfset session.mapURL = mapURL>
	<cfif isdefined("transaction_id")>
			<input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
	</cfif>
	<cfif isdefined("loan_request_coll_id")>
			<input type="hidden" name="loan_request_coll_id" id="loan_request_coll_id" value="#loan_request_coll_id#">
	</cfif>
</form>
	<cfquery name="summary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
		select distinct collection_object_id from #session.SpecSrchTab#
	</cfquery>
<cfif summary.recordcount is 0>
	<script>
		hidePageLoad();
	</script>
	<div class="loading" style="position:relative; margin: 1.5em auto;width: 80%;z-index:999;background-color:white;color:##222;padding: 2% 10%;padding-bottom: 6em;">
		<div class="noResults">
		<h1>Your query returned no results.</h1>
		<h2>Tips:</h2>
			<p>Check your form input or use the "Clear Form" button to start over.</p>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			 <p>
				  MCZbase form fields may not be what you expect them to be.  See: <a href='https://code.mcz.harvard.edu/wiki/index.php/Glossary_of_MCZbase_Field_Names'>The glossary of MCZbase Field Names</a>.
			   </p>
			<cfelse>
		
		
			</cfif>
			<p>
				Use dropdowns or partial word matches instead of text strings, which may be entered in unexpected ways. Since the system relies on exact matches, "Doe" is a good choice for a collector if "John P. Doe" didn't match anything, for example. 
			</p>
			<p>See: <a href="/info/help.cfm?content=search_help">Additional Search Tips</a></p>
			<p>
				<a href="/contact.cfm">Contact us</a> if you still can't find what you need, and you think it is related to how you are using the form. We'll help if we can.
			</p>
			<h3>Taxonomy Searches</h3>
			<ul>
			<li>
				If you searched by taxonomy, consult the <a href="/Taxa.cfm">MCZbase Taxonomy</a>.
				Taxa are often synonymized and revised and may not be consistent across collections. Previous Identifications,
				which are separate from the taxonomy used in Identifications, may be located using the scientific name
				"is/was/cited/related" option.
			</li>
			</ul>
			<h3>Geography Searches</h3>
			<ul>
			<li>
				Try broadening your search criteria. Try the next-higher geographic element, remove search parameters, or use a substring match.
				Don't assume we've accurately or predictably recorded data.
			</li>
			<li>
				 Not all specimens have coordinates - the spatial query tool will not locate all specimens.
			</li>
			
		</ul>
		<h3>Unexpected results</h3>
		<p>Please note that not 100% of the MCZ collections have been fully databased. If you believe there may be material in the collections that satisfies your search criteria or are simply not getting the expected results, please feel free to contact the relevant department or departments. Emails are linked below:</p>
						<table>
							<tr><td><a href="mailto:mcz_cryogenics@fas.harvard.edu">Cryogenics</a></td>
								<td><a href="mailto:mcz_entomology@fas.harvard.edu">Entomology</a></td>
								<td><a href="mailto:mcz_herpetology@fas.harvard.edu">Herpetology</a></td>
								<td><a href="mailto:mcz_ichthyology@fas.harvard.edu">Ichthyology</a></td>
								<td><a href="mailto:mcz_invertebratepaleo@fas.harvard.edu">Invertebrate Paleontology</a></td>
							</tr>
							<tr><td><a href="mailto:mcz_invertebratezoology@fas.harvard.edu">Invertebrate Zoology</a></td><td><a href="mailto:mcz_malacology@fas.harvard.edu">Malacology</a></td><td><a href="mailto:mcz_mammalogy@fas.harvard.edu">Mammalogy</a></td><td><a href="mailto:mcz_ornithology@fas.harvard.edu">Ornithology</a></td><td><a href="mailto:mcz_vertebratepaleo@fas.harvard.edu>">Vertebrate Paleontology</a></td>
							</tr>
							
						</table>
						
						
	</div>
		</div>
	<cfabort>
</cfif>
<cfset collObjIdList = valuelist(summary.collection_object_id)>
<script>
	hidePageLoad();
</script>
<cfquery name="mappable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select count(distinct(collection_object_id)) cnt from #session.SpecSrchTab# where dec_lat is not null and dec_long is not null
</cfquery>

<form name="saveme" id="saveme" method="post" action="saveSearch.cfm" target="myWin">
	<input type="hidden" name="returnURL" value="#Application.ServerRootUrl#/SpecimenResults.cfm?#mapURL#" />
</form>
<!--- clean up things we'll let them sort by --->
<cfset resultList = session.resultColumnList>
<cfset tabooItems="institution_acronym,collection_id,collection_cde">
<cfloop list="#tabooItems#" index="item">
		<cfif ListContainsNoCase(resultList,item)>
		<cfset resultList = ListDeleteAt(resultList, ListFindNoCase(resultList,item))>
	</cfif>
</cfloop>
<!--- things that start with _ require special handling here as well --->
<!--- TAG:SORTRESULT
if you have an item that starts with _, you must change how it is sorted!
For example, if your item cannot be sorted, then remove it from resultList.
If your item needs to be sorted in a special way, then do that here. --->
<cfif ListContainsNoCase(resultList,"_elev_in_m")>
<cfflush>
	<cftry>
        <!-- 
        // This looks like a remaining element of a previous? generalized add/remove elevation in meters control
	<cfset resultList = listappend(resultList,"min_elev_in_m")>
	<cfset resultList = listappend(resultList,"max_elev_in_m")>
        -->
	<cfset resultList = ListDeleteAt(resultList, ListFindNoCase(resultList,"_elev_in_m"))>
	<cfcatch></cfcatch>
	</cftry>
</cfif>
<cfif ListContainsNoCase(resultList,"_original_elevation")>
	<cftry>
	<cfset resultList = listappend(resultList,"minimum_elevation")>
	<cfset resultList = listappend(resultList,"maximum_elevation")>
	<cfset resultList = listappend(resultList,"orig_elev_units")>
	<cfset resultList = ListDeleteAt(resultList, ListFindNoCase(resultList,"_original_elevation"))>
	<cfcatch></cfcatch>
	</cftry>
</cfif>
<form name="controls">
	<!--- keep stuff around for JS to get at --->
	<input type="hidden" name="resultList" id="resultList" value="#resultList#">
	<input type="hidden" name="customID" id="customID" value="#session.customOtherIdentifier#">
	<input type="hidden" name="result_sort" id="result_sort" value="#session.result_sort#">
	<input type="hidden" name="displayRows" id="displayRows" value="#session.displayRows#">
       <p style="margin-left: 5px;padding-top: 0em;"><strong>#mappable.cnt#</strong> of these <strong>#summary.recordcount#</strong> records have coordinates
        <cfif #mappable.cnt# gt 0>
          and can be displayed with
			<span class="controlButton"
				onclick="window.open('/bnhmMaps/bnhmMapData.cfm?#mapurl#','_blank');">BerkeleyMapper</span>
			<span class="controlButton"
				onclick="window.open('/bnhmMaps/bnhmMapData.cfm?showRangeMaps=true&#mapurl#','_blank');">BerkeleyMapper+Rangemaps</span>
			<span class="infoLink" onclick="getDocs('maps');">
				What's this?
			</span>
			<a href="bnhmMaps/kml.cfm">Google Earth/Maps</a>
            <cfelse></cfif>
			<a href="SpecimenResultsHTML.cfm?#mapurl#" class="infoLink" style="display:block;">Problems viewing this page? Click for HTML version</a>
         <cfif isDefined("session.username") AND len(session.username) gt 0>
				<a class="infoLink" href="/info/reportBadData.cfm?collection_object_id=#collObjIdList#">Report Bad Data</a>	
			</cfif>
		</p>
<div class="topBlock" id="ssControl">
<cfif isdefined("transaction_id") and #action# is "dispCollObj">
	<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">Back to Loan</a>
    <cfelseif isdefined("transaction_id") and #action# is "dispCollObjDeacc">
    <a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#transaction_id#">Back to Deaccession</a>
</cfif>
<table border="0">
	<tr>
		<td>
		<!--- the function accepts:
				startrow <- first record of the page we want to view
				numRecs <- session.displayrows
				orderBy < current values from dropdown
		--->
		<cfset numPages= ceiling(summary.recordcount/session.displayrows)>
		<cfset loopTo=numPages-2>
		<label for="page_record">Records...</label>
		<select name="page_record" id="page_record" size="1" onchange="getSpecResultsData(this.value);">
			<cfloop from="0" to="#loopTo#" index="i">
				<cfset bDispVal = (i * session.displayrows + 1)>
				<cfset eDispval = (i + 1) * session.displayrows>
				<option value="#bDispVal#,#session.displayrows#">#bDispVal# - #eDispval#</option>
			</cfloop>
			<!--- last set of records --->
			<cfset bDispVal = ((loopTo + 1) * session.displayrows )+ 1>
			<cfset eDispval = summary.recordcount>
			<option value="#bDispVal#,#session.displayrows#">#bDispVal# - #eDispval#</option>
			<!--- all records --->
			<option value="1,#summary.recordcount#">1 - #summary.recordcount#</option>
		</select>

		</td>
		<td nowrap="nowrap">
			<label for="orderBy1">Order by...</label>
			<select name="orderBy1" id="orderBy1" size="1" onchange="changeresultSort(this.value)">
				<!--- prepend their CustomID and integer sort of their custom ID to the list --->
				<cfif len(session.CustomOtherIdentifier) gt 0>
					<option <cfif session.result_sort is "custom_id">selected="selected" </cfif>value="CustomID">#session.CustomOtherIdentifier#</option>
					<option value="CustomIDInt">#session.CustomOtherIdentifier# (INT)</option>
				</cfif>
				<cfloop list="#resultList#" index="i">
					<option <cfif #session.result_sort# is #i#>selected="selected" </cfif>value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
		<td>
			<label for="orderBy2">...then order by</label>
			<select name="orderBy2" id="orderBy2" size="1">
				<cfloop list="#resultList#" index="i">
					<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
		<td>
			<label for="">&nbsp;</label>
			<span class="controlButton"
				onmouseover="this.className='controlButton btnhov'"
				onmouseout="this.className='controlButton'"
				onclick="var pr=document.getElementById('page_record');
					var c=pr.value;
					var obv=document.getElementById('orderBy1').value + ',' + document.getElementById('orderBy2').value;
					if (c=='1,#summary.recordcount#')
						{var numRec=#summary.recordcount#}else{var numRec=#session.displayrows#;pr.selectedIndex=0;};
						getSpecResultsData(1,numRec,obv,'ASC');">&uarr;</span>
		</td>
		<td>
			<label for="">&nbsp;</label>
			<span class="controlButton"
				onmouseover="this.className='controlButton btnhov'"
				onmouseout="this.className='controlButton'"
				onclick="var pr=document.getElementById('page_record');
					var c=pr.value;
					var obv=document.getElementById('orderBy1').value + ',' + document.getElementById('orderBy2').value;
					if (c=='1,#summary.recordcount#')
						{var numRec=#summary.recordcount#}else{var numRec=#session.displayrows#;pr.selectedIndex=0;};
					getSpecResultsData(1,numRec,obv,'DESC');">&darr;</span>
		</td>
		<td>
			<span id="sPrefs" class="infoLink">Settings...</span>
		</td>
		<td><div style="width:10px;">&nbsp;</div></td>
		<td>
			<label for="">&nbsp;</label>
			<input type="hidden" name="killRowList" id="killRowList">
			<span id="removeChecked"
				style="display:none;"
				class="controlButton"
				onmouseover="this.className='controlButton btnhov'"
				onmouseout="this.className='controlButton'"
				onclick="removeItems();">Remove&nbsp;Checked</span>
		</td>
		<td>
			<label for="">&nbsp;</label>
			<span class="controlButton" id="customizeButton">Customize&nbsp;Form</span>
			<!----onclick="openCustomize();"---->
		</td>
		<td>
			<label for="">&nbsp;</label>
			<span class="controlButton"
							onmouseover="this.className='controlButton btnhov'"
				onmouseout="this.className='controlButton'"
				onclick="window.open('/SpecimenResultsDownload.cfm?tableName=#session.SpecSrchTab#','_blank');">Download</span>
		</td>
		<td>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")><label for="">&nbsp;</label>
			<span class="controlButton"
			onmouseover="this.className='controlButton btnhov'"
				onmouseout="this.className='controlButton'"
                  onclick="saveSearch('#Application.ServerRootUrl#/SpecimenResults.cfm?#mapURL#');">Save Search</span></cfif>
		</td>
		<td nowrap="nowrap">
			<cfif summary.recordcount lt 1000 and (isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
				<label for="goWhere">Manage results by...</label>
				<select name="goWhere" id="goWhere" size="1">
               <option value="/bulkCollEvent.cfm"><!--- works only with collection_object_id --->
						Collecting Events
					</option>
					<option value="/bulkLocality.cfm"><!--- works only on session_search table, passed as table_name --->
						Localities [Warning: No Tabs]
					</option>
					<!--- 
					<option value="/specimens/changeQueryIdentification.cfm"><!--- works only with collection_object_id --->
						Identification
					</option>
					--->
					<option value="/tools/downloadParts.cfm"><!--- works only on session search table, passed as table_name --->
						Parts (Report) [Warning: No Tabs]
					</option>
					<option value="/findContainer.cfm?showControl=1"><!--- looks like it works only with collection_object_id, but downstream code has reference to session.username and passed table name --->
						Parts (Locations)
					</option>
					<option value="/specimens/changeQueryParts.cfm"><!--- works only on session search table, passed as table_name --->
						Parts (Modify) [Warning: No Tabs]
					</option>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						<option value="/grouping/addToNamedCollection.cfm"><!--- works with either, collection_objecT_id has priority, session search table looked up, not passed --->
							Add To Named Group [Warning: No Tabs]
						</option>
					</cfif>
               <option value="/Reports/report_printer.cfm?collection_object_id=#collObjIdList#"><!--- works only with collection_object_id --->
						Print Any Report
					</option>
				</select>
				<input type="button"
					value="Go"
					class="lnkBtn"
		   			onmouseover="this.className='lnkBtn btnhov'"
					onmouseout="this.className='lnkBtn'"
					onClick="reporter();">
			</cfif>
		</td>
	</tr>
</table>
</div>
</form>

<div id="resultsGoHere"></div>
<script language="javascript" type="text/javascript">
	getSpecResultsData(1,#session.displayrows#);
</script>
<script language="javascript" type="text/javascript">
	function reporter() {
		var f=document.getElementById('goWhere').value;
		var t='#session.SpecSrchTab#';
		var o1=document.getElementById('orderBy1').value;
		var o2=document.getElementById('orderBy2').value;
		var s=o1 + ',' + o2;
		var u = f;
		var sep="?";
		if (f.indexOf('?') > 0) {
			sep='&';
		}
		var lla='#collObjIdList#'.split(',');
		var i;
		if (lla.length>999){
			i='';
		} else {
			i='#collObjIdList#';
		}
		if (f=='/grouping/addToNamedCollection.cfm') {
			// leave off list of collection object ids.
		} else { 
			u += sep + 'collection_object_id=' + i;
			u += '&table_name=' + t;
			u += '&sort=' + s;
		}
		var reportWin=window.open(u);
	}

</script>
</cfoutput>
<!---
<cf_get_footer collection_id="#session.exclusive_collection_id#">
--->
<cfinclude template = "includes/_footer.cfm">
