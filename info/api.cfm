<cfset pageTitle = "MCZbase API summary.">
<cfinclude template="/shared/_header.cfm">
       
<cfif isdefined("url.action")>
	<cfset action = url.action>
<cfelse>
	<cfset action = "entryPoint">
</cfif>

<cfoutput>
	<main class=”container” id=”content”>
		<section class=”row” >
        
<cfif action is "entryPoint">
 
	<h2 class="h2">
		Partial list of ways to talk to MCZbase
	</h2>
	<!--- p>
		You may search specimens using the <a href="/api/specsrch">SpecimenResults.cfm API</a>. 
	</p --->
	<p>
		You may open KML files of MCZbase data using the <a href="/api/kml">KML API</a>. 
	</p>
	You may link to specimens with any of the following:
		<ul class="labels">
			<li>
				#Application.serverRootUrl#/guid/{institution}:{collection}:{catnum}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/guid/MCZ:Mamm:1
					</li>
					<li>
						This URI returns html by default, but can return RDF via content negotiation, include an http accept header for 'text/turtle' or 'application/rdf+xml' or 'application/ld+json'
					</li>
				</ul>
				<br>
			</li>
			<li>
				#Application.serverRootUrl#/specimen/{institution}/{collection}/{catnum}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/specimen/MCZ/Mamm/1
					</li>
				</ul>
				<br>
			</li>
			<!--- look up an occurrenceID from guid_our_thing --->
			<cfquery name="occID" datasource="cf_dbuser">
				SELECT local_identifier
				FROM guid_our_thing
				WHERE guid_is_a = 'occurrenceID'
					and scheme = 'urn' 
					and type = 'uuid'
				FETCH FIRST 1 ROW ONLY
			</cfquery>
			<cfif occID.recordcount GT 0>
			<li>
				#Application.serverRootUrl#/uuid/{uuid:uuid:occurrenceID or materialSampleID}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/uuid/#local_identifier#>
					</li>
					<li>
						This uri delivers a human readable html representation by default, but it also supports content negotiation with an http accept header for RDF representations with 'text/turtle' or 'application/rdf+xml' or 'application/ld+json'
					</li>
					<li>
						To request RDF in a specific format, you may also append /turtle, /rdf, or /json to the URI.
					</li>
					<li>
						Example RDF in a Turtle serialization : #Application.serverRootUrl#/uuid/#local_identifier#/turtle
					</li>
					<li>
						Example RDF in a JSON-LD serialization: #Application.serverRootUrl#/uuid/#local_identifier#/json-ld
					</li>
					<li>
						Example RDF in an RDF/XML serialization: #Application.serverRootUrl#/uuid/#local_identifier#/xml
					</li>
				</ul>
				<br>
			</li>
			</cfif>
			<li>
				#Application.serverRootUrl#/rdf/Occurrence.cfm?guid={institution}:{collection}:{catnum}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/rdf/Occurrence.cfm?guid=MCZ:Mamm:1
					</li>
					<li>
						This URI returns rdf-xml by default, but can deliver turtle or json-ld via content negotiation, include an http accept header for 'text/turtle' or 'application/ld+json'.
					</li>
				</ul>
				<br>
			</li>
		</ul>
	or through Saved Searches (find specimens, click Save Search, provide a name, then click My Stuff/Saved Searches, then 
	copy/paste/email/click the links.)
	<p>
		You may search taxonomy using the <a href="/api/taxsrch">Taxonomy API</a>. 
	</p>
	<p>
		You may link to taxon detail pages with URLs of the format:
		<ul class="labels">
			<li>
				#Application.serverRootUrl#/name/{taxon name}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/name/Alces alces
					</li>
				</ul>
			</li>
		</ul>		
	</p>
	<p>
		You may search Media using the <a href="/api/mediasrch">MediaSearch.cfm API</a>
	</p>
	<p>
		You may download the complete public MCZ data set from 
        our <a href='http://digir.mcz.harvard.edu/ipt/resource.do?r=mczbase'>IPT instance</a> DOI <a href='http://doi.org/10.15468/p5rupv'>doi:10.15468/p5rupv</a>.
	</p>
	<!--- 
	<p>
		You may link to specific <a href="/api/collections">collection&##39;s portals</a>.
	</p>
	--->
