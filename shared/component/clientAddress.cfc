<!---
shared/component/clientAddress.cfc
Functions for finding the address of the client making a request, for the blocklist and for logs.

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
<!--- X-Forwarded-For is sent by the client, so it can name any address.  It is used only when the
	request came from a proxy we trust: this server itself (a reverse proxy on the host, as on
	test), loopback, or an address in Application.trustedProxies (e.g. the load balancer's subnet),
	and then only the entries added by trusted proxies, read from the right.  No method is remote. --->
<cfcomponent>

<!---
	isIpAddress test whether a value is a single IPv4 or IPv6 address.

	@param value the value to test.
	@return true for a dotted quad IPv4 address, or a value made only of hex digits, colons and dots
		that contains a colon (IPv6).
--->
<cffunction name="isIpAddress" access="public" returntype="boolean" output="false">
	<cfargument name="value" type="string" required="yes">
	<cfset var octet = "(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])">
	<cfif REFind("^#octet#\.#octet#\.#octet#\.#octet#$", arguments.value) GT 0>
		<cfreturn true>
	</cfif>
	<cfreturn len(arguments.value) LE 45 AND find(":", arguments.value) GT 0 AND REFind("^[0-9A-Fa-f:.]+$", arguments.value) GT 0>
</cffunction>

<!---
	ipv4ToNumber convert a dotted quad IPv4 address to a number, for comparing with a CIDR range.

	@param address an IPv4 address.
	@return the address as a number from 0 to 2^32-1.
--->
<cffunction name="ipv4ToNumber" access="private" returntype="numeric" output="false">
	<cfargument name="address" type="string" required="yes">
	<cfset var result = 0>
	<cfset var i = 0>
	<cfloop from="1" to="4" index="i">
		<cfset result = result * 256 + listGetAt(arguments.address, i, ".")>
	</cfloop>
	<cfreturn result>
</cffunction>

<!---
	addressInList test whether an address matches an entry in a list of addresses and IPv4 CIDR ranges.

	@param address the address to look for.
	@param addressList comma separated addresses (IPv4 or IPv6) and IPv4 ranges such as 10.0.0.0/16.
	@return true if the address equals an address in the list, or is an IPv4 address in a listed range.
--->
<cffunction name="addressInList" access="public" returntype="boolean" output="false">
	<cfargument name="address" type="string" required="yes">
	<cfargument name="addressList" type="string" required="yes">
	<cfset var entry = "">
	<cfset var network = "">
	<cfset var prefixLength = 0>
	<cfset var blockSize = 0>
	<cfloop list="#arguments.addressList#" index="entry">
		<cfset entry = trim(entry)>
		<cfif find("/", entry) GT 0>
			<cfset network = listFirst(entry, "/")>
			<cfset prefixLength = listLast(entry, "/")>
			<cfif isIpAddress(network) AND find(".", network) GT 0 AND find(":", network) EQ 0
					AND isIpAddress(arguments.address) AND find(":", arguments.address) EQ 0
					AND isValid("integer", prefixLength) AND prefixLength GE 0 AND prefixLength LE 32>
				<cfset blockSize = 2 ^ (32 - prefixLength)>
				<cfif int(ipv4ToNumber(arguments.address) / blockSize) EQ int(ipv4ToNumber(network) / blockSize)>
					<cfreturn true>
				</cfif>
			</cfif>
		<cfelseif len(entry) GT 0 AND compareNoCase(entry, arguments.address) EQ 0>
			<cfreturn true>
		</cfif>
	</cfloop>
	<cfreturn false>
</cffunction>

<!---
	localAddresses the addresses of this server's network interfaces.

	@return comma separated addresses, without IPv6 zone suffixes.
--->
<cffunction name="localAddresses" access="public" returntype="string" output="false">
	<cfset var result = "">
	<cfset var interfaces = "">
	<cfset var addresses = "">
	<cfset var hostAddress = "">
	<cfif isDefined("Application.localAddresses")>
		<cfreturn Application.localAddresses>
	</cfif>
	<cftry>
		<cfset interfaces = createObject("java", "java.net.NetworkInterface").getNetworkInterfaces()>
		<cfloop condition="interfaces.hasMoreElements()">
			<cfset addresses = interfaces.nextElement().getInetAddresses()>
			<cfloop condition="addresses.hasMoreElements()">
				<cfset hostAddress = listFirst(addresses.nextElement().getHostAddress(), "%")>
				<cfset result = listAppend(result, hostAddress)>
			</cfloop>
		</cfloop>
	<cfcatch>
		<cflog file="MCZbase" text="clientAddress.cfc: could not list this server's addresses: #cfcatch.message#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!---
	isTrustedProxy test whether an address is a proxy whose X-Forwarded-For entries can be believed.

	@param address the address to test.
	@return true for loopback, this server's own addresses, and Application.trustedProxies.
--->
<cffunction name="isTrustedProxy" access="public" returntype="boolean" output="false">
	<cfargument name="address" type="string" required="yes">
	<cfset var LOOPBACK_ADDRESSES = "127.0.0.1,::1,0:0:0:0:0:0:0:1">
	<cfset var configured = "">
	<cfif isDefined("Application.trustedProxies")>
		<cfset configured = Application.trustedProxies>
	</cfif>
	<cfreturn addressInList(arguments.address, listAppend(listAppend(LOOPBACK_ADDRESSES, localAddresses()), configured))>
</cffunction>

<!---
	clientAddress the address of the client making the current request.

	@return cgi.remote_addr, unless that is a trusted proxy, in which case the rightmost
		X-Forwarded-For entry that is not itself a trusted proxy.  If that entry is not a valid
		address, cgi.remote_addr.
--->
<cffunction name="clientAddress" access="public" returntype="string" output="false">
	<cfset var remoteAddress = trim(cgi.remote_addr)>
	<cfset var forwardedFor = trim(cgi.http_x_forwarded_for)>
	<cfset var entry = "">
	<cfset var i = 0>
	<cfif len(forwardedFor) EQ 0 OR NOT isTrustedProxy(remoteAddress)>
		<cfreturn remoteAddress>
	</cfif>
	<!--- entries to the left of the last one a trusted proxy added were sent by the client --->
	<cfloop from="#listLen(forwardedFor)#" to="1" step="-1" index="i">
		<cfset entry = trim(listGetAt(forwardedFor, i))>
		<cfif NOT isIpAddress(entry)>
			<cfreturn remoteAddress>
		</cfif>
		<cfif NOT isTrustedProxy(entry)>
			<cfreturn entry>
		</cfif>
	</cfloop>
	<cfreturn remoteAddress>
</cffunction>

<!---
	isBlockExempt test whether an address must never be added to the blocklist.

	@param address the address to test.
	@return true for trusted proxies and this server, whose blocking would block everyone, and for
		Application.blockExemptAddresses.
--->
<cffunction name="isBlockExempt" access="public" returntype="boolean" output="false">
	<cfargument name="address" type="string" required="yes">
	<cfset var exempt = "">
	<cfif isDefined("Application.blockExemptAddresses")>
		<cfset exempt = Application.blockExemptAddresses>
	</cfif>
	<cfreturn isTrustedProxy(arguments.address) OR addressInList(arguments.address, exempt)>
</cffunction>

</cfcomponent>
