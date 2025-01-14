<cfset pageTitle = "Dynamic ERD">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3" id="content">
		<section class="row">
			<div class="col-12">
			<script src="https://d3js.org/d3.v7.min.js"></script>
			<style>
				.bar {
					fill: steelblue;
				}

				.bar:hover {
					fill: orangered;
				}

				.axis-label {
					font-size: 12px;
					text-anchor: middle;
				}
			</style>

			<svg width="500" height="200"></svg>

			<script>
				// Sample data
				const data = [4, 8, 15, 16, 23, 42];

				// Set up dimensions
				const width = 500;
				const height = 200;
				const barPadding = 5;

				// Create an SVG element
				const svg = d3.select("svg");

				// Scale for the vertical axis
				const yScale = d3.scaleLinear()
					.domain([0, d3.max(data)])
					.range([0, height]);

				// Create bars
				svg.selectAll("rect")
					.data(data)
					.enter().append("rect")
					.attr("class", "bar")
					.attr("x", (d, i) => i * (width / data.length))
					.attr("y", d => height - yScale(d))
					.attr("width", width / data.length - barPadding)
					.attr("height", d => yScale(d));

				// Add x-axis labels
				svg.selectAll("text")
					.data(data)
					.enter().append("text")
					.attr("class", "axis-label")
					.attr("x", (d, i) => i * (width / data.length) + (width / data.length - barPadding) / 2)
					.attr("y", height - 5)
					.text(d => d);
			</script>
				
		</div>
	</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">