</cfif>
<cfif action is "collections">
	<p>
		Specimen data in MCZbase/Arctos is segregated into Virtual Private Databases. The default public user has
		access to all portals (all collections) simultaneously. It is also possible to form URLs specific to
		individual portals.
	</p>
	You may redirect users (those without overriding login preferences) to a specific "portal" by using the links from 
	<a href="/home.cfm">#Application.serverRootUrl#/home.cfm</a>
	<p>
		Generally, all collections have a portal of the format
		<ul class="labels">
			<li>
				#Application.serverRootUrl#/{institution_acronym}_{collection_cde}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/uam_mamm
					</li>
				</ul>
			</li>
		</ul>
	</p>
	<p>
		The default all-access portal is #Application.serverRootUrl#/all_all
	</p>
</cfif>

<cfif action is "mediasrch">
	Base URL: #Application.serverRootUrl#/MediaSearch.cfm?action=search
	<table border>
		<tr>
			<th>term</th>
			<th>values</th>
			<th>comment</th>
		</tr>
		<tr>
			<td>media_uri</td>
			<td>&nbsp;</td>
			<td>substring match on URI where Media is stored</td>
		</tr>
		<cfquery name="ct" datasource="cf_dbuser">
			select media_type data from ctmedia_type order by media_type
		</cfquery>
		<tr>
			<td>media_type</td>
			<td>#valuelist(ct.data,"<br>")#</td>
			<td>&nbsp;</td>
		</tr>
		<cfquery name="ct" datasource="cf_dbuser">
			select mime_type data from ctmime_type order by mime_type
		</cfquery>
		<tr>
			<td>mime_type</td>
			<td>#valuelist(ct.data,"<br>")#</td>
			<td>&nbsp;</td>
		</tr>
		<cfquery name="ct" datasource="cf_dbuser">
			select media_relationship data from ctmedia_relationship order by media_relationship
		</cfquery>
		<tr>
			<td>relationship</td>
			<td>#valuelist(ct.data,"<br>")#</td>
			<td>substring searches are supported</td>
		</tr>
		<tr>
			<td>related_to</td>
			<td>&nbsp;</td>
			<td>
				Display value of relationship. Examples include:
				<ul>
					<li><strong>MVZ Birds 182924 (Buteogallus anthracinus anthracinus)</strong> (cataloged_item)</li>
					<li><strong>Stan Moore</strong> (agent)</li>
					<li><strong>North America, United States, California, Alameda County: STRAWBERRY CANYON, BERKELEY</strong> (locality)</li>
					<li><strong>A molecular view of pinniped relationships with particular emphasis on the true seals.</strong> (project)</li>
				</ul>
			</td>
		</tr>
		<cfquery name="ct" datasource="cf_dbuser">
			select media_label data from ctmedia_label order by media_label
		</cfquery>
		<tr>
			<td>label</td>
			<td>#valuelist(ct.data,"<br>")#</td>
			<td>substring searches are supported</td>
		</tr>
		<tr>
			<td>label_value</td>
			<td>&nbsp;</td>
			<td>
				Display value of label. Examples include:
				<ul>
					<li><strong>10 Jul 2007</strong> (made date)</li>
					<li><strong>prepared specimen</strong> (subject)</li>
					<li><strong>5000</strong> (image number)</li>
				</ul>
			</td>
		</tr>		
	</table>
