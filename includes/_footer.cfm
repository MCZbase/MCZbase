<!---
_footer.cfm

Copyright 2019 President and Fellows of Harvard College

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
<footer class="footer">
    <div class="fixed-bottom bg-inverse">
    <cfif cgi.HTTP_HOST contains "harvard.edu" >
    
		<div class="row helplinks border-top pt-3">
        	<div class="col-sm-12 col-md-4 col-lg-4" style="text-align: center;">
        		<a HREF="mailto:bhaley@oeb.harvard.edu">System Administrator</a>
			</div>
       		<div class="col-sm-12 col-md-4 col-lg-4" style="text-align: center;">
        		<a href="/info/bugs.cfm">Feedback&#8202;/&#8202;Report Errors</a>
			</div>
        	<div class="col-sm-12 col-md-4 col-lg-4" style="text-align: center;">
        		<a href="/Collections/index.cfm">Data Providers</a> 
        	</div>
		</div>

        <div class="row copyright_background">
            <div class="footer-col-4-md" align="center" style="width: 393px;"> <img alt="Harvard Museum of Comparative Zoology Logo" title="Harvard Museum of Comparative Zoology Logo" class="media-element file-default file-os-files-medium" src="/includes/images/harvard_museum.png">
				<p class="agreements" style="font-size: smaller;"><a href="/Affiliates.cfm" class="policy_link">Affiliates</a> <a>|</a> <a href="https://mcz.harvard.edu/privacy-policy" class="policy_link">Privacy</a> <a>|</a> <a href="https://mcz.harvard.edu/user-agreement" class="policy_link">User Agreement</a> 
				</p>
            </div>
        </div>
        </div>
        <div class="branding-container">
            <div class="copyright-bottom fs-012 text-center"> Copyright © 2019 The President and Fellows of Harvard College.&nbsp; <a href="http://accessibility.harvard.edu/" class="text-white">Accessibility</a> | <a href="http://www.harvard.edu/reporting-copyright-infringements" class="text-white">Report Copyright Infringement</a> </div>
        </div>
    </cfif>
    </div>

<script>

var	menuRight = document.getElementById( 'cbp-spmenu-s2' ),
	showRightPush = document.getElementById( 'showRightPush' ),
	menuLeft = document.getElementById( 'cbp-spmenu-s3' ),
	showLeftPush = document.getElementById( 'showLeftPush' ),
	body = document.body;

    showRightPush.onclick = function() {
	classie.toggle( this, 'active' );
	classie.toggle( body, 'cbp-spmenu-push-toleft' );
	classie.toggle( menuRight, 'cbp-spmenu-open' );
	
	disableOther( 'showRightPush' );
    };
		
	showLeftPush.onclick = function() {
		classie.toggle( this, 'active' );
		classie.toggle( body, 'cbp-spmenu-push-toright');
		classie.toggle( menuLeft, 'cbp-spmenu-open' );
		disableOther( 'showLeftPush' );
	};
	
	function disableOther( button ) {
	if( button !== 'showLeftPush' ) {
		classie.toggle( showLeftPush, 'disabled' );
	}
	if( button !== 'showRightPush' ) {
		classie.toggle( showRightPush, 'disabled' );
	}
}
/*!
 * classie - class helper functions
 * from bonzo https://github.com/ded/bonzo
 * 
 * classie.has( elem, 'my-class' ) -> true/false
 * classie.add( elem, 'my-new-class' )
 * classie.remove( elem, 'my-unwanted-class' )
 * classie.toggle( elem, 'my-class' )
 */
/*jshint browser: true, strict: true, undef: true */

( function( window ) {

'use strict';

// class helper functions from bonzo https://github.com/ded/bonzo

function classReg( className ) {
  return new RegExp("(^|\\s+)" + className + "(\\s+|$)");
}

// classList support for class management
// altho to be fair, the api sucks because it won't accept multiple classes at once
var hasClass, addClass, removeClass;

if ( 'classList' in document.documentElement ) {
  hasClass = function( elem, c ) {
    return elem.classList.contains( c );
  };
  addClass = function( elem, c ) {
    elem.classList.add( c );
  };
  removeClass = function( elem, c ) {
    elem.classList.remove( c );
  };
}
else {
  hasClass = function( elem, c ) {
    return classReg( c ).test( elem.className );
  };
  addClass = function( elem, c ) {
    if ( !hasClass( elem, c ) ) {
      elem.className = elem.className + ' ' + c;
    }
  };
  removeClass = function( elem, c ) {
    elem.className = elem.className.replace( classReg( c ), ' ' );
  };
}

function toggleClass( elem, c ) {
  var fn = hasClass( elem, c ) ? removeClass : addClass;
  fn( elem, c );
}

window.classie = {
  // full names
  hasClass: hasClass,
  addClass: addClass,
  removeClass: removeClass,
  toggleClass: toggleClass,
  // short names
  has: hasClass,
  add: addClass,
  remove: removeClass,
  toggle: toggleClass
};

})( window );
</script>
</footer>
</body></html>
