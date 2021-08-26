<cfcomponent name="tests.TestListcatnumToBasQual" displayname="tests.TestListcatnumToBasQual" extends="mxunit.framework.TestCase">
	<cfinclude template="../specimens/component/search.cfc">

	<cffunction name="testScriptNumberListToJSON" returntype="void" access="public" hint="Tests ScriptNumberListToJSON()">
		<!--- '{join":"and","field": "cat_num","comparator": "IN","value": "1"}'  --->
		<cfscript>
		 assertEquals('{join":"and","field": "fieldname","comparator": "IN","value": "1"}', ScriptNumberListToJSON("1","fieldname"));
		 assertEquals('{join":"and","field": "fieldname","comparator": "IN","value": "1234567890"}', ScriptNumberListToJSON("1234567890","fieldname"));
		 assertEquals('{join":"and","field": "fieldname","comparator": "IN","value": "1234567890"}', ScriptNumberListToJSON("1234567890a","fieldname"));
		 assertEquals('{join":"and","field": "fieldname","comparator": "IN","value": "1234567890"]}', ScriptNumberListToJSON("1234567890X","fieldname"));
		 assertEquals('{join":"and","field": "fieldname","comparator": ">=","value": "1"]},{join":"and","field": "fieldname","comparator": "<=","value": "4"]}', ScriptNumberListToJSON("1-4","fieldname"));
		 assertEquals('{join":"and","field": "fieldname","comparator": ">=","value": "1"]},{join":"and","field": "fieldname","comparator": "<=","value": "4"]}', ScriptNumberListToJSON("4-1","fieldname"));
		 assertEquals(" ( fieldname >= 1 AND fieldname <= 4 ) ", ScriptNumberListToJSON("4-1","fieldname"));
		 assertEquals("", ScriptNumberListToJSON("A","fieldname"));
		 assertEquals("", ScriptNumberListToJSON("","fieldname"));
		 assertEquals("", ScriptNumberListToJSON("-","fieldname"));
		// TODO: Implement comma separated lists 
		// assertEquals('{join":"and","field": "fieldname","comparator": ">=","value": "1"]},{join":"and","field": "fieldname","comparator": "<=","value": "4"]}', ScriptNumberListToJSON("4-1","fieldname"));
		</cfscript>
	</cffunction>
