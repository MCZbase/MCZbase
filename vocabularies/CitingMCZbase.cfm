<cfoutput>
<cfset pageTitle = "Citing MCZbase">
<cfinclude template="/shared/_header.cfm">

<div class="container main my-3">
	<div class="row">
		<div class="col-12">
			<h2>Guidlines for Citing MCZ Specimens</h2>
				<div class="section">
					<div class="row">
						<div class="col-12">
						<h3>Mentioning an MCZ specimen in a publication </h3>
							<p>The preferred format for mentioning an individual MCZ specimen in the text of a publication (or in other resources such as GenBank) is with the full Darwin Core Triplet, MCZ:collection code:catalog number, (e.g., MCZ:VP:VPRA-1285), rather than with just the catalog number.</p> 
						</div>
					</div>
				</div>
				<div class="section">
					<div class="row">
						<div class="col-12">
						<h3>Citing MCZ Specimen Data </h3>
							<p>The best way to cite a set of MCZ specimens is to run a search on GBIF that finds the specimens being cited. After confirming that the search contains the exact set of specimens of focus, login and click "Download." GBIF will provide you with a DOI and citation for the search result on GBIF. When this DOI appears in a publication, the citation is tracked and reported to the MCZ. With its DOI, this citation will resemble:</p>
							<p class="mx-4">GBIF.org (31 October 2022) GBIF Occurrence Download https://doi.org/10.15468/dl.nq9gb8.</p>
							<p>Authors may also include (in a footnote or other metadata) a link to a search on MCZbase that returns the target specimens, but a "Link to This Search" should never be relied upon for a citation in a publication as it only links to the search form entries (not to the results), it provides no guarantees of persistence (unlike a DOI), and it provides no means for tracking the citation (unlike a DOI).</p>
						</div>
					</div>
				</div>
				<div class="section">
					<div class="row">
						<div class="col-12">
						<h3>Citing the MCZbase Dataset as a whole </h3>
							<p>Cite the MCZbase specimen data (the entire dataset) with the DOI assigned to the dataset by GBIF: doi:10.15468/p5rupv. One format for the citation is:</p> 
							<p class="mx-4">Harvard University, Museum of Comparative Zoology (2018): MCZbase, Museum of Comparative Zoology, Harvard University. Occurrence Dataset. http://digir.mcz.harvard.edu/ipt/resource?r=mczbase. https://doi.org/10.15468/p5rupv.</p>
						</div>
					</div>
				</div>
				<div class="section">
					<div class="row">
						<div class="col-12">
						<h3>Citing the MCZbase Collection Management System Code </h3>
							<p>The code of the MCZbase application itself can be cited at doi:10.5281/zenodo.891420 and the code for the underlying database (the DDL schema) at  (doi:10.5281/zenodo.4489193). There is also a HOLLIS (Harvard On-Line Library Information System) catalog record for MCZbase: http://id.lib.harvard.edu/alma/99153708509603941/catalog.</p>
							<p>Format for the citations of the MCZbase application and database schema:</p>
							<p>Kennedy, M., P.J. Morris, B. Haley, D. McDonald (2024) MCZbase/MCZbase MCZbase version as of v2023June05 commit 4c6a6131 [Computer Software] doi:10.5281/zenodo.891420.</p>
							<p>Haley, B., P.J. Morris, D. McDonald (2024) MCZbase/DDL MCZbase Schema version as of 2023-06-05 commit a8ce06c6 [Computer Software] doi:10.5281/zenodo.4489193</p>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
<cfinclude template="/shared/_footer.cfm">
</cfoutput>
