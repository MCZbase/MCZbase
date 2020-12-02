<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">

<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>
			<div class="accordion w-100" id="accordionForTaxa">
				<cfif qsubspecies.recordcount LT 10 AND qspecies.recordcount LT 10>
					<cfset collapsed = "">
					<cfset collapseshow = "collapse show">
				<cfelse>
					<cfset collapsed = "collapsed">
					<cfset collapseshow = "collapse">
				</cfif>
				<div class="card mb-2">
					<div class="card-header w-100" id="headingPart">
						<h2 class="h4 my-0 float-left">  
							<a class="btn-link text-black #collapsed#" role="button" data-toggle="collapse" data-target="##collapseRelatedTaxa">
								Bulk Add New Parts to Existing Specimen Records
							</a>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseRelatedTaxa" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
							<div class="row">
								<div class="col-12 col-lg-6">
									<div class="accordion w-100" id="accordionForTaxa">
										<!--- included subspecies --->
										<cfquery name="qsubspecies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
											select 
												scientific_name, display_name, author_text
											from 
												taxonomy 
											where
												 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
												 species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and 
												 subspecies is not null and
												 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
											order by
												scientific_name
										</cfquery>
										<!--- congeneric species --->
										<cfquery name="qspecies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
											select 
												scientific_name,
												display_name 
											from 
												taxonomy 
											where
												 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
												 species != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and
												 subspecies is null and 
												 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
											order by
												scientific_name
										</cfquery>
										<cfif qsubspecies.recordcount LT 10 AND qspecies.recordcount LT 10>
											<cfset collapsed = "">
											<cfset collapseshow = "collapse show">
										<cfelse>
											<cfset collapsed = "collapsed">
											<cfset collapseshow = "collapse">
										</cfif>
										<div class="card mb-2">
											<div class="card-header w-100" id="headingPart">
												<h2 class="h4 my-0 float-left">  
													<a class="btn-link text-black #collapsed#" role="button" data-toggle="collapse" data-target="##collapseRelatedTaxa">
														Related Taxon Records (#qsubspecies.recordcount# subspecies, #qspecies.recordcount# species): 
													</a>
												</h2>
											</div>
											<div class="card-body px-3 py-0">
												<div id="collapseRelatedTaxa" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
													<div class="row">
														<div class="col-12 col-lg-6">
															<br>
															<cfif qspecies.recordcount EQ 0>No</cfif>
															Congeneric Species:
															<ul>
																<cfloop query="qspecies">
																	<li><a href="/name/#scientific_name#">#display_name#</a></li>
																</cfloop>
															</ul>
														</div>
														<div class="col-12 col-lg-6">
															<br>
															<cfif qsubspecies.recordcount EQ 0>No</cfif>
															<cfif len(t.subspecies) gt 0>Included </cfif>Subspecies:
															<ul>
																<cfloop query="qsubspecies">
																	<li><a href="/name/#scientific_name#">#display_name# <span class="sm-caps">#qsubspecies.author_text#</span></a></li>
																</cfloop>
															</ul>
														</div>
													</div>
												</div><!--- collapseRelatedTaxa --->
											</div>
										</div>
									</div><!--- accordion --->
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</section>
</main>
<cfinclude template = "/shared/_footer.cfm">