<!---
TODO: Determine JSON output

	<cffunction name="testScriptPrefixedNumberListToJSONList" returntype="void" access="public" hint="Tests ScriptPrefixedNumberListToJSONList()">
		<!--- 
   	ScriptPrefixedNumberListToJSONList(listOfNumbers, integerFieldname, prefixFieldname, embeddedSeparator) {
		--->	
		<cfscript>
		        // a single number
		assertEquals(" ( intfield IN ( 1000 ) ) ",ScriptPrefixedNumberListToJSONList("1000","intfield","prefield",true));
		assertEquals(" ( intfield IN ( 1 ) ) ",ScriptPrefixedNumberListToJSONList("1","intfield","prefield",true));
		        // a single number with a prefix
		assertEquals(" ( ( prefield = 'A-' AND ( intfield IN ( 1 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'S-' AND ( intfield IN ( 800 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("S-800","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'S-' AND ( intfield IN ( 800 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("S800","intfield","prefield",true));
		        // a range of numbers with a prefix 
		assertEquals(" ( ( prefield = 'A-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1-5","intfield","prefield",true));
		        // a range of numbers without a prefix 
		assertEquals(" ( ( intfield >= 1 AND intfield <= 5 ) ) ",ScriptPrefixedNumberListToJSONList("1-5","intfield","prefield",true));

		        // turn off separator in the prefix field
		assertEquals(" ( ( prefield = 'Z' AND ( intfield IN ( 1 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("Z-1","intfield","prefield",0));
		assertEquals(" ( ( prefield = 'S' AND ( intfield IN ( 800 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("S-800","intfield","prefield",0));
		assertEquals(" ( ( prefield = 'S' AND ( intfield IN ( 800 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("S800","intfield","prefield",0));
		assertEquals(" ( ( prefield = 'A' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1-5","intfield","prefield",0));

		        // a comma delimited list of two numbers
		assertEquals(replace(" ( intfield IN ( 1 ) OR intfield in ( 2 ) ) "," ",".","All"),
		                     replace(ScriptPrefixedNumberListToJSONList("1,2","intfield","prefield",true)," ",".","All")
		                     );
		        // a comma delimited list of three numbers
		assertEquals(" ( intfield IN ( 1 ) OR intfield in ( 2 ) OR intfield in ( 1000 ) ) ",ScriptPrefixedNumberListToJSONList("1,2,1000","intfield","prefield",true));
		        // a comma delimited list of two numbers with the same prefix
		assertEquals(" ( ( prefield = 'A-' AND ( intfield IN ( 1 ) ) ) OR ( prefield = 'A-' AND ( intfield IN ( 2 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1,A-2","intfield","prefield",true));
		        // a comma delimited list of two numbers with different prefixes 
		assertEquals(" ( ( prefield = 'A-' AND ( intfield IN ( 1 ) ) ) OR ( prefield = 'R-' AND ( intfield IN ( 2 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1,R-2","intfield","prefield",true));
		        // a bare dash separator adds no term
		assertEquals("",ScriptPrefixedNumberListToJSONList("-","intfield","prefield",true));
		        // a comma separated list of dashes adds no term
		assertEquals("",ScriptPrefixedNumberListToJSONList("-,-","intfield","prefield",true));
		assertEquals("",ScriptPrefixedNumberListToJSONList("-,--","intfield","prefield",true));
		assertEquals("",ScriptPrefixedNumberListToJSONList("-,-,-,-","intfield","prefield",true));
		        // just a prefix with o number 
		assertEquals(replace(" ( ( prefield = 'PRE-' ) ) "," ",".","All"),
			         replace(ScriptPrefixedNumberListToJSONList("PRE","intfield","prefield",true)," ",".","All")
			         );
		        // a comma delimited list of prefixes 
		assertEquals(replace(" ( ( prefield = 'PRE-' ) OR ( prefield = 'OTHER-' ) ) "," ",".","All"),
			         replace(ScriptPrefixedNumberListToJSONList("PRE,OTHER","intfield","prefield",true)," ",".","All")
			         );
		        // a prefix and a suffix without a number 
		        // TODO: this will fail if suffix support is added.
		assertEquals(replace(" ( ( prefield = 'PRE-' ) ) "," ",".","All"),
			         replace(ScriptPrefixedNumberListToJSONList("PRE-suff","intfield","prefield",true)," ",".","All")
			         );
		        // a coma delimited list of two numbers with different prefixes, with and extra comma
		assertEquals(replace(" ( ( prefield = 'B-' AND ( intfield IN ( 1 ) ) ) OR ( prefield = 'A-' AND ( intfield IN ( 2 ) ) ) ) "," ",".","All"),
		                     replace(ScriptPrefixedNumberListToJSONList("B-1,,A-2,","intfield","prefield",true)," ",".","All")
		                     );
		        // a comma delimited list with an extra dash as the last element
		assertEquals(" ( ( prefield = 'C-' AND ( intfield IN ( 1 ) ) ) OR ( prefield = 'A-' AND ( intfield IN ( 2 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("C-1,A-2,-","intfield","prefield",true));
		</cfscript>
	</cffunction>

TODO: Determine JSON output
	<cffunction name="testScriptPrefixedNumberListToJSONListLists" returntype="void" access="public" hint="Tests ScriptPrefixedNumberListToJSONList() for lists">
		<cfscript>
		assertEquals(" ( ( prefield = 'A-' AND ( ( intfield >= 1000 AND intfield <= 1500 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1000-1500","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'R-' AND ( ( intfield >= 1200 AND intfield <= 1210 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("R-1200-1210","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'Apre-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) OR ( prefield = 'Bpre-' ) ) ",ScriptPrefixedNumberListToJSONList("Apre-1-5,Bpre","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'Apre-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) OR intfield IN ( 2000 ) ) ",ScriptPrefixedNumberListToJSONList("Apre-1-5,2000","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'Apre-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) OR ( prefield = 'Bpre-' ) OR intfield IN ( 5000 ) ) ",ScriptPrefixedNumberListToJSONList("Apre-1-5,Bpre,5000","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'A-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) OR ( prefield = 'A-' AND ( intfield IN ( 5000 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A-1-5,A-5000","intfield","prefield",true));
		assertEquals(" ( ( prefield = 'A-' AND ( ( intfield >= 1 AND intfield <= 5 ) ) ) OR ( prefield = 'A-' AND ( intfield IN ( 5000 ) ) ) OR intfield IN ( 900 ) ) ",ScriptPrefixedNumberListToJSONList("A-1-5,A-5000,900","intfield","prefield",true));
		        // A139902,A139908-139920
		assertEquals(" ( ( prefield = 'A-' AND ( intfield in ( 139902 ) ) ) OR ( prefield = 'A-' AND ( ( intfield >= 139908 AND intfield <= 139920 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("A139902,A139908-139920","intfield","prefield",true));

		assertEquals(" ( ( prefield = 'R-' AND ( ( intfield >= 1200 AND intfield <= 1210 ) ) ) OR ( prefield = 'S-' ) OR ( prefield = 'BOM-' AND ( ( intfield >= 0 AND intfield <= 100 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("R-1200-1210,S,BOM-0-100","intfield","prefield",true));
		        // list without dashes separating prefixes from numbers
		assertEquals(" ( ( prefield = 'R-' AND ( ( intfield >= 1200 AND intfield <= 1210 ) ) ) OR ( prefield = 'S-' ) OR ( prefield = 'BOM-' AND ( ( intfield >= 0 AND intfield <= 100 ) ) ) ) ",ScriptPrefixedNumberListToJSONList("R1200-1210,S,BOM0-100","intfield","prefield",true));
		</cfscript>
	</cffunction>
--->

</cfcomponent>
