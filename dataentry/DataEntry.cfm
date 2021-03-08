<cfset pageTitle = "Data Entry">
<!-- 
Affiliates.cfm

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

-->
<cfinclude template = "/shared/_header.cfm">
 <script type="text/javascript">
        $(document).ready(function () {           
            $('#events').jqxPanel({ width: 260, height: 330});
            $('#draggable').jqxDragDrop({ restricter: 'parent',  dropTarget: '.drop-target' });
            $('#draggable').bind('dragStart', function (event) {
                addEvent(event.type, event.args.position);
            });
            $('#draggable').bind('dragEnd', function (event) {
                addEvent(event.type, event.args.position);
            });
            $('#draggable').bind('dropTargetEnter', function (event) {
                addEvent(event.type, event.args.position);
            });
            $('#draggable').bind('dropTargetLeave', function (event) {
                addEvent(event.type, event.args.position);
            });
            function addEvent(type, position) {
                $('#events').jqxPanel('prepend',
                    '<div class="row">Event: ' + type + ', (' + position.left + ', ' + position.top + ')</div>'
                );
            }
            (function centerLabels() {
                var labels = $('.label');
                labels.each(function (index, el) {
                    el = $(el);
                    var top = (el.parent().height() - el.height()) / 2;
                    el.css('top', top + 'px');
                });
            } ());
        });
    </script>
    <style type="text/css">
    .row
    {
        padding: 1px;
    }
    .draggable
    {
        border: 1px solid #bbb;
        background-color: #C9ECFF;
        width: 100px;
        height: 100px;
        left: 30px;
        top: 50px;
        padding: 5px;
        z-index: 2;
    }
    #draggable-parent
    {
        background-color: #eeffee;
        width: 350px;
        height: 350px;     
        text-align: center;
        border: 1px solid #eee;
        float: left;
    }
    .main-container
    {
        width: 650px;
        z-index: 0;
    }
    .events
    {
        float: right;
        padding: 10px;
        font-family: Tahoma;
        font-size: 13px;
    }    
    .label
    {
        position: relative; 
        font-family: Verdana;
        font-size: 11px;
        color: #000;
    }
    .drop-target
    {
        background-color: #FBFFB5;
        width: 150px;
        height: 150px;
        border: 1px solid #ddd;
        margin-left: 190px;
        margin-top: 70px;        
        z-index: 1;
    }
    </style>

<cfoutput>

    <div class="main-container">
        <form id="draggable-parent">
            <div id="draggable" class="draggable">
                <div class="label">							<label for="other_id" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Other ID</label>
							<div class="col-sm-4 col-md-4">
								<select class="data-entry-select border" oninput="this.className = ''" mt-0 required>
									<option value="">Other ID Type</option>
									<option value="1">Field Number</option>
									<option value="2">Collector Number</option>
									<option value="3">Previous Number</option>
								</select>
							</div></div>
            </div>
            <div class="drop-target"><div class="label">I'm a drop target</div></div>
        </form>
        <div id="events" class="events">
        </div>
    </div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
