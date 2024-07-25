<cfschedule
	action = "run"
	task = "run_rscript"
	group = "metrics"
	startDate = "2024-07-26"
	startTime = "12:30:00 AM"
	file = "chart1.png"
	path = "/metrics/R/graphs/"
	overwrite = "yes"
	interval = "weekly"
	url = "https://mczbase-dev.rc.fas.harvard.edu/metrics/R/simple_chart.R"
	resolveURL = "yes"
>