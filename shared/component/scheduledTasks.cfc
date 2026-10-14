<!---
shared/component/scheduledTasks.cfc
Functions for the scheduled tasks in /ScheduledTasks/.

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<!--- No method is remote. --->
<cfcomponent>

<!---
	isLiveEmailServer whether reminder emails may really be sent: only from production with the master
	branch checked out.  Elsewhere (test, dev, or production on another branch) the reminder jobs report
	what they would send instead, so running them can't email borrowers or staff by mistake.

	@return true on the production server with master checked out.
--->
<cffunction name="isLiveEmailServer" access="public" returntype="boolean" output="false">
	<cfset var branch = "">
	<cfif NOT isDefined("Application.serverrole") OR Application.serverrole NEQ "production">
		<cfreturn false>
	</cfif>
	<cftry>
		<cfset branch = trim(fileRead("#Application.webDirectory#/.git/HEAD"))>
	<cfcatch>
		<cfreturn false>
	</cfcatch>
	</cftry>
	<cfreturn branch EQ "ref: refs/heads/master">
</cffunction>

</cfcomponent>
