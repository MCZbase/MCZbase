<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="">
<meta name="author" content="">
<link rel="icon" href="images/favicon.ico">
<title>Search Results</title>
<script src="includes/bootstrap-4.0.0-alpha.6-dist/js/bootstrap.min.js"></script>
<script src="includes/jquery/1.11.3/jquery-1.11.3.min.js"></script>
<script src="https://code.jquery.com/jquery-1.12.4.js"></script>
<link href="includes/bootstrap-4.0.0-alpha.6-dist/css/bootstrap.css" rel="stylesheet">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/css/custom.css" rel="stylesheet">
<link href="//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css" rel="stylesheet">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/css/font-awesome.css" rel="stylesheet">
<link href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" rel="stylesheet">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/css/dataTables.jqueryui.min.css" rel="stylesheet">
<!--SCRIPT & MOBILE SHEETS-->
<link href="includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.mobile-1.4.5.css" rel="stylesheet" media="media screen and (max-width: 599px)">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.mobile.structure-1.4.5.css" rel="stylesheet" media="media screen and (max-width: 599px)">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.mobile.theme-1.4.5.css" rel="stylesheet" media="media screen and (max-width: 599px)">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.mobile.inline-svg-1.4.5.css" rel="stylesheet" media="media screen and (max-width: 599px)">
<link href="includes/bootstrap-4.0.0-alpha.6-dist/css/dataTables.searchPane.css" rel="stylesheet">

</head>
<body>
 <nav class="navbar navbar-toggleable-md fixed-top navbar-inverse bg-inverse">
      <button class="navbar-toggler navbar-toggler-right" type="button" data-toggle="collapse" data-target="#navbar" aria-controls="navbar" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
      </button>
      <div class="shield-container">
       <div class="navbar-harvard-toggle">
       <img src="images/shield.png" alt="harvard shield"/>
      </div>
	 </div>
      <div class="navbar-brand">
      <a  href="specimen-search-test.cfm">
      <img class="navbar-brandK" src="includes/bootstrap-4.0.0-alpha.6-dist/images/mcz_logo_white.png"/><span class="navbar-text">Museum of <br/>Comparative Zoology</span></a>
	 </div>
      <div class="collapse navbar-collapse" id="navbar">
        <ul class="navbar-nav mr-auto" style="text-align: center;">
          <li class="nav-item active">
            <a class="nav-link" href="#">Specimens<span class="sr-only">(current)</span></a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="#">Data Entry</a>
          </li>
            <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" id="dropdown01" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Manage Data</a>
            <div class="dropdown-menu" aria-labelledby="dropdown01">
              <a class="dropdown-item" href="http://www.google.com">Action</a>
              <a class="dropdown-item" href="#">Another action</a>
              <a class="dropdown-item" href="#">Something else here</a>
            </div>
          </li>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="http://example.com" id="dropdown01" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Transactions</a>
            <div class="dropdown-menu" aria-labelledby="dropdown01">
              <a class="dropdown-item" href="http://www.google.com">Action</a>
              <a class="dropdown-item" href="#">Another action</a>
              <a class="dropdown-item" href="#">Something else here</a>
            </div>
          </li>
           <li class="nav-item dropdown">
            <div class="dropdown-menu" aria-labelledby="dropdown01">
              <a class="dropdown-item" href="http://www.google.com">Action</a>
              <a class="dropdown-item" href="#">Another action</a>
              <a class="dropdown-item" href="#">Something else here</a>
            </div>
          </li>
           <li class="nav-item active">
            <a class="nav-link" href="#">Help</span></a>
          </li>
        </ul>
      </div>
 </nav>

