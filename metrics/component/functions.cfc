<cfexecute(
	name="rscript",
	arguments="-R 'Chart' '/metrics/datafile/chart_data.csv'",
	timeout="10",
	terminateOnTimeout="true"
	);
></cfexecute>