</cfif>
<cfif action is "taxsrch">
	<h1>NAME API:</h1>
	<p>name api: <a href="#Application.serverRootUrl#/name/Murex">#Application.serverRootUrl#/name/Scientific+Name</a>
	<p>RDF is planned, but not yet supported.</p>
	<h1>HTML Search API:</h1>
	<p>Taxon search Base URL: #Application.serverRootUrl#/Taxa.cfm  Accepts http GET or http POST</p>
	<p>Example: <a href="#Application.serverRootUrl#/Taxa.cfm?execute=true&genus=Murex">#Application.serverRootUrl#/Taxa.cfm?execute=true&genus=Murex</a></p>
	<p>Returns an HTML page with results in a grid widget</p>
	<h1>JSON API:</h1>
	<p>Taxon search Base URL: #Application.serverRootUrl#/taxonomy/component/search.cfc?method=getTaxa Accepts http GET.</p>
	<p>Example: <a href="#Application.serverRootUrl#/taxonomy/component/search.cfc?method=getTaxa&genus=Murex">#Application.serverRootUrl#/Taxa.cfm?execute=true&genus=Murex</a></p>
	<p>Returns JSON in the form [{"PHYLUM":"Mollusca","TAXON_NAME_ID":273735,"TAXON_STATUS":"","SCIENTIFIC_NAME":"Maclurites magnus","GENUS":"Maclurites","SPECIES":"magnus","TRIBE":"","INFRASPECIFIC_RANK":"","DIVISION":"","FAMILY":"Macluritidae","SUPERORDER":"","SUBSPECIES":"","display_name_author":"Maclurites magnus Le Sueur. 1818","KINGDOM":"Animalia","SUBORDER":"","SUBDIVISION":"","TAXON_REMARKS":"PaleoDB taxon number: 68614\r\n\r\nhttps://www.biodiversitylibrary.org/page/24680580","INFRASPECIFIC_AUTHOR":"","SPECIMEN_COUNT":4,"SUBCLASS":"","PHYLCLASS":"Gastropoda","SUPERCLASS":"","SCIENTIFICNAMEID":"","DISPLAY_NAME":"Maclurites magnus","SUBPHYLUM":"","VALID_CATALOG_TERM":"Yes ","PHYLORDER":"Euomphalina","SUBGENUS":"","COMMON_NAMES":"","NOMENCLATURAL_CODE":"ICZN","SOURCE_AUTHORITY":"Paleobiology Database","TAXONID":"","INFRAORDER":"","AUTHOR_TEXT":"Le Sueur. 1818","SUPERFAMILY":"","FULL_TAXON_NAME":"Animalia Mollusca Gastropoda Euomphalina Macluritidae Maclurites magnus","SUBFAMILY":""}]</p>
	<table border>
		<tr>
			<th>term</th>
			<th>api</th>
			<th>comment</th>
		</tr>
		<tr>
			<td>execute</td>
			<td>html</td>
			<td><strong>true</strong> executes the search and displays the search results, no value populates the search form, but does not run the search</td>
		</tr>
		<tr>
			<td>common_name</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match</td>
		</tr>
		<tr>
			<td>scientific_name</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match</td>
		</tr>
		<tr>
			<td>genus</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>species</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>subspecies</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>full_taxon_name</td>
			<td>both</td>
			<td></td>
		</tr>
		<tr>
			<td>phylum</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>phylclass</td>
			<td>both</td>
			<td>Class</td>
		</tr>
		<tr>
			<td>phylorder</td>
			<td>both</td>
			<td>Order</td>
		</tr>
		<tr>
			<td>suborder</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>family</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>subfamily</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>tribe</td>
			<td>both</td>
			<td>prefix with <strong>=</strong> for exact match, prefix with <strong>!</strong> for NOT search, <strong>NULL</strong> finds blanks.</td>
		</tr>
		<tr>
			<td>subgenus</td>
			<td>both</td>
			<td>Not including parenthesies</td>
		</tr>
		<tr>
			<td>author_text</td>
			<td>both</td>
			<td>Authorship string, may include year, includes parenthesies for changed combinations.</td>
		</tr>
		<tr>
			<td>we_have_some</td>
			<td>both</td>
			<td><strong>1</strong>  Show only taxa for which cataloged items exist.  <strong>0</strong> Show only not used in identifications.  Omit/no value for all.</td>
		</tr>
		<tr>
			<td>valid_catalog_term_fg</td>
			<td>both</td>
			<td><strong>1</strong>  Show only taxa currently accepted for data entry.  <strong>0</strong> Show only taxa not accepted for data entry.  Omit/no value for all.</td>
		</tr>
		<tr>
			<td>method</td>
			<td>JSON</td>
			<td><strong>getTaxa</strong> Required for search to run.</td>
		</tr>
	</table>