<nav class="navbar navbar-expand-lg navbar-light bg-light" style="top: 88px;">
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNavDropdown" aria-controls="navbarNavDropdown" aria-expanded="false" aria-label="Toggle navigation">
	  <span class="navbar-toggler-icon"></span> <span style="font-size: 14px;">Filters</span>
  </button>

  <div class="collapse navbar-collapse" id="navbarNavDropdown">
    <ul class="navbar-nav">
        <li class="nav-item">
		<h3>Filters and Reports</h3>

       <ul class="filters" style="margin-left:0;padding-right: 0;">
                     <li style="padding: 2px 2px 6px 5px;border-top: 1px solid #ccc;border-radius:5px;border-left:1px solid #ccc;border-bottom:5px solid white;border-right: 1px solid #ccc;">

                     <a href="#" style="color:#1e1e1e;">

                     <i class="fa fa-filter" style="font-size:20px;left:0;" aria-hidden="true"></i> <span style="margin-left:7px;">  Filters</span></a></li>
                    <li style="padding: 2px 0px 3px 5px;"><a href="#"><i class="fa fa-file-text-o" style="font-size:20px;left:0;" aria-hidden="true"></i> <span style="margin-left:7px;">  Reports</span></a></li>
                    <li style="padding: 2px 0px 3px 5px;"><a href="#"><i class="fa fa-bar-chart-o" style="" aria-hidden="true"></i><span style="margin-left:7px;"> Analytics </span></a></li>
                    <li style="padding: 2px 0px 3px 5px;"><a href="#"><i class="fa fa-download" style="font-size:20px;" aria-hidden="true"></i><span style="margin-left:7px;"> Export </span></a></li>
                </ul>

      </li>
      <li class="nav-item">
         <div class="searchPanes" style="font-size: .95em;border:1px solid #ccc;border-radius:6px;z-index:1;"></div>
      </li>
    </ul>
  </div>

</nav>

    <div class="row">
        <div id="wrapper">
            <div id="page-content-wrapper" style="margin-left:0;margin-bottom: 100px;">
                <div class="container-fluid container-fluid-helper">
                    <div class="row">
                        <div class="col-lg-12">
                            <h1>Deaccession Search Results</h1>

    <table id="example" class="display" style="width:100%" data-role="listview">
        <thead>
            <tr>
                <th>Name</th>
                <th>Position</th>
                <th>Office</th>
                <th>Age</th>
                <th>Start date</th>
                <th>Salary</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Tiger Nixon</td>
                <td>System Architect</td>
                <td>Edinburgh</td>
                <td>61</td>
                <td>2011/04/25</td>
                <td>$320,800</td>
            </tr>
            <tr>
                <td>Garrett Winters</td>
                <td>Accountant</td>
                <td>Tokyo</td>
                <td>63</td>
                <td>2011/07/25</td>
                <td>$170,750</td>
            </tr>
            <tr>
                <td>Ashton Cox</td>
                <td>Junior Technical Author</td>
                <td>San Francisco</td>
                <td>66</td>
                <td>2009/01/12</td>
                <td>$86,000</td>
            </tr>
            <tr>
                <td>Cedric Kelly</td>
                <td>Senior Javascript Developer</td>
                <td>Edinburgh</td>
                <td>22</td>
                <td>2012/03/29</td>
                <td>$433,060</td>
            </tr>
            <tr>
                <td>Airi Satou</td>
                <td>Accountant</td>
                <td>Tokyo</td>
                <td>33</td>
                <td>2008/11/28</td>
                <td>$162,700</td>
            </tr>
            <tr>
                <td>Brielle Williamson</td>
                <td>Integration Specialist</td>
                <td>New York</td>
                <td>61</td>
                <td>2012/12/02</td>
                <td>$372,000</td>
            </tr>
            <tr>
                <td>Herrod Chandler</td>
                <td>Sales Assistant</td>
                <td>San Francisco</td>
                <td>59</td>
                <td>2012/08/06</td>
                <td>$137,500</td>
            </tr>
            <tr>
                <td>Rhona Davidson</td>
                <td>Integration Specialist</td>
                <td>Tokyo</td>
                <td>55</td>
                <td>2010/10/14</td>
                <td>$327,900</td>
            </tr>
            <tr>
                <td>Colleen Hurst</td>
                <td>Javascript Developer</td>
                <td>San Francisco</td>
                <td>39</td>
                <td>2009/09/15</td>
                <td>$205,500</td>
            </tr>
            <tr>
                <td>Sonya Frost</td>
                <td>Software Engineer</td>
                <td>Edinburgh</td>
                <td>23</td>
                <td>2008/12/13</td>
                <td>$103,600</td>
            </tr>
            <tr>
                <td>Jena Gaines</td>
                <td>Office Manager</td>
                <td>London</td>
                <td>30</td>
                <td>2008/12/19</td>
                <td>$90,560</td>
            </tr>
            <tr>
                <td>Quinn Flynn</td>
                <td>Support Lead</td>
                <td>Edinburgh</td>
                <td>22</td>
                <td>2013/03/03</td>
                <td>$342,000</td>
            </tr>
            <tr>
                <td>Charde Marshall</td>
                <td>Regional Director</td>
                <td>San Francisco</td>
                <td>36</td>
                <td>2008/10/16</td>
                <td>$470,600</td>
            </tr>
            <tr>
                <td>Haley Kennedy</td>
                <td>Senior Marketing Designer</td>
                <td>London</td>
                <td>43</td>
                <td>2012/12/18</td>
                <td>$313,500</td>
            </tr>
            <tr>
                <td>Tatyana Fitzpatrick</td>
                <td>Regional Director</td>
                <td>London</td>
                <td>19</td>
                <td>2010/03/17</td>
                <td>$385,750</td>
            </tr>
            <tr>
                <td>Michael Silva</td>
                <td>Marketing Designer</td>
                <td>London</td>
                <td>66</td>
                <td>2012/11/27</td>
                <td>$198,500</td>
            </tr>
            <tr>
                <td>Paul Byrd</td>
                <td>Chief Financial Officer (CFO)</td>
                <td>New York</td>
                <td>64</td>
                <td>2010/06/09</td>
                <td>$725,000</td>
            </tr>
            <tr>
                <td>Gloria Little</td>
                <td>Systems Administrator</td>
                <td>New York</td>
                <td>59</td>
                <td>2009/04/10</td>
                <td>$237,500</td>
            </tr>
            <tr>
                <td>Bradley Greer</td>
                <td>Software Engineer</td>
                <td>London</td>
                <td>41</td>
                <td>2012/10/13</td>
                <td>$132,000</td>
            </tr>
            <tr>
                <td>Dai Rios</td>
                <td>Personnel Lead</td>
                <td>Edinburgh</td>
                <td>35</td>
                <td>2012/09/26</td>
                <td>$217,500</td>
            </tr>
            <tr>
                <td>Jenette Caldwell</td>
                <td>Development Lead</td>
                <td>New York</td>
                <td>30</td>
                <td>2011/09/03</td>
                <td>$345,000</td>
            </tr>
            <tr>
                <td>Yuri Berry</td>
                <td>Chief Marketing Officer (CMO)</td>
                <td>New York</td>
                <td>40</td>
                <td>2009/06/25</td>
                <td>$675,000</td>
            </tr>
            <tr>
                <td>Caesar Vance</td>
                <td>Pre-Sales Support</td>
                <td>New York</td>
                <td>21</td>
                <td>2011/12/12</td>
                <td>$106,450</td>
            </tr>
            <tr>
                <td>Doris Wilder</td>
                <td>Sales Assistant</td>
                <td>Sidney</td>
                <td>23</td>
                <td>2010/09/20</td>
                <td>$85,600</td>
            </tr>
            <tr>
                <td>Angelica Ramos</td>
                <td>Chief Executive Officer (CEO)</td>
                <td>London</td>
                <td>47</td>
                <td>2009/10/09</td>
                <td>$1,200,000</td>
            </tr>
            <tr>
                <td>Gavin Joyce</td>
                <td>Developer</td>
                <td>Edinburgh</td>
                <td>42</td>
                <td>2010/12/22</td>
                <td>$92,575</td>
            </tr>
            <tr>
                <td>Jennifer Chang</td>
                <td>Regional Director</td>
                <td>Singapore</td>
                <td>28</td>
                <td>2010/11/14</td>
                <td>$357,650</td>
            </tr>
            <tr>
                <td>Brenden Wagner</td>
                <td>Software Engineer</td>
                <td>San Francisco</td>
                <td>28</td>
                <td>2011/06/07</td>
                <td>$206,850</td>
            </tr>
            <tr>
                <td>Fiona Green</td>
                <td>Chief Operating Officer (COO)</td>
                <td>San Francisco</td>
                <td>48</td>
                <td>2010/03/11</td>
                <td>$850,000</td>
            </tr>
            <tr>
                <td>Shou Itou</td>
                <td>Regional Marketing</td>
                <td>Tokyo</td>
                <td>20</td>
                <td>2011/08/14</td>
                <td>$163,000</td>
            </tr>
            <tr>
                <td>Michelle House</td>
                <td>Integration Specialist</td>
                <td>Sidney</td>
                <td>37</td>
                <td>2011/06/02</td>
                <td>$95,400</td>
            </tr>
            <tr>
                <td>Suki Burks</td>
                <td>Developer</td>
                <td>London</td>
                <td>53</td>
                <td>2009/10/22</td>
                <td>$114,500</td>
            </tr>
            <tr>
                <td>Prescott Bartlett</td>
                <td>Technical Author</td>
                <td>London</td>
                <td>27</td>
                <td>2011/05/07</td>
                <td>$145,000</td>
            </tr>
            <tr>
                <td>Gavin Cortez</td>
                <td>Team Leader</td>
                <td>San Francisco</td>
                <td>22</td>
                <td>2008/10/26</td>
                <td>$235,500</td>
            </tr>
            <tr>
                <td>Martena Mccray</td>
                <td>Post-Sales support</td>
                <td>Edinburgh</td>
                <td>46</td>
                <td>2011/03/09</td>
                <td>$324,050</td>
            </tr>
            <tr>
                <td>Unity Butler</td>
                <td>Marketing Designer</td>
                <td>San Francisco</td>
                <td>47</td>
                <td>2009/12/09</td>
                <td>$85,675</td>
            </tr>
            <tr>
                <td>Howard Hatfield</td>
                <td>Office Manager</td>
                <td>San Francisco</td>
                <td>51</td>
                <td>2008/12/16</td>
                <td>$164,500</td>
            </tr>
            <tr>
                <td>Hope Fuentes</td>
                <td>Secretary</td>
                <td>San Francisco</td>
                <td>41</td>
                <td>2010/02/12</td>
                <td>$109,850</td>
            </tr>
            <tr>
                <td>Vivian Harrell</td>
                <td>Financial Controller</td>
                <td>San Francisco</td>
                <td>62</td>
                <td>2009/02/14</td>
                <td>$452,500</td>
            </tr>
            <tr>
                <td>Timothy Mooney</td>
                <td>Office Manager</td>
                <td>London</td>
                <td>37</td>
                <td>2008/12/11</td>
                <td>$136,200</td>
            </tr>
            <tr>
                <td>Jackson Bradshaw</td>
                <td>Director</td>
                <td>New York</td>
                <td>65</td>
                <td>2008/09/26</td>
                <td>$645,750</td>
            </tr>
            <tr>
                <td>Olivia Liang</td>
                <td>Support Engineer</td>
                <td>Singapore</td>
                <td>64</td>
                <td>2011/02/03</td>
                <td>$234,500</td>
            </tr>
            <tr>
                <td>Bruno Nash</td>
                <td>Software Engineer</td>
                <td>London</td>
                <td>38</td>
                <td>2011/05/03</td>
                <td>$163,500</td>
            </tr>
            <tr>
                <td>Sakura Yamamoto</td>
                <td>Support Engineer</td>
                <td>Tokyo</td>
                <td>37</td>
                <td>2009/08/19</td>
                <td>$139,575</td>
            </tr>
            <tr>
                <td>Thor Walton</td>
                <td>Developer</td>
                <td>New York</td>
                <td>61</td>
                <td>2013/08/11</td>
                <td>$98,540</td>
            </tr>
            <tr>
                <td>Finn Camacho</td>
                <td>Support Engineer</td>
                <td>San Francisco</td>
                <td>47</td>
                <td>2009/07/07</td>
                <td>$87,500</td>
            </tr>
            <tr>
                <td>Serge Baldwin</td>
                <td>Data Coordinator</td>
                <td>Singapore</td>
                <td>64</td>
                <td>2012/04/09</td>
                <td>$138,575</td>
            </tr>
            <tr>
                <td>Zenaida Frank</td>
                <td>Software Engineer</td>
                <td>New York</td>
                <td>63</td>
                <td>2010/01/04</td>
                <td>$125,250</td>
            </tr>
            <tr>
                <td>Zorita Serrano</td>
                <td>Software Engineer</td>
                <td>San Francisco</td>
                <td>56</td>
                <td>2012/06/01</td>
                <td>$115,000</td>
            </tr>
            <tr>
                <td>Jennifer Acosta</td>
                <td>Junior Javascript Developer</td>
                <td>Edinburgh</td>
                <td>43</td>
                <td>2013/02/01</td>
                <td>$75,650</td>
            </tr>
            <tr>
                <td>Cara Stevens</td>
                <td>Sales Assistant</td>
                <td>New York</td>
                <td>46</td>
                <td>2011/12/06</td>
                <td>$145,600</td>
            </tr>
            <tr>
                <td>Hermione Butler</td>
                <td>Regional Director</td>
                <td>London</td>
                <td>47</td>
                <td>2011/03/21</td>
                <td>$356,250</td>
            </tr>
            <tr>
                <td>Lael Greer</td>
                <td>Systems Administrator</td>
                <td>London</td>
                <td>21</td>
                <td>2009/02/27</td>
                <td>$103,500</td>
            </tr>
            <tr>
                <td>Jonas Alexander</td>
                <td>Developer</td>
                <td>San Francisco</td>
                <td>30</td>
                <td>2010/07/14</td>
                <td>$86,500</td>
            </tr>
            <tr>
                <td>Shad Decker</td>
                <td>Regional Director</td>
                <td>Edinburgh</td>
                <td>51</td>
                <td>2008/11/13</td>
                <td>$183,000</td>
            </tr>
            <tr>
                <td>Michael Bruce</td>
                <td>Javascript Developer</td>
                <td>Singapore</td>
                <td>29</td>
                <td>2011/06/27</td>
                <td>$183,000</td>
            </tr>
            <tr>
                <td>Donna Snider</td>
                <td>Customer Support</td>
                <td>New York</td>
                <td>27</td>
                <td>2011/01/25</td>
                <td>$112,000</td>
            </tr>
        </tbody>
        <tfoot>
            <tr>
                <th>Name</th>
                <th>Position</th>
                <th>Office</th>
                <th>Age</th>
                <th>Start date</th>
                <th>Salary</th>
            </tr>
        </tfoot>
    </table>

                        </div>
                    </div>
                </div>
            </div>
        </div>
     </div>
</div>

            <footer class="footer" style="margin-left:0;bottom:0 !important">
                <div class="fixed-bottom bg-inverse">
                    <cfif cgi.HTTP_HOST contains "harvard.edu" >
                        <div class="helplinks" ><a HREF="mailto:bhaley@oeb.harvard.edu">System Administrator</a> <a href="/info/bugs.cfm">Feedback&#8202;/&#8202;Report Errors</a> <a href="/Collections/index.cfm">Data Providers</a> </div>
                           <div class="logos" style="padding-top: 0;">
                           <div align="center" style="padding:.5em 0 0 0;background-color:#BAC5C6"><img src="images/harvard_logo_sm.png" class="harvard_logo"/></div>
                            <div class="copyright">
                        <p class="copyright_c" style="margin-bottom:.25em;font-size: 14px;padding: 0 2em;color: #1e1e1e;">Database content: &copy; Copyright 2017
                            President and Fellows of Harvard College</p>
                        <a href="http://www.mcz.harvard.edu/privacy/index.html" style="display: inline;">Privacy Statement</a> <span>|</span> <a href="http://www.mcz.harvard.edu/privacy/user_agreement.html">User Agreement</a> </div>
                             <a href="http://www.gbif.org/"><img src="/images/gbiflogo.png" alt="GBIF" class="gbif_logo"></a> <a href="http://www.idigbio.org/"><img src="/images/idigbio.png" alt="herpnet"></a> <a href="http://eol.org"><img src="/images/eol.png" alt="eol" class="eol_logo"></a>
                             <a href="http://vertnet.org"><img src="/images/vertnet_logo_small.png" alt="Vertnet"></a>
                             <a href="https://arctosdb.org/"><img src="/images/arctos-logo.png" class="arctos_logo" ALT="[ Link to home page. ]"></a>
                            <p class="tagline">Delivering Data to the Natural Sciences Community &amp; Beyond</p>
                        </div>
                    </cfif>
                  </div>
            </footer>

<script src="/includes/bootstrap-4.0.0-alpha.6-dist/js/bootstrap.js"></script>
<script src="/includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.dataTables.min.js"></script>
<script src="/includes/bootstrap-4.0.0-alpha.6-dist/js/dataTables.jqueryui.min.js"></script>
<!--<script src="includes/bootstrap-4.0.0-alpha.6-dist/js/jquery.mobile-1.4.5.js"></script>-->
<script src="/includes/bootstrap-4.0.0-alpha.6-dist/js/dataTables.searchPane.js"></script>
<script>
    $("#menu-toggle").click(function(e) {
        e.preventDefault();
        $("#wrapper").toggleClass("toggled");
    });
	 $("#navbarToggle").click(function(e) {
        e.preventDefault();
        $("#navbarToggle").toggleClass("collapse");
    });




</script>
<script type="text/javascript" charset="utf-8">
		if ( $.fn.dataTable.isDataTable( '#example' ) ) {
    table = $('#example').DataTable({
		searchPane: {
                        container: '.searchPanes',
						threshold: .3
					}})
}
else {
    table = $('#example').DataTable( {
        paging: true,
		searchPane: {
                        container: '.searchPanes',
						threshold: .3
					}
    } );
}
</script>
</body>
</html>
