<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset pageTitle = "Media Record">
<cfinclude template = "/shared/_header.cfm">
	
	
<main id="content" class="container">
	<section class="row">
		<div class="col-12">
		page title and viewer button
		</div>
		<div class="col-12 col-md-6">
		image and caption
		</div>
		<div class="col-12 col-md-6">
		metadata
		</div>
	</section>

	<section class="row">
		<div class="col-12">
			<h3>In catalog records</h3>
			<div class="">
				Grid search results (like showNamedCollection)
			</div>
		</div>
		<div class="col-12">
			<h3>In transaction records</h3>
			<div class="">
				Grid search results (like showNamedCollection)
			</div>
		</div>
	</section>
</main>
	
	
<cfinclude template = "/shared/_header.cfm">