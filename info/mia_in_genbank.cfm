<cfset pageTitle = "Potential Missed GenBank Records">
<cfinclude template="/shared/_header.cfm">
<script src="/includes/sorttable.js"></script>

<main class=”container py-3” id=”content” >
	<section class=”row border rounded my-2”>
		<h1 class=”h2”>Potential Missed GenBank Records</h1>
		<div class="border p-1">
			The following are potential specimen records that are in GenBank but not in MCZbase.
			<br><strong>wildcard</strong> query types are limited to 600 records by GenBank - the numbers you see here may make no sense.
			<br>Data in the table below are far from perfect and require human verification
			(excepting <strong>specimen_voucher:collection</strong>).
			These queries represent guesses based on what GenBank has received from researchers.
		</div>
		<cfoutput>
			<cfquery name="gb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select owner, found_count, run_date, query_type, link_url
				from cf_genbank_crawl 
				order by owner
			</cfquery>
			
			<table border id="t" class="sortable">
				<tr>
					<th>Owner</th>
					<th>Count</th>
					<th>Run Date</th>
					<th>Query Type</th>
					<th>Link</th>
				</tr>
				<cfloop query="gb">
					<tr>
						<td>#owner#</td>
						<td>#found_count#</td>
						<td>#dateformat(run_date,"dd mmm yyyy")#</td>
						<td>#query_type#</td>
						<td><a href="#link_url#" target="_blank">open GenBank</a></td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
