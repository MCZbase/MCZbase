<cfset pageTitle = "Scheduled Tasks">
<cfinclude template="/shared/_header.cfm">
<main class="container-fluid" id="content">
	<section class="row">
		<div class="col-12">
			<h2 class="h2">Scheduled Tasks</h2>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
				<p>Scheduled tasks are used to run background jobs at specified intervals.</p>
        
				<cfdirectory action="list" directory="#Application.webDirectory#/ScheduledTasks" name="dir" sort="name ASC">
				<cfoutput>
					<ul>
					<cfloop query="dir">
						<li> 
							<a href="#name#">#name#</a> 
							<cfif isdefined("dir.dateLastModified")> (Last Modified: #dateFormat(dir.dateLastModified, "mm/dd/yyyy")#)</cfif> 
						</li>
					</cfloop>
					</ul>
				</cfoutput>

			</cfif>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
