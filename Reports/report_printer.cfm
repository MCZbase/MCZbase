<cfoutput>
<cfif not isdefined("collection_object_id")>
    <cfset collection_object_id="">
</cfif>
<cfif not isdefined("transaction_id")>
    <cfset transaction_id="">
</cfif>
<cfif not isdefined("container_id")>
    <cfset container_id="">
</cfif>
<cfif not isdefined("sort")>
    <cfset sort="">
</cfif>
<cfif not isdefined("show_all")>
    <cfset show_all = "false" >
</cfif>
<cfinclude template="/includes/_header.cfm">
<cfinclude template="/Reports/functions/label_functions.cfm">

<cfif #action# is "nothing">
	<!--- Obtain a list of reports that contain the limit_preserve_method marker --->
	<cfquery name="preservationRewrite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select report_name 
		from cf_report_sql 
		where 
			sql_text like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%-- ##limit_preserve_method##%">
	</cfquery>
	<!--- Obtain a list of reports that contain the limit_part_name marker --->
	<cfquery name="partnameRewrite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select report_name 
		from cf_report_sql 
		where 
			sql_text like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%-- ##limit_part_name##%">
	</cfquery>
	<cfif isdefined("report") and len(#report#) gt 0>
		<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select report_id 
			from cf_report_sql 
			where 
				upper(report_name)=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(report)#">
		</cfquery>
		<cfif id.recordcount is 1 and id.report_id gt 0>
			<cflocation url='report_printer.cfm?action=print&report_id=#id.report_id#&collection_object_id=#collection_object_id#&container_id=#container_id#&transaction_id=#transaction_id#&sort=#sort#'>
		<cfelse>
			<div class="error">
				You tried to call this page with a report name, but that failed.
			</div>
		</cfif>
	</cfif>
	<a href="reporter.cfm" target="_blank">Manage Reports</a><br/>
	<!-- Obtain the list of reports -->
	<cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	   select * 
		from cf_report_sql 
		where report_name not like 'mcz_%' 
		order by report_name
	</cfquery>
	<!-- Obtain a list of collection codes for which this user has expressed a preference for seeing label reports for -->
	<cfquery name="usersColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select reportprefs 
			from CF_USERS 
			where 
				username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfset collList = []>
	<cfloop query="usersColls">
		<cfset collList = listToArray("#reportprefs#") >
	</cfloop>
    <!-- Add the All code so that reports in the form __All will be shown to everyone.  -->
	<cfset added = ArrayPrepend(collList,"All") >


	<form name="print" id="print" method="post" action="report_printer.cfm">
	    <input type="hidden" name="action" value="print">
	    <input type="hidden" name="transaction_id" value="#transaction_id#">
	    <input type="hidden" name="container_id" value="#container_id#">
	    <input type="hidden" name="collection_object_id" value="#collection_object_id#">
	    <label for="report_id">Print....</label>
        <table border='0'>
           <tr>
             <td>
		<select name="report_id" id="report_id" size="36">
		   <cfloop query="e">
			   <cfset show = 0 >
			   <!--
			      Take the part of the report name after the double underscore,
			      then explode the collection codes in it on underscores
			   -->
               <cfset repBit = REMatch('__[a-zA-Z_]+$',#report_name#)>
               <cfif NOT ArrayIsEmpty(repBit)>
			   <cfset repList = listToArray(#repBit[1]#,"_",true)>

			   <!--  If the report name includes a collection code in the user's list, then show it. -->
               <cfloop index="element" array="#repList#">
                  <cfloop index="cel" array="#collList#">
                     <cfif cel EQ element >
                        <cfset show = 1 >
                     </cfif>
                  </cfloop>
               </cfloop>
			   </cfif>
               <!-- Show only reports for users collections, unless showAll is set -->
			   <cfif (#show# EQ 1) || (#show_all# is "true") >
		          <option value="#report_id#">#report_name#</option>
		       </cfif>
		   </cfloop>
		</select>
                <!--- Compile a list of reports that cotain the limit_preserve_method marker, 
                      for only those reports show the picklist of preservation types --->
                <cfset reportsWithPreserveRewrite = "">
                <cfset rwprSeparator = "">
                <cfloop query="preservationRewrite">
                   <cfset reportsWithPreserveRewrite = "#reportsWithPreserveRewrite##rwprSeparator##preservationRewrite.report_name#" >
                   <cfset rwprSeparator = "|">
                </cfloop>
                <cfif len(#reportsWithPreserveRewrite#) GT 0>
                   <cfset reportsWithPreserveRewrite = "(#reportsWithPreserveRewrite#)">
		          </cfif>
                <!--- Compile a list of reports that cotain the limit_preserve_method marker, 
                      for only those reports show the picklist of preservation types --->
                <cfset reportsWithPartNameRewrite = "">
                <cfset rwprSeparator = "">
                <cfloop query="partnameRewrite">
                   <cfset reportsWithPartNameRewrite = "#reportsWithPartNameRewrite##rwprSeparator##partnameRewrite.report_name#" >
                   <cfset rwprSeparator = "|">
                </cfloop>
                <cfif len(#reportsWithPartNameRewrite#) GT 0>
                   <cfset reportsWithPartNameRewrite = "(#reportsWithPartNameRewrite#)">
		          </cfif>
                <script>
                    	$("##report_id").change( function () { 
                           var sel = $(this).find(":selected").text();
                           var match = sel.match(/^#reportsWithPreserveRewrite#$/);
                           if (match!=null && match.length>0) { 
                              $("##preserve_limit_section").show();
                           } else { 
                              $("##preserve_limit_section").hide();
                           }
                           var match = sel.match(/^#reportsWithPartNameRewrite#$/);
                           if (match!=null && match.length>0) { 
                              $("##part_name_limit_section").show();
                           } else { 
                              $("##part_name_limit_section").hide();
                           }

                           $.getJSON("/component/functions.cfc",
                            {
                              method : "getReportDescription",
                              report_id : sel,
                              returnformat : "json",
                              queryformat : 'column'
                            },
                            function (r){
                               var result=r.DATA;
                               var description=result.DESCRIPTION;
                               if (description.length==0) {
                                   description = 'No Description';
                               }
                               if (result!=null) { 
                                  $("##report_description_section").show();
                                  $("##report_description_section").html(' ' + description);
                               }
                            }
                           );
                       });
                </script>
				<script>
					jQuery(document).ready(function() {
						$("##preserve_limit_section").hide();
						$("##part_name_limit_section").hide();
					});
				</script>
			</td>
			<td style='vertical-align: top;'>
				<input type="submit" value="Print Report">
					<div id="preserve_limit_section">
						<cfif isdefined("collection_object_id") and len(#collection_object_id#) gt 0>
							<label for="preserve_limit">Limit to Preservation Type:</label>
							<cfquery name="partsList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(*) as ct, preserve_method 
								from specimen_part
								left join cataloged_item on derived_from_cat_item = cataloged_item.collection_object_id
								where 
									cataloged_item.collection_object_id in
									( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes"> )
								group by preserve_method
							</cfquery>
							<select name="preserve_limit" id="preserve_limit">
								<option value="">All</option>
								<cfloop query="partsList">
									<option value="#preserve_method#">#preserve_method# (#ct#)</option>
								</cfloop>
							</select>
						</cfif>
						<p>Many reports are configured to limit printing of labels to a class of preservation type (e.g. fluid or dry), but will print one label for each preservation type in that class.  In some cases it is desirable to print reports for only one particular preservation type.  Reports that have been configured to also use this pick list can limit labels to a single preservation type (e.g 70% ethanol).  If you pick "All", one label will be printed for each part with the preservation type allowed for by the label (e.g. any fluid type).  If you pick a specific preservation type from the picklist, one label will be printed for each part with the preservation type that you picked.  This pick list further filters rather than overiding the preservation types allowed by the selected report, if you pick "Dry", or another preservation type that is not normally included on that particular label report, for a Fluid label, you will get an empty report. </p><!--- ; --->
					</div>
					<div id="part_name_limit_section">
						<cfif isdefined("collection_object_id") and len(#collection_object_id#) gt 0>
							<label for="part_name_limit">Limit to Part Name:</label>
							<cfquery name="partNameList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(*) as ct, part_name
								from specimen_part
								left join cataloged_item on derived_from_cat_item = cataloged_item.collection_object_id
								where 
									cataloged_item.collection_object_id in
									( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes"> )
								group by part_name 
							</cfquery>
							<select name="part_name_limit" id="part_name_limit">
								<option value="">All</option>
								<cfloop query="partNameList">
									<option value="#part_name#">#part_name# (#ct#)</option>
								</cfloop>
							</select>
						</cfif>
						<p>In some cases, for reports that print one label per part, it is desirable to print reports for only one part name.  Reports that have been configured to also use this pick list can limit labels to a single part name (e.g whole animal).  If you pick "All", one label will be printed for each part.  If you pick a specific part name from the picklist, one label will be printed for each part (possibly also limited to a selected preservation type) that you picked.  This pick list further filters rather than overiding the preservation types allowed by the selected report.</p>
					</div>
					<div id="report_description_section">Select a report from the list.</div>
				</td>
			</tr>
		</table>
	</form>
    <cfif NOT show_all is "true">
           Only reports relevant to collections you work with are shown<br/>
        <a href='report_printer.cfm?&show_all=true&collection_object_id=#collection_object_id#&container_id=#container_id#&transaction_id=#transaction_id#&sort=#sort#'>Show all Reports</a>
    <cfelse>
        <a href='report_printer.cfm?&show_all=false&collection_object_id=#collection_object_id#&container_id=#container_id#&transaction_id=#transaction_id#&sort=#sort#'>Show just reports for my collections</a>
    </cfif>
	<div>See the <a href="/Reports/listReports.cfm" target="_blank">summary of all reports</a> to see descriptions of all reports.</div>
</cfif>
<!------------------------------------------------------>
<cfif #action# is "print">
	<cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * 
		from cf_report_sql 
		where 
			report_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#report_id#">
	</cfquery>
	<cfif len(e.sql_text) gt 0>
                <!--- The query to obtain the report data is in cf_report_sql.sql_text --->
		<cfset sql=e.sql_text>
                <cfif sql contains "##transaction_id##">
			yeppers
			<cfset sql=replace(sql,"##transaction_id##",#transaction_id#,"all")>
		<cfelse>
			noper
		</cfif>
		<cfif sql contains "##collection_object_id##">
			<cfset sql=replace(sql,"##collection_object_id##",#collection_object_id#,"All")>
		</cfif>
                <!---  Include comment and the special tag '#limit_preserve_method#' 
                       to allow optional insertion of a preservation type limit on the report query 
                       in the form "-- #limit_preserve_method#" as a where clause other than the last where clause in the query.
                --->
                <cfif sql contains "-- ##limit_preserve_method##">
                   <cfif isdefined("preserve_limit") and len(#preserve_limit#) gt 0>
                        <cfset sql=replace(sql,"-- ##limit_preserve_method##","specimen_part.preserve_method = '#preserve_limit#' AND ","All")>
                   <cfelse>
                        <cfset sql=replace(sql,"-- ##limit_preserve_method##",'',"All")>
                   </cfif>
                </cfif>
                <!---  Include comment and the special tag '#limit_part_name#' 
                       to allow optional insertion of a preservation type limit on the report query 
                       in the form "-- #limit_part_name#" as a where clause other than the last where clause in the query.
                --->
                <cfif sql contains "-- ##limit_part_name##">
                   <cfif isdefined("part_name_limit") and len(#part_name_limit#) gt 0>
                        <cfset sql=replace(sql,"-- ##limit_part_name##","specimen_part.part_name = '#part_name_limit#' AND ","All")>
                   <cfelse>
                        <cfset sql=replace(sql,"-- ##limit_part_name##",'',"All")>
                   </cfif>
                </cfif>
		<cfif sql contains "##container_id##">
			<cfset sql=replace(sql,"##container_id##",#container_id#)>
		</cfif>

		<cfif sql contains "##session.CustomOtherIdentifier##">
			<cfset sql=replace(sql,"##session.CustomOtherIdentifier##",#session.CustomOtherIdentifier#,"all")>
		</cfif>
		<cfif sql contains "##session.SpecSrchTab##">
			<cfset sql=replace(sql,"##session.SpecSrchTab##",#session.SpecSrchTab#,"all")>
		</cfif>
		<cfif sql contains "##session.projectReportTable##">
			<cfset sql=replace(sql,"##session.projectReportTable##",#session.projectReportTable#,"all")>
		</cfif>


		<cfif len(#sort#) gt 0 and #sql# does not contain "order by">
                        <cfif #sort# eq "cat_num_pre_int"> 
  			    <cfset ssql=sql & " order by cat_num_prefix, cat_num_integer ">
                        <cfelse>
  			    <cfset ssql=sql & " order by #sort#">
                        </cfif>
		<cfelse>
			<cfset ssql=sql>
		</cfif>
		<hr>#ssql#<hr>
	 	<cftry>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				#preservesinglequotes(ssql)#
			</cfquery>
		<cfcatch>
			<!--- sort can fail here, or below where d is sorted, if they try to sort by things that are not in the query --->
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				#preservesinglequotes(sql)#
			</cfquery>
		</cfcatch>
		</cftry>
    <cfelse>
        <!--- cf_report_sql.sql_text is null --->
        <!--- need something to pass to the function --->
        <cfset d="">
    </cfif>

    <!---  Can call a custom function here to obtain or transform the query --->
    <cfif len(e.pre_function) gt 0>
        <!---  e.sql may be empty and e.pre_function may point to a query from a CustomTag --->
        <!---  The query for loan invoices comes from a CustomTag --->
        <!---  Other reports may have a query in e.sql and have it modified by e.pre_function --->
        <cfset d=evaluate(e.pre_function & "(d)")>
    </cfif>

    <!---  Add the sort if one is not present (to add a sort to a query from CustomTags --->
    <!---  Supports sort order on loan invoice --->
    <cfif len(#sort#) gt 0 and #d.getMetaData().getExtendedMetaData().sql# does not contain " order by ">
         <cfif #sort# eq "cat_num_pre_int"> 
				<cfset comparator = function(item1, item2) { 
					i = compare(item1['cat_num_prefix'],item2['cat_num_prefix']); 
					if (i!=0) return i;
					return compare(item1['cat_num_integer'],item2['cat_num_integer']); 
				} >
         <cfelse>
				<cfset comparator = function(item1, item2) { return compare(item1['#sort#'],item2['#sort#']); } >
         </cfif>
			<cfset QuerySort(d,comparator)>
    </cfif>

    <cfif e.report_format is "pdf">
		<cfset extension="pdf">
    <cfelseif e.report_format is "RTF">
		<cfset extension="rtf">
    <cfelse>
		<cfset extension="rtf">
    </cfif>
    <cfreport format="#e.report_format#"
    	template="#application.webDirectory#/Reports/templates/#e.report_template#"
        query="d"
        overwrite="true"></cfreport>
</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