</cfif>
<!---  cfif action is "specsrch">
	<!--- Never actually documented.  Expected to be replaced in redesign --->
	<cfquery name="st" datasource="cf_dbuser">
		select * from cf_search_terms order by term
	</cfquery>
		Base URL: #Application.serverRootUrl#/SpecimenResults.cfm
	<table border>
		<tr>
			<th>term</th>
			<th>display</th>
			<th>values</th>
			<th>comment</th>
		</tr>
		<cfloop query="st">
			<cfif left(code_table,2) is "CT">
				<cftry>
				<!--- cfquery name="docs" datasource="cf_dbuser">
					select * from #code_table#
				</cfquery --->
				<cfloop list="#docs.columnlist#" index="colName">
					<cfif #colName# is not "COLLECTION_CDE" and #colName# is not "DESCRIPTION">
						<cfset theColumnName = #colName#>
					</cfif>
				</cfloop>
				<!--- cfquery name="theRest" dbtype="query">
					select #theColumnName# from docs
						group by #theColumnName#
						order by #theColumnName#
				</cfquery --->
				<cfset ct="">
				<cfloop query="theRest">
					<cfset ct=ct & evaluate(theColumnName) & "<br>">
				</cfloop>
				<cfcatch>
					<cfset ct="fail: #code_table#: #cfcatch.message# #cfcatch.detail# #cfcatch.sql#">
				</cfcatch>
				</cftry>
			<cfelse>
				<cfset ct=code_table>
			</cfif>
			<tr>				
				<td valign="top">#term#</td>
				<td valign="top">#display#</td>
				<td valign="top">#ct#</td>
				<td valign="top">#definition#</td>
			</tr>
		</cfloop>
	</table>
</cfif --->
<cfif action is "kml">
	Base URL: #Application.serverRootUrl#/bnhmMaps/kml.cfm?action=newReq
	<table border>
		<tr>
			<th>Variable</th>
			<th>Values</th>
			<th>Explanation</th>
		</tr>		
		<tr>
			<td>{search criteria}</td>
			<td>{various}</td>
			<td>{see SpecimenSearch}</td>
		</tr>		
		<tr>
			<td>userFileName</td>
			<td>Any string</td>
			<td>Non-default file name. Will be URL-encoded, so use alphanumeric characters for predictability.</td>
		</tr>		
		<tr>
			<td rowspan="3">next</td>
			<td>nothing</td>
			<td>Proceed to a form where you may set all other criteria</td>
		</tr>
		<tr>		
			<td>colorByCollection</td>
			<td>Map points are arranged by collection</td>
		</tr>
		<tr>		
			<td>colorBySpecies</td>
			<td>Map points are arranged by collection</td>
		</tr>
		
		<tr>
			<td rowspan="3">method</td>
			<td>download</td>
			<td>Download a full KML file</td>
		</tr>
		<tr>		
			<td>gmap</td>
			<td>Map in Google Maps</td>
		</tr>
		<tr>		
			<td>link</td>
			<td>Download a KML Linkfile</td>
		</tr>
		
		<tr>
			<td rowspan="2">includeTimeSpan</td>
			<td>0</td>
			<td>Do not include time information</td>
		</tr>
		<tr>		
			<td>1</td>
			<td>Include time information</td>
		</tr>
		
		<tr>
			<td rowspan="2">showUnaccepted</td>
			<td>0</td>
			<td>Include only accepted coordinate determinations</td>
		</tr>
		<tr>		
			<td>1</td>
			<td>Include unaccepted coordinate determinations</td>
		</tr>
		
		<tr>
			<td rowspan="2">mapByLocality</td>
			<td>0</td>
			<td>Show only those specimens matching search criteria</td>
		</tr>
		<tr>		
			<td>1</td>
			<td>Include all specimens from each locality</td>
		</tr>
		
		<tr>
			<td rowspan="2">showErrors</td>
			<td>0</td>
			<td>Map points only</td>
		</tr>
		<tr>		
			<td>1</td>
			<td>Include error radii as circles</td>
		</tr>
	</table>
</cfif>
 
		<section>
	</main>
</cfoutput>
                 
<cfinclude template="/shared/_footer.cfm">
