<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset pageTitle = "Media Record">
<cfinclude template = "/shared/_header.cfm">
	
	
<main id="content" class="container mt-5">
	<section class="row">
		<div class="col-12">
			<h1>Media</h1>
			<button></button>
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
			<h3 class="h4">In catalog records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
		<div class="col-12">
			<h3 class="h4">In transaction records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
	</section>
</main>
	
	
<cfinclude template = "/shared/_footer.cfm">