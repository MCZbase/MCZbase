<cfinclude template="/includes/_header.cfm">
<cfset title="Suspect Data">
<cfif action is "nothing">
	<a href="slacker.cfm?action=pubNoAuth">Publications without Authors</a>
	<br><a href="slacker.cfm?action=pubNoCit">Publications without Citations</a>
	<br><a href="slacker.cfm?action=projNoCit">Projects with Loans and without Publications</a>	
	<br><a href="slacker.cfm?action=loanNoSpec">Loans without Specimens</a>
</cfif>
<cfif action is "loanNoSpec">
	<!--- TODO: Should be supported in transactions search --->
	<cfquery name="data" datasource="uam_god">
		select 
			collection,loan_number,loan.transaction_id
		from
		loan,trans,collection
		where
		loan.transaction_id=trans.transaction_id and
		trans.collection_id=collection.collection_id and
		trans.transaction_id not in (select transaction_id from loan_item)
		order by collection,loan_number
	</cfquery>
	<cfoutput>
		<h2>Loans without Specimens</h2>
		<cfset i=1>
		<cfloop query="data">
			<br><a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#collection# #loan_number#</a>
		</cfloop>
	</cfoutput>
</cfif>
<cfif action is "projNoCit">
	<cfquery name="data" datasource="uam_god">
		select 
			project_id,
			project_name
		from 
			project 
		where 
			project_id in (
				select 
					project_id 
				from 
					project_trans,
					loan
				where
					project_trans.transaction_id=loan.transaction_id
				) and
			project_id not in (
				select project_id from project_publication
				)
		order by
			project_name
	</cfquery>
	<cfoutput>
		<h2>Projects with Loans and without Publications</h2>
		<cfset i=1>
		<cfloop query="data">
			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
				<p class="indent">
					#project_name#
					<br>
					<a href="/ProjectDetail.cfm?project_id=#project_id#">Project Details</a>
					<br>
					<a href="/Project.cfm?action=editProject&project_id=#project_id#">Edit Project</a>
				</p>
			</div>
			<cfset i=i+1>
		</cfloop>
	</cfoutput>
</cfif>

<cfif action is "pubNoAuth">
	<cfquery name="data" datasource="uam_god">
		select 
			publication_id,
			publication_type
		from 
			publication 
		where 
			publication_id not in (select publication_id from publication_author_name)
	</cfquery>
	<cfoutput>
		<h2>Publications with no Authors</h2>
		<cfset i=1>
		<cfloop query="data">
			<a href="/publications/Publication.cfm?publication_id=#publication_id#">#publication_type#: #publication_id#</a>
			<br>
			<cfset i=i+1>
		</cfloop>
	</cfoutput>
</cfif>
<cfif action is "pubNoCit">
	<cfquery name="data" datasource="uam_god">
		select 
			publication_id,
			formatted_publication 
		from 
			formatted_publication
		where
			publication_id not in (
				select publication_id from citation
			)
		order by
			formatted_publication
	</cfquery>
	<cfoutput>
		<h2>Publications with no Citations</h2>
		<cfset i=1>
		<cfloop query="data">
			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
				<p class="indent">
					#formatted_publication#
					<br>
					<a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details (This link may not work. These data are suspect. That's why they're here.)</a>
					<br>
					<a href="/publications/Publication.cfm?publication_id=#publication_id#">Edit Publication</a>
				</p>
			</div>
			<cfset i=i+1>
		</cfloop>
	</cfoutput>
</cfif>

<cfinclude template="/includes/_footer.cfm">
