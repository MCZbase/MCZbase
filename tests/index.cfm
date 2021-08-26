<!--- run unit tests for catalog number list parsing --->
<!--- unit test the original mczbase catalog number list to SQL where clause code --->
<cfinclude template="TestListcatnumToBasQual.cfc">
<cfscript>
     testsuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
     testsuite.addAll("tests.TestListcatnumToBasQual");
     results = testsuite.run();
     writeOutput(results.getResultsOutput('html'));
</cfscript>
<!--- unit test the redesigned mczbase catalog number list to JSON code --->
<cfinclude template="TestListcatnumToJSON.cfc">
<cfscript>
     testsuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
     testsuite.addAll("tests.TestListcatnumToJSON");
     results = testsuite.run();
     writeOutput(results.getResultsOutput('html'));
</cfscript>
