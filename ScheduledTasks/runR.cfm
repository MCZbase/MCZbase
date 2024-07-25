<cfschedule
	action = "run"
	task = "run_rscript"
	group = "metrics"
	startDate = "2024-07-27"
	startTime = "12:00:30"
	file = "chart1.png"
	path = "/metrics/R/graphs/"
	overwrite = "yes"
	interval = "weekly"
	url = "/metrics/R/simple_chart.R"
>