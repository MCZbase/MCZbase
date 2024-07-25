<cfexecute 
		name= "/usr/bin/Rscript"
		arguments = "/var/www/html/arctos/metrics/R/simple_chart.R"
		variable = "chartOutput"
		timeout = "10000"
		errorVariable = "chartError">
</cfexecute>