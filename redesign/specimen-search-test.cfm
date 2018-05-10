<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="">
<meta name="author" content="">
<link rel="icon" href="images/favicon.ico">
<title>Specimens</title>
<script src="redesign/includes/js/bootstrap.min.js"></script>
<script src="includes/jquery/1.11.3/jquery-1.11.3.min.js"></script>
<script src="https://code.jquery.com/jquery-1.12.4.js"></script>
<link href="redesign/includes/css/bootstrap.css" rel="stylesheet">
<link href="redesign/includes/css/custom.css" rel="stylesheet">
<link href="//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css" rel="stylesheet">
<link href="redesign/includes/css/font-awesome.css" rel="stylesheet">
<link href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" rel="stylesheet">
<link href="redesign/includes/css/dataTables.jqueryui.min.css" rel="stylesheet">
<link href="redesign/includes/css/dataTables.searchPane.css" rel="stylesheet">
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
      <a  href="#">
      <img class="navbar-brandK" src="redesign/images/mcz_logo_white.png"/><span class="navbar-text">Museum of <br/>Comparative Zoology</span></a>
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
              <a class="dropdown-item" href="form-test.cfm">Deaccession test</a>
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
    <i class="fa .fa-lg fa-user"></i>
  </button>
  <div class="collapse navbar-collapse" id="navbarNavDropdown" style="margin-bottom:88px;">
   	<div class="col-lg-12"  style="height: auto;">
   	<div class="container-fluid">
    	<div class="row">
    	<div class="col-md-2" style="background-color:palegoldenrod">
				<div class="panel panel-login">
					<div class="panel-heading">
						<div class="row">
						<div class="col-md-12" >
							<a href="#" class="active" id="login-form-link">Login</a>
							or
							<a href="#" id="register-form-link">Register</a>
						</div>
					    </div>
					 </div>
				</div>
				<div class="panel-body">
						<div class="row">
							<div class="col-md-12">
								<form id="login-form" action="https://phpoll.com/login/process" method="post" role="form" style="display: block;">
									<div class="form-group">
										<input type="text" name="username" id="username" tabindex="1" class="form-control" placeholder="Username" value="">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Password">
									</div>
									<div class="text-center">
										<input type="checkbox" tabindex="3" class="" name="remember" id="remember">
										<label for="remember"> Remember Me</label>
									</div>
									<div class="form-group">
									<div class="text-center">
												<input type="submit" name="login-submit" id="login-submit" tabindex="4" class="form-control btn btn-primary my-2" value="Log In"  style="width: 70%;">
										</div>
									</div>
									<div class="form-group">
										<div class="row">
											<div class="col-lg-12">
												<div class="text-center">
													<a href="https://phpoll.com/recover" tabindex="5" class="forgot-password">Forgot Password?</a>
												</div>
											</div>
										</div>
									</div>
								</form>
								<form id="register-form" action="https://phpoll.com/register/process" method="post" role="form" style="display: none;">
									<div class="form-group">
										<input type="text" name="username" id="username" tabindex="1" class="form-control" placeholder="Username" value="">
									</div>
									<div class="form-group">
										<input type="email" name="email" id="email" tabindex="1" class="form-control" placeholder="Email Address" value="">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Password">
									</div>
									<div class="form-group">
										<input type="password" name="confirm-password" id="confirm-password" tabindex="2" class="form-control" placeholder="Confirm Password">
									</div>
									<div class="form-group">
									<div class="text-center">
												<input type="submit" name="register-submit" id="register-submit" tabindex="4" class="form-control btn btn-register my-2" value="Log In"  style="width: 70%;">
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>
			</div>
			<div class="col-md-3">
				<div class="panel panel-login">
					<div class="panel-heading">
						<div class="row">
						<div class="col-md-12" >
							<p><strong>Site Profile</strong></p>
						</div>
					    </div>
					 </div>
					</div>
					<div class="panel-body">
						<div class="row">
							<div class="col-md-12">
								<form id="login-form" action="https://phpoll.com/login/process" method="post" role="form" style="display: block;">
									<div class="form-group">
										<input type="text" name="username" id="username" tabindex="1" class="form-control" placeholder="First Name" value="">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Last Name">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Affiliation">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Email">
									</div>
								</form>
								<form id="register-form" action="https://phpoll.com/register/process" method="post" role="form" style="display: none;">
									<div class="form-group">
										<input type="text" name="username" id="username" tabindex="1" class="form-control" placeholder="Username" value="">
									</div>
									<div class="form-group">
										<input type="email" name="email" id="email" tabindex="1" class="form-control" placeholder="Email Address" value="">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Password">
									</div>
									<div class="form-group">
										<input type="password" name="confirm-password" id="confirm-password" tabindex="2" class="form-control" placeholder="Confirm Password">
									</div>
									<div class="form-group">
									<div class="text-center">
												<input type="submit" name="register-submit" id="register-submit" tabindex="4" class="form-control btn btn-register my-2" value="Log In"  style="width: 70%;">
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>
				</div>
			<div class="col-md-3">
				<div class="panel panel-login">
					<div class="panel-heading">
						<div class="row">
						<div class="col-md-12" >
							<p><strong>Site Settings</strong></p>
						</div>
					    </div>
					 </div>
					</div>
					<div class="panel-body">
						<div class="row">
							<div class="col-md-12">
								<form id="login-form" action="https://phpoll.com/login/process" method="post" role="form" style="display: block;">
									<div class="form-group">
									<span>Suggest Browse</span> &nbsp;<select name="block_suggest" id="block_suggest" onchange="blockSuggest(this.value)">
			<option value="0">Allow</option>
			<option value="1" selected="selected">Block</option>
		</select>

									</div>
										<div class="form-group">
									<span>Include Observations</span> &nbsp;<select name="block_suggest" id="block_suggest" onchange="blockSuggest(this.value)">
			<option value="0">Yes</option>
			<option value="1" selected="selected">No</option>
		</select>

									</div>
								<div class="form-group">
									<span>Specimen and Taxonomy Records per page</span> &nbsp;<select name="block_suggest" id="block_suggest" onchange="blockSuggest(this.value)">
			<option value="0">100</option>
			<option value="1" selected="selected">10</option>
		</select>
		</div>
		<div class="form-group">
			<span>Other Identifier</span> &nbsp;<select name="block_suggest" id="block_suggest" onchange="blockSuggest(this.value)">
			<option value="0">Collector Number</option>
			<option value="1" selected="selected">Previous Number</option>
		</select>
						<br/><br/>
							<div class="form-group">
									<div class="text-center">
												<input type="submit" name="save-submit" id="save-submit" tabindex="4" class="form-control btn btn-register my-2" value="Save"  style="width: 70%;">
										</div>
									</div>
								</form>
								<form id="register-form" action="https://phpoll.com/register/process" method="post" role="form" style="display: none;">
									<div class="form-group">
										<input type="text" name="username" id="username" tabindex="1" class="form-control" placeholder="Username" value="">
									</div>
									<div class="form-group">
										<input type="email" name="email" id="email" tabindex="1" class="form-control" placeholder="Email Address" value="">
									</div>
									<div class="form-group">
										<input type="password" name="password" id="password" tabindex="2" class="form-control" placeholder="Password">
									</div>
									<div class="form-group">
										<input type="password" name="confirm-password" id="confirm-password" tabindex="2" class="form-control" placeholder="Confirm Password">
									</div>
									<div class="form-group">
									<div class="text-center">
												<input type="submit" name="register-submit" id="register-submit" tabindex="4" class="form-control btn btn-register my-2" value="Log In"  style="width: 70%;">
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
</nav>
     <main role="main" style="clear:both;">
      <section class="jumbotron text-center">
        <div class="container">
          <h1 class="jumbotron-heading">Search Our Collections</h1>
          <p class="lead text-muted">The Museum of Comparative Zoology was founded in 1859 on the concept that collections are an integral and fundamental component of zoological research and teaching. This more than 150-year-old commitment remains a strong and proud tradition for the MCZ. The present-day MCZ contains over 21-million specimens in collections which comprise one of the world's richest and most varied resources for studying the diversity of life. </p>
          <p>
            <a href="#" class="btn btn-primary my-2">Browse by Collection</a>
            <a href="#" class="btn btn-secondary my-2">Advanced Search</a>
          </p>
        </div>
      </section>
      <div class="album py-5 bg-light">
        <div class="container">
          <div class="row">
          <div class="col-md-4">
              <div class="card mb-4 box-shadow">
               <img class="card-img-top" src="redesign/images/bootstrap-cryo.jpg" alt="cryo">
				  <div class="card-body"><h4>Cryogenics</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                    <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 7,702 specimens</small>
                </div>
              </div>
            </div>
              <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" class="img-fluid" src="redesign/images/bootstrap-ent.jpg" data-holder-rendered="true" alt="Bee in amber">
				  <div class="card-body"><h4>Entomology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                    <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted"> 332,471 specimens</small>
                </div>
              </div>
            </div>
       <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg" alt="Card image cap">
                <div class="card-body"><h4>Herpetology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted"> 346,941 specimens</small>
                </div>
              </div>
            </div>
                        <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-ich.jpg" alt="Card image cap">
                <div class="card-body"><h4>Ichthyology</h4>
                  <p class="card-text">Links to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                          <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted"> 173,794 specimens</small>
                </div>
              </div>
            </div>
                       <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-IP.jpg"  alt="Card image cap">
                <div class="card-body"><h4 style="font-size: 1.4em;">Invertebrate Paleontology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 193,027 specimens</small>
                </div>
              </div>
            </div>
          <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-IZ.jpg" alt="Card image cap">
                <div class="card-body"><h4>Invertebrate Zoology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 163,924 specimens</small>
                </div>
              </div>
            </div>

            <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg" alt="Card image cap">
                <div class="card-body"><h4>Malacology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted"> 332471 specimens</small>
                </div>
              </div>
            </div>

            <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg" alt="Card image cap">
				  <div class="card-body"><h4>Mammalogy</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted"> 332471 specimens</small>
                </div>
              </div>
            </div>

            <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg" alt="Card image cap">
                <div class="card-body"><h4>Ornithology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>

                  </div>
                   <small class="text-muted">332471 specimens</small>
                </div>
              </div>
            </div>
                       <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg"  alt="Card image cap">
                <div class="card-body"><h4>Vertebrate Paleontology</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 332471 specimens</small>
                </div>
              </div>
            </div>

                       <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg"  alt="Card image cap">
                <div class="card-body"><h4>Special Collections</h4>
                  <p class="card-text">Link to results of featured specimens.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 332471 specimens</small>
                </div>
              </div>
            </div>
                         <div class="col-md-4">
              <div class="card mb-4 box-shadow">
                <img class="card-img-top" src="redesign/images/bootstrap-herp.jpg"  alt="Card image cap">
                <div class="card-body"><h4>Observations</h4>
                  <p class="card-text">Link to results of Herpetology Obs.</p>
                  <div class="d-flex justify-content-between align-items-center">
                         <div class="btn-group">
                      <button type="button" class="btn btn-sm btn-outline-secondary">Website</button>
                      <button type="button" class="btn btn-sm btn-outline-secondary">Search Collection</button>
                    </div>
                  </div>
                   <small class="text-muted"> 332471 specimens</small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

    </main>
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
	<script src="/redesign/includes/js/bootstrap.js"></script>
	<script src="/redesign/includes/js/jquery.dataTables.min.js"></script>
	<script src="/redesign/includes/js/dataTables.jqueryui.min.js"></script>
			<script type="text/javascript" language="javascript" src="/redesign/includes/js/dataTables.searchPane.js"></script>
		<script type="text/javascript" charset="utf-8">
		if ( $.fn.dataTable.isDataTable( '#example' ) ) {
    table = $('#example').DataTable({
		searchPane: {
                        container: '.searchPanes'
					}})
}
else {
    table = $('#example').DataTable( {
        paging: true,
		searchPane: {
                        container: '.searchPanes'
					}
    } );
}

		$(document).ready(function(){

    $(".filter-button").click(function(){
        var value = $(this).attr('data-filter');

        if(value == "all")
        {
            //$('.filter').removeClass('hidden');
            $('.filter').show('1000');
        }
        else
        {
//            $('.filter[filter-item="'+value+'"]').removeClass('hidden');
//            $(".filter").not('.filter[filter-item="'+value+'"]').addClass('hidden');
            $(".filter").not('.'+value).hide('3000');
            $('.filter').filter('.'+value).show('3000');

        }
    });

    if ($(".filter-button").removeClass("active")) {
$(this).removeClass("active");
}
$(this).addClass("active");

});
	$(function() {

    $('#login-form-link').click(function(e) {
		$("#login-form").delay(100).fadeIn(100);
 		$("#register-form").fadeOut(100);
		$('#register-form-link').removeClass('active');
		$(this).addClass('active');
		e.preventDefault();
	});
	$('#register-form-link').click(function(e) {
		$("#register-form").delay(100).fadeIn(100);
 		$("#login-form").fadeOut(100);
		$('#login-form-link').removeClass('active');
		$(this).addClass('active');
		e.preventDefault();
	});

});


			</script>
</body>
</html>
