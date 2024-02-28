<cffunction name="getEditCitationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">	
	<cfthread name="getEditCitationsThread">
		<cfoutput>
			<cftry>
					<div id="citationsDialog">

						<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									citation.type_status,
									citation.occurs_page_number,
									citation.citation_page_uri,
									citation.CITATION_REMARKS,
									cited_taxa.scientific_name as cited_name,
									cited_taxa.taxon_name_id as cited_name_id,
									formatted_publication.formatted_publication,
									formatted_publication.publication_id,
									cited_taxa.taxon_status as cited_name_status
								from
									citation,
									taxonomy cited_taxa,
									formatted_publication
								where
									citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
									citation.publication_id = formatted_publication.publication_id AND
									format_style='short' and
									citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								order by
									substr(formatted_publication, - 4)
						</cfquery>
							<cfset i = 1>
							<cfloop query="citations" group="formatted_publication">
								<div class="d-block py-1 px-2 w-100 float-left">
									<span class="d-inline"></span>
									<a href="/publications/showPublication.cfm?publication_id=#publication_id#" target="_mainFrame">#formatted_publication#</a>,
									<cfif len(occurs_page_number) gt 0>
										Page
										<cfif len(citation_page_uri) gt 0>
											<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
										<cfelse>
										#occurs_page_number#,
										</cfif>
									</cfif>
									<span class="font-weight-lessbold">#type_status#</span> of 
										<a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
										<cfif find("(ms)", #type_status#) NEQ 0>
										<!--- Type status with (ms) is used to mark to be published types, for which we aren't (yet) exposing the new name.  Append sp. nov or ssp. nov.as appropriate to the name of the parent taxon of the new name --->
											<cfif find(" ", #cited_name#) NEQ 0>
											&nbsp;ssp. nov.
											<cfelse>
											&nbsp;sp. nov.
											</cfif>
										</cfif>
										<span class="small font-italic">
											<cfif len(citation_remarks) gt 0></cfif>
											#CITATION_REMARKS#
										</span>
								</div>
								<cfset i = i + 1>
							</cfloop>
		
					</div>
				<cfcatch>
					<cfif isDefined("cfcatch.queryError") >
						<cfset queryError=cfcatch.queryError>
						<cfelse>
						<cfset queryError = ''>
					</cfif>
					<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfcontent reset="yes">
					<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getEditCitationsThread" />
	<cfreturn getEditCitationsThread.output>
</cffunction>
