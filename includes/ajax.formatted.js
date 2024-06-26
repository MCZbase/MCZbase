// JavaScript Document
function changeStyle() {
    for (var a = 0, b = getAllSheets(); b[a]; a++) {
        if (b[a].title) {
            b[a].disabled = true
        }
        for (var c = 0; c < arguments.length; c++) {
            if (b[a].title == arguments[c]) {
                b[a].disabled = false
            }
        }
    }
    if (!b.length) {
        alert("Your browser cannot change stylesheets")
    }
}

function getAllSheets() {
    if (!window.ScriptEngine && navigator.__ice_version) {
        return document.styleSheets
    }
    if (document.getElementsByTagName) {
        var a = document.getElementsByTagName("LINK");
        var b = document.getElementsByTagName("STYLE")
    } else if (document.styleSheets && document.all) {
        var a = document.all.tags("LINK"),
            b = document.all.tags("STYLE")
    } else {
        return []
    }
    for (var c = 0, d = []; a[c]; c++) {
        if (a[c].rel) {
            var e = a[c].rel
        } else if (a[c].getAttribute) {
            var e = a[c].getAttribute("rel")
        } else {
            var e = ""
        }
        if (typeof e == "string" && e.toLowerCase()
            .indexOf("style") + 1) {
            d[d.length] = a[c]
        }
    }
    for (var c = 0; b[c]; c++) {
        d[d.length] = b[c]
    }
    return d
}

function deleteEncumbrance(a, b) {
    var c = "/picks/DeleteEncumbrance.cfm";
    var a;
    var b;
    var d = c + "?encumbrance_id=" + a + "&collection_object_id=" + b;
    deleteEncumbrance = window.open(d, "", "width=400,height=338, toolbar,location,status,menubar,resizable,scrollbars,")
}

function findJournal(a, b, c, d) {
    var e = "/picks/findJournal.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?journalIdFld=" + a + "&journalNameFld=" + b + "&formName=" + c + "&journalName=" + d;
    journalpick = window.open(f, "", "width=400,height=338, toolbar,location,status,menubar,resizable,scrollbars,")
}

function LocalityPick(a, b, c, d) {
    var e = "/picks/LocalityPick.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?localityIdFld=" + a + "&speclocFld=" + b + "&formName=" + c + "&fireEvent=" + d;
    localitypick = window.open(f, "", "width=800,height=600,resizable,scrollbars,")
}

function GeogPick(a, b, c) {
    var d = "/picks/GeogPick.cfm";
    var a;
    var b;
    var c;
    var e = d + "?geogIdFld=" + a + "&highGeogFld=" + b + "&formName=" + c;
    geogpick = window.open(e, "", "width=600,height=600, toolbar,resizable,scrollbars,")
}

function addrPick(a, b, c) {
    var d = "/picks/AddrPick.cfm";
    var a;
    var b;
    var c;
    var e = d + "?addrIdFld=" + a + "&addrFld=" + b + "&formName=" + c;
    addrpick = window.open(e, "", "width=400,height=338, resizable,scrollbars")
}

function findAgentName(a, b, c) {
    var d = "/picks/findAgentName.cfm";
    var a;
    var b;
    var c;
    var e = d + "?agentIdFld=" + a + "&agentNameFld=" + b + "&agentName=" + c;
    agentpick = window.open(e, "", "width=400,height=338, resizable,scrollbars")
}

function CatItemPick(a, b, c, d) {
    var e = "/picks/CatalogedItemPick.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?collIdFld=" + a + "&catNumFld=" + b + "&formName=" + c + "&sciNameFld=" + d;
    CatItemPick = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function taxaPickOptional(a, b, c, d) {
    var e = "/picks/TaxaPick.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?keepValue=1&taxonIdFld=" + a + "&taxonNameFld=" + b + "&formName=" + c + "&scientific_name=" + d;
    taxapick = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function taxaPick(a, b, c, d) {
    var e = "/picks/TaxaPick.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?taxonIdFld=" + a + "&taxonNameFld=" + b + "&formName=" + c + "&scientific_name=" + d;
    taxapick = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function findMedia(a, b, c) {
    var d = "/picks/findMedia.cfm";
    var b;
    var a;
    var c;
    var e = d + "?mediaIdFld=" + b + "&mediaStringFld=" + a + "&media_uri=" + c;
    mediapick = window.open(e, "", "width=400,height=338, resizable,scrollbars")
}

function addLoanItem(a) {
    var a;
    loanItemWin = windowOpener("/user/loanItem.cfm?collection_object_id=" + a, "loanItemWin", "width=800,height=500, resizable,scrollbars,toolbar,menubar")
}

function getInfo(a, b) {
    var a;
    var b;
    infoWin = windowOpener("/info/SpecInfo.cfm?subject=" + a + "&thisId=" + b, "infoWin", "width=800,height=500, resizable,scrollbars")
}

function getLegal(a) {
    var a;
    helpWin = windowOpener("/info/legal.cfm?content=" + a, "legalWin", "width=400,height=338, resizable,scrollbars")
}

function getQuadHelp() {
    helpWin = windowOpener("/info/quad.cfm", "quadHelpWin", "width=800,height=600, resizable,scrollbars,status")
}

function getHistory(a) {
    var b;
    historyWin = windowOpener("/info/ContHistory.cfm?container_id=" + a, "historyWin", "width=800,height=338, resizable,scrollbars")
}

function confirmDelete(a, b) {
    var a;
    var b = b || "this record";
    confirmWin = windowOpener("/includes/abort.cfm?formName=" + a + "&msg=" + b, "confirmWin", "width=200,height=150,resizable")
}

function getHelp(a) {
    var a;
    helpWin = windowOpener("/info/help.cfm?content=" + a, "helpWin", "width=400,height=338, resizable,scrollbars")
}

function getGeog(a, b, c, d) {
    var e = "/picks/findHigherGeog.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?geogIdFld=" + a + "&geogStringFld=" + b + "&formName=" + c + "&geogString=" + d;
    geogpickwin = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function getAccn(StringFld, IdFld, formName) {
    var url = "/picks/findAccn.cfm";
    var pickwin = url + "?AccnNumFld=" + StringFld + "&AccnIdFld=" + IdFld + "&formName=" + formName;
    pickwin = window.open(pickwin, "", "width=600,height=400, resizable,scrollbars");
}

function getPublication(a, b, c, d) {
    var e = "/picks/findPublication.cfm";
    var f = e + "?pubStringFld=" + a + "&pubIdFld=" + b + "&publication_title=" + c + "&formName=" + d;
    f = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function pickCollEvent(a, b, c) {
    var d = "/picks/pickCollEvent.cfm";
    var a;
    var c;
    var b;
    var e = d + "?collIdFld=" + a + "&collection_object_id=" + c + "&formName=" + b;
    ColPickwin = window.open(e, "", "width=800,height=600, resizable,scrollbars")
}

function findCollEvent(a, b, c) {
    var d = "/picks/findCollEvent.cfm";
    var a;
    var c;
    var b;
    var e = d + "?collIdFld=" + a + "&dispField=" + c + "&formName=" + b;
    ColPickwin = window.open(e, "", "width=800,height=600, resizable,scrollbars")
}

function findCatalogedItem(a, b, c, d, e, f) {
    var g = "/picks/findCatalogedItem.cfm";
    var a;
    var h;
    var c;
    var d;
    var e;
    var i;
    var j = g + "?collIdFld=" + a + "&CatNumStrFld=" + b + "&formName=" + c + "&oidType=" + d + "&oidNum=" + e + "&collID=" + f;
    catItemWin = window.open(j, "", "width=400,height=338, resizable,scrollbars")
}

function getProject(a, b, c, d) {
    var e = "/picks/findProject.cfm";
    var a;
    var b;
    var c;
    var d;
    var f = e + "?projIdFld=" + a + "&projNameFld=" + b + "&formName=" + c + "&project_name=" + d;
    projpickwin = window.open(f, "", "width=400,height=338, resizable,scrollbars")
}

function getAgent(a, b, c, d, e) {
    var f = "/picks/findAgent.cfm";
    var a;
    var b;
    var c;
    var d;
    var e;
    var g = f + "?agentIdFld=" + a + "&agentNameFld=" + b + "&formName=" + c + "&agent_name=" + d + "&allowCreation=" + e;
    agentpickwin = window.open(g, "", "width=400,height=338, resizable,scrollbars")
}

function chgCondition(a) {
    var a;
    helpWin = windowOpener("/picks/condition.cfm?collection_object_id=" + a, "conditionWin", "width=800,height=338, resizable,scrollbars")
}

function chgPreserve(a) {
    var a;
    helpWin = windowOpener("/picks/preserve.cfm?collection_object_id=" + a, "conditionWin", "width=800,height=338, resizable,scrollbars")
}

function gotAgentId(a) {
    var a;
    var b = a.length;
    if (b == 0) {
        alert("Oops! A select box malfunctioned! Try changing the value and leaving with TAB. The background should change to green when you've successfullly run the check routine.");
        return false
    }
}

function noenter(a) {
    var b;
    if (window.event) b = window.event.keyCode;
    else b = a.which;
    if (b == 13) return false;
    else return true
}

function getDocs(a, b) {
    var a;
    var b;
    var c = "http://g-arctos.appspot.com/arctosdoc/";
    var d = ".html";
    var e = c + a + d;
    if (b != null) {
        e += "#" + b
    }
    siteHelpWin = windowOpener(e, "HelpWin", "width=700,height=400, resizable,scrollbars,location,toolbar")
}

function windowOpener(a, b, c) {
    popupWins = [];
    if (typeof popupWins[b] != "object") {
        popupWins[b] = window.open(a, b, c)
    } else {
        if (!popupWins[b].closed) {
            popupWins[b].location.href = a
        } else {
            popupWins[b] = window.open(a, b, c)
        }
    }
    popupWins[b].focus()
}

function getCtDoc(a, b) {
    var a;
    var b;
    var c = "/info/ctDocumentation.cfm?table=" + a + "&field=" + b;
    ctDocWin = windowOpener(c, "ctDocWin", "width=700,height=400, resizable,scrollbars")
}

function get_cookie(a) {
    var b = document.cookie.match("(^|;) ?" + a + "=([^;]*)(;|$)");
    if (b) return unescape(b[2]);
    else return null
}

function IsNumeric(a) {
    var b = "0123456789.";
    var c = true;
    var d;
    for (i = 0; i < a.length && c == true; i++) {
        d = a.charAt(i);
        if (b.indexOf(d) == -1) {
            c = false
        }
    }
    return c
}

function changeexclusive_collection_id(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changeexclusive_collection_id",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            var b = document.getElementById("exclusive_collection_id")
                .className = ""
        } else {
            alert("An error occured: " + a)
        }
    })
}

function readCookie(a) {
    var b = a + "=";
    var c = document.cookie.split(";");
    for (var d = 0; d < c.length; d++) {
        var e = c[d];
        while (e.charAt(0) == " ") e = e.substring(1, e.length);
        if (e.indexOf(b) == 0) return e.substring(b.length, e.length)
    }
    return null
}

function createCookie(a, b, c) {
    if (c) {
        var d = new Date;
        d.setTime(d.getTime() + c * 24 * 60 * 60 * 1e3);
        var e = "; expires=" + d.toGMTString()
    } else var e = "";
    document.cookie = a + "=" + b + e + "; path=/"
}

function nada() {
    return false
}

function getFormValues() {
    var a = document.getElementById("SpecData");
    var b = a.length;
    var c = new Array;
    for (var d = 0; d < b; d++) {
        var e = a.elements[d];
        var f = e.name;
        var g = e.value;
        if (f.length > 0 && g.length > 0) {
            var h = f + "::" + g;
            if (c.indexOf(h) == -1) {
                c.push(h)
            }
        }
    }
    var i = c.join("|");
    document.cookie = "schParams=" + i
}

function closeAndRefresh() {
    document.location = location.href;
    var a = document.getElementById("customDiv");
    document.body.removeChild(a)
}

function showHide(a, b) {
    var c = "e_" + a;
    var d = "c_" + a;
    if (document.getElementById(c) && document.getElementById(d)) {
        var e = document.getElementById(c);
        var f = document.getElementById(d);
        if (c == "e_spatial_query") {
            var g = "Select on Google Map";
            var h = "Hide Google Map"
        } else {
            var h = "Show Fewer Options";
            var g = "Show More Options"
        }
        if (b == 1) {
            var i = "/includes/SpecSearch/" + a + ".cfm";
            f.innerHTML = '<img src="/images/indicator.gif">';
            jQuery.get(i, function (c) {
                jQuery(e)
                    .html(c);
                f.innerHTML = h;
                f.setAttribute("onclick", "showHide('" + a + "',0)");
                saveSpecSrchPref(a, b)
            })
        } else {
            e.innerHTML = "";
            f.setAttribute("onclick", "showHide('" + a + "',1)");
            f.innerHTML = g;
            saveSpecSrchPref(a, b)
        }
    }
}

function saveSpecSrchPref(a, b) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "saveSpecSrchPref",
        id: a,
        onOff: b,
        returnformat: "json",
        queryformat: "column"
    }, saveComplete)
}

function saveComplete(a) {
    var b = a.split(",");
    var c = b[0];
    var d = b[1];
    var e = b[2];
    if (c == "cookie") {
        var f = new Array;
        var g = readCookie("specsrchprefs");
        var h = -1;
        if (g !== null) {
            f = g.split(",");
            for (i = 0; i < f.length; i++) {
                if (f[i] == d) {
                    h = i
                }
            }
        }
        if (e == 1) {
            if (h == -1) {
                f.push(d)
            }
        } else {
            if (h != -1) f.splice(h, 1)
        }
        var j = f.join();
        createCookie("specsrchprefs", j, 0)
    }
}

function changeshowObservations(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changeshowObservations",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a != "success") {
            alert("An error occured: " + a)
        }
    })
}

function removeHelpDiv() {
    if (document.getElementById("bgDiv")) {
        jQuery("#bgDiv")
            .remove()
    }
    if (document.getElementById("helpDiv")) {
        jQuery("#helpDiv")
            .remove()
    }
}

function changecustomOtherIdentifier(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changecustomOtherIdentifier",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            document.getElementById("customOtherIdentifier")
                .className = ""
        } else {
            alert("An error occured: " + a)
        }
    })
}

function changefancyCOID(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changefancyCOID",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            var b = document.getElementById("fancyCOID")
                .className = ""
        } else {
            alert("An error occured: " + a)
        }
    })
}

function changedisplayRows(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changedisplayRows",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            document.getElementById("displayRows")
                .className = ""
        } else {
            alert("An error occured: " + a)
        }
    })
}

function changeresultSort(a) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "changeresultSort",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            var b = document.getElementById("result_sort")
                .className = ""
        } else {
            alert("An error occured: " + a)
        }
    })
}

function makePart() {
    var a = document.getElementById("collection_object_id")
        .value;
    var b = document.getElementById("npart_name")
        .value;
    var c = document.getElementById("lot_count")
        .value;
    var d = document.getElementById("coll_obj_disposition")
        .value;
    var e = document.getElementById("condition")
        .value;
    var f = document.getElementById("coll_object_remarks")
        .value;
    var g = document.getElementById("barcode")
        .value;
    var h = document.getElementById("new_container_type")
        .value;
    jQuery.getJSON("/component/functions.cfc", {
        method: "makePart",
        collection_object_id: a,
        part_name: b,
        lot_count: c,
        coll_obj_disposition: d,
        condition: e,
        coll_object_remarks: f,
        barcode: g,
        new_container_type: h,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        var b = a.DATA;
        var c = b.STATUS[0];
        if (c == "error") {
            var d = b.MSG[0];
            alert(d)
        } else {
            var d = "Created part: ";
            d += b.PART_NAME[0] + " ";
            if (b.BARCODE[0] !== null) {
                d += "barcode " + b.BARCODE[0];
                if (b.NEW_CONTAINER_TYPE[0] !== null) {
                    d += "( " + b.NEW_CONTAINER_TYPE[0] + ")"
                }
            }
            var e = document.getElementById("ppDiv");
            document.body.removeChild(e);
            var f = document.getElementById("bgDiv");
            document.body.removeChild(f);
            getParts()
        }
    })
}

function divpopClose() {
    var a = document.getElementById("ppDiv");
    document.body.removeChild(a);
    var b = document.getElementById("bgDiv");
    document.body.removeChild(b)
}

function divpopDone(a) {
    if (a.readyState == 4) {
        if (a.status == 200) {
            document.getElementById("ppDiv")
                .innerHTML = a.responseText
        } else {
            document.getElementById("ppDiv")
                .innerHTML = "ahah error:\n" + a.statusText
        }
        var b = document.getElementById("ppDiv");
        var c = document.createElement("span");
        c.className = "popDivControl";
        c.setAttribute("onclick", "divpopClose();");
        c.innerHTML = "X";
        b.appendChild(c)
    }
}

function divpop(a) {
    var b;
    var c = document.createElement("div");
    c.id = "bgDiv";
    c.className = "bgDiv";
    document.body.appendChild(c);
    var d = document.createElement("div");
    d.id = "ppDiv";
    d.className = "pickBox";
    d.innerHTML = "Loading....";
    d.src = "";
    document.body.appendChild(d);
    if (window.XMLHttpRequest) {
        b = new XMLHttpRequest
    } else if (window.ActiveXObject) {
        b = new ActiveXObject("Microsoft.XMLHTTP")
    }
    if (b != undefined) {
        b.onreadystatechange = function () {
            divpopDone(b)
        };
        b.open("GET", a, true);
        b.send("")
    }
}

function success_getParts(a) {
    var b = a.DATA;
    var c = document.getElementById("ajaxStatus");
    document.body.removeChild(c);
    var d = document.getElementById("thisSpecimen");
    var e = document.getElementById("collection_id");
    var f = document.getElementById("collection_object_id");
    var g = document.getElementById("part_name");
    var h = document.getElementById("part_name_2");
    var j = g.value;
    var k = h.value;
    g.options.length = 0;
    h.options.length = 0;
    var l = e.selectedIndex;
    var m = e.options[l].text;
    var n = document.getElementById("other_id_type")
        .value;
    var o = document.getElementById("oidnum")
        .value;
    var p = m + " " + n + " " + o;
    if (b.PART_NAME[0].indexOf("Error:") > -1) {
        d.className = "error";
        p += " = " + b.PART_NAME[0];
        f.value = "";
        document.getElementById("pTable")
            .className = "red"
    } else {
        document.getElementById("pTable")
            .className = "";
        d.className = "";
        f.value = b.COLLECTION_OBJECT_ID[0];
        var q = document.createElement("option");
        q.setAttribute("value", "");
        q.appendChild(document.createTextNode(""));
        h.appendChild(q);
        for (i = 0; i < a.ROWCOUNT; i++) {
            var q = document.createElement("option");
            var r = document.createElement("option");
            q.setAttribute("value", b.PARTID[i]);
            r.setAttribute("value", b.PARTID[i]);
            var s = b.PART_NAME[i];
            if (b.BARCODE[i] !== null) {
                s += " [" + b.BARCODE[i] + "]"
            }
            q.appendChild(document.createTextNode(s));
            r.appendChild(document.createTextNode(s));
            g.appendChild(q);
            h.appendChild(r)
        }
        g.value = j;
        h.value = k;
        p += " = " + b.COLLECTION[0] + " " + b.CAT_NUM[0] + " (" + b.CUSTOMIDTYPE[0] + " " + b.CUSTOMID[0] + ")"
    }
    d.innerHTML = p
}

function getParts() {
    var a = document.getElementById("collection_id")
        .value;
    var b = document.getElementById("other_id_type")
        .value;
    var c = document.getElementById("oidnum")
        .value;
    if (a.length > 0 && b.length > 0 && c.length > 0) {
        var d = document.createElement("DIV");
        d.id = "ajaxStatus";
        d.className = "ajaxStatus";
        d.innerHTML = "Fetching parts...";
        document.body.appendChild(d);
        var e = document.getElementById("noBarcode")
            .checked;
        var f = document.getElementById("noSubsample")
            .checked;
        jQuery.getJSON("/component/functions.cfc", {
            method: "getParts",
            collection_id: a,
            other_id_type: b,
            oidnum: c,
            noBarcode: e,
            noSubsample: f,
            returnformat: "json",
            queryformat: "column"
        }, success_getParts)
    }
}

function newPart(a) {
    var b = document.getElementById("collection_id")
        .value;
    var c = document.getElementById("part_name")
        .value;
    var d = "/form/newPart.cfm";
    d += "?collection_id=" + b;
    d += "&collection_object_id=" + a;
    d += "&part=" + c;
    divpop(d)
}

function checkSubmit() {
    var a = document.getElementById("submitOnChange")
        .checked;
    if (a == true) {
        addPartToContainer()
    }
}

function success_getSpecimen(a) {
    if (toString(a.DATA.COLLECTION_OBJECT_ID[0])
        .indexOf("Error:") > -1) {
        alert(a.DATA.COLLECTION_OBJECT_ID[0])
    } else {
        newPart(a.DATA.COLLECTION_OBJECT_ID[0])
    }
}

function clonePart() {
    var a = document.getElementById("collection_id")
        .value;
    var b = document.getElementById("other_id_type")
        .value;
    var c = document.getElementById("oidnum")
        .value;
    if (a.length > 0 && b.length > 0 && c.length > 0) {
        jQuery.getJSON("/component/functions.cfc", {
            method: "getSpecimen",
            collection_id: a,
            other_id_type: b,
            oidnum: c,
            returnformat: "json",
            queryformat: "column"
        }, success_getSpecimen)
    } else {
        alert("Error: cannot resolve ID to specimen.")
    }
}

function success_addPartToContainer(a) {
    statAry = a.split("|");
    var b = statAry[0];
    var c = statAry[1];
    document.getElementById("pTable")
        .className = "";
    var d = document.getElementById("msgs");
    var e = document.getElementById("msgs_hist");
    var f = d.innerHTML + "<hr>" + e.innerHTML;
    e.innerHTML = f;
    d.innerHTML = c;
    if (b == 0) {
        d.className = "error"
    } else {
        d.className = "successDiv";
        document.getElementById("oidnum")
            .focus();
        document.getElementById("oidnum")
            .select();
        getParts()
    }
}

function addPartToContainer() {
    document.getElementById("pTable")
        .className = "red";
    var a = document.getElementById("collection_object_id")
        .value;
    var b = document.getElementById("part_name")
        .value;
    var c = document.getElementById("part_name_2")
        .value;
    var d = document.getElementById("parent_barcode")
        .value;
    var e = document.getElementById("new_container_type")
        .value;
    if (a.length == 0 || b.length == 0 || d.length == 0) {
        alert("Something is null");
        return false
    }
    jQuery.getJSON("/component/functions.cfc", {
        method: "addPartToContainer",
        collection_object_id: a,
        part_id: b,
        part_id2: c,
        parent_barcode: d,
        new_container_type: e,
        returnformat: "json",
        queryformat: "column"
    }, success_addPartToContainer)
}

function success_findAccession(a) {
    if (a > 0) {
        document.getElementById("g_num")
            .className = "doShow";
        document.getElementById("b_num")
            .className = "noShow"
    } else {
        document.getElementById("g_num")
            .className = "noShow";
        document.getElementById("b_num")
            .className = "doShow"
    }
}

function findAccession() {
    var a = document.getElementById("collection_id")
        .value;
    var b = document.getElementById("accn_number")
        .value;
    jQuery.getJSON("/component/functions.cfc", {
        method: "findAccession",
        collection_id: a,
        accn_number: b,
        returnformat: "json",
        queryformat: "column"
    }, success_findAccession)
}

function hidePageLoad() {
    $("#loading")
        .hide()
}

function goPickParts(a, b) {
    var c = "/picks/internalAddLoanItemTwo.cfm?collection_object_id=" + a + "&transaction_id=" + b;
    mywin = windowOpener(c, "myWin", "height=300,width=800,resizable,location,menubar ,scrollbars ,status ,titlebar,toolbar")
}

function uncheckAllById(a) {
    crcloo(a, "out");
    var b = a.split(",");
    for (i = 0; i < b.length; ++i) {
        if (document.getElementById(b[i])) {
            document.getElementById(b[i])
                .checked = false
        }
    }
}

function checkAllById(a) {
    var b = a.split(",");
    for (i = 0; i < b.length; ++i) {
        if (document.getElementById(b[i])) {
            document.getElementById(b[i])
                .checked = true;
            crcloo(b[i], "in")
        }
    }
}

function crcloo(a, b) {
    jQuery.getJSON("/component/functions.cfc", {
        method: "clientResultColumnList",
        ColumnList: a,
        in_or_out: b,
        returnformat: "json",
        queryformat: "column"
    }, success_crcloo)
}

function success_crcloo() {
    return false
}

function saveSearch(a) {
    var b = prompt("Name this search", "my search");
    if (b !== null) {
        var c = encodeURIComponent(b);
        var d = encodeURI(a);
        jQuery.getJSON("/component/functions.cfc", {
            method: "saveSearch",
            returnURL: d,
            srchName: c,
            returnformat: "json",
            queryformat: "column"
        }, function (a) {
            if (a != "success") {
                alert(a)
            }
        })
    }
}

function closeAnnotation() {
    var a = document.getElementById("bgDiv");
    document.body.removeChild(a);
    var a = document.getElementById("annotateDiv");
    document.body.removeChild(a)
}

function npPage(a, b, c) {
    var d = "/includes/taxonomy/specTaxMedia.cfm";
    var e = "?Result_Per_Page=" + b + "&offset=" + a + "&taxon_name_id=" + c;
    d += e;
    $("#imgBrowserCtlDiv")
        .append('<img src="/images/indicator.gif">');
    jQuery.get(d, function (a) {
        jQuery("#specTaxMedia")
            .html(a)
    })
}

function openAnnotation(a) {
    var b = document.createElement("div");
    b.id = "bgDiv";
    b.className = "bgDiv";
    b.setAttribute("onclick", "closeAnnotation()");
    document.body.appendChild(b);
    var c = document.createElement("div");
    c.id = "annotateDiv";
    c.className = "annotateBox";
    c.innerHTML = "";
    c.src = "";
    document.body.appendChild(c);
    var d = "/info/annotate.cfm?q=" + a;
    jQuery("#annotateDiv")
        .load(d, {}, function () {
            viewport.init("#annotateDiv");
            viewport.init("#bgDiv")
        })
}

function saveThisAnnotation() {
    var a = document.getElementById("idtype")
        .value;
    var b = document.getElementById("idvalue")
        .value;
    var c = document.getElementById("annotation")
        .value;
    if (c.length == 0) {
        alert("You must enter an annotation to save.");
        return false
    }
    $.getJSON("/component/functions.cfc", {
        method: "addAnnotation",
        idType: a,
        idvalue: b,
        annotation: c,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            closeAnnotation();
            alert("Your annotations have been saved, and the appropriate curator will be alerted. \n Thank you for helping improve Arctos!")
        } else {
            alert("An error occured! \n " + a)
        }
    })
}

function findPart(a, b, c) {
    var d = "/picks/findPart.cfm";
    var b = b.replace("%", "_");
    var e = d + "?part_name=" + b + "&collCde=" + c + "&partFld=" + a;
    partpick = window.open(e, "", "width=400,height=338, resizable,scrollbars")
}

function findPart_Atrribute(a, b, c) {
    var d = "/picks/findPart_Attribute.cfm";
    var b = b.replace("%", "_");
    var e = d + "?attribute_type=" + b + "&part_name=" + c + "&partFld2=" + a;
    attributepick = window.open(e, "", "width=400,height=338, resizable,scrollbars")
}

function changekillRows(a) {
    jQuery.getJSON("/users/component/functions.cfc", {
        method: "changekillRows",
        tgt: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a != "success") {
            alert("An error occured: " + a)
        }
    })
}

function blockSuggest(a) {
    $.getJSON("/users/component/functions.cfc", {
        method: "changeBlockSuggest",
        onoff: a,
        returnformat: "json",
        queryformat: "column"
    }, function (a) {
        if (a == "success") {
            $("#browseArctos")
                .html("Suggest Browser disabled. You may turn this feature back on under My Stuff.")
        } else {
            alert("An error occured! \n " + a)
        }
    })
}

function changeSpecimensDefaultAction (specimens_default_action) {
	$.getJSON("/component/functions.cfc", {
				method : "changeSpecimensDefaultAction",
				specimens_default_action : specimens_default_action,
				returnformat : "json",
				queryformat : 'column'
	}, function(r) {
		if (r == 'success') {
			$('#browseArctos').html('Default Tab for the Specimen Search changed.');
		} else {
			alert('An error occured! \n ' + r);
		}	
	});
}

function changeSpecimensPinGuid (specimens_pin_guid) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeSpecimensPinGuid",
				specimens_pin_guid : specimens_pin_guid,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Pin GUID Column setting for the Specimen Search changed.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}

function changeSpecimensPageSize (specimens_pagesize) {
	$.getJSON("/component/functions.cfc",
			{
				method : "changeSpecimensPageSize",
				specimens_pagesize : specimens_pagesize,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				if (r == 'success') {
					$('#browseArctos').html('Page Size setting for the Specimen Search changed.');
				} else {
					alert('An error occured! \n ' + r);
				}	
			}
		);
}

function getMedia(a, b, c, d, e) {
    $("#imgBrowserCtlDiv")
        .append('<img src="/images/indicator.gif">');
    var a;
    var b;
    var c;
    var d;
    var e;
    var f = "/form/inclMedia.cfm?typ=" + a + "&q=" + b + "&tgt=" + c + "&rpp=" + d + "&pg=" + e;
    jQuery.get(f, function (a) {
        jQuery("#" + c)
            .html(a)
    })
}
var viewport = {
    o: function () {
        if (self.innerHeight) {
            this.pageYOffset = self.pageYOffset;
            this.pageXOffset = self.pageXOffset;
            this.innerHeight = self.innerHeight;
            this.innerWidth = self.innerWidth
        } else if (document.documentElement && document.documentElement.clientHeight) {
            this.pageYOffset = document.documentElement.scrollTop;
            this.pageXOffset = document.documentElement.scrollLeft;
            this.innerHeight = document.documentElement.clientHeight;
            this.innerWidth = document.documentElement.clientWidth
        } else if (document.body) {
            this.pageYOffset = document.body.scrollTop;
            this.pageXOffset = document.body.scrollLeft;
            this.innerHeight = document.body.clientHeight;
            this.innerWidth = document.body.clientWidth
        }
        return this
    },
    init: function (a) {
        jQuery(a)
            .css("left", Math.round(viewport.o()
                    .innerWidth / 2) + viewport.o()
                .pageXOffset - Math.round(jQuery(a)
                    .width() / 2));
        jQuery(a)
            .css("top", Math.round(viewport.o()
                    .innerHeight / 2) + viewport.o()
                .pageYOffset - Math.round(jQuery(a)
                    .height() / 2))
    }
};
var dateFormat = function () {
    var a = /d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,
        b = /\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b/g,
        c = /[^-+\dA-Z]/g,
        d = function (a, b) {
            a = String(a);
            b = b || 2;
            while (a.length < b) a = "0" + a;
            return a
        };
    return function (e, f, g) {
        var h = dateFormat;
        if (arguments.length == 1 && Object.prototype.toString.call(e) == "[object String]" && !/\d/.test(e)) {
            f = e;
            e = undefined
        }
        e = e ? new Date(e) : new Date;
        if (isNaN(e)) throw SyntaxError("invalid date");
        f = String(h.masks[f] || f || h.masks["default"]);
        if (f.slice(0, 4) == "UTC:") {
            f = f.slice(4);
            g = true
        }
        var i = g ? "getUTC" : "get",
            j = e[i + "Date"](),
            k = e[i + "Day"](),
            l = e[i + "Month"](),
            m = e[i + "FullYear"](),
            n = e[i + "Hours"](),
            o = e[i + "Minutes"](),
            p = e[i + "Seconds"](),
            q = e[i + "Milliseconds"](),
            r = g ? 0 : e.getTimezoneOffset(),
            s = {
                d: j,
                dd: d(j),
                ddd: h.i18n.dayNames[k],
                dddd: h.i18n.dayNames[k + 7],
                m: l + 1,
                mm: d(l + 1),
                mmm: h.i18n.monthNames[l],
                mmmm: h.i18n.monthNames[l + 12],
                yy: String(m)
                    .slice(2),
                yyyy: m,
                h: n % 12 || 12,
                hh: d(n % 12 || 12),
                H: n,
                HH: d(n),
                M: o,
                MM: d(o),
                s: p,
                ss: d(p),
                l: d(q, 3),
                L: d(q > 99 ? Math.round(q / 10) : q),
                t: n < 12 ? "a" : "p",
                tt: n < 12 ? "am" : "pm",
                T: n < 12 ? "A" : "P",
                TT: n < 12 ? "AM" : "PM",
                Z: g ? "UTC" : (String(e)
                        .match(b) || [""])
                    .pop()
                    .replace(c, ""),
                o: (r > 0 ? "-" : "+") + d(Math.floor(Math.abs(r) / 60) * 100 + Math.abs(r) % 60, 4),
                S: ["th", "st", "nd", "rd"][j % 10 > 3 ? 0 : (j % 100 - j % 10 != 10) * j % 10]
            };
        return f.replace(a, function (a) {
            return a in s ? s[a] : a.slice(1, a.length - 1)
        })
    }
}();
dateFormat.masks = {
    "default": "ddd mmm dd yyyy HH:MM:ss",
    shortDate: "m/d/yy",
    mediumDate: "mmm d, yyyy",
    longDate: "mmmm d, yyyy",
    fullDate: "dddd, mmmm d, yyyy",
    shortTime: "h:MM TT",
    mediumTime: "h:MM:ss TT",
    longTime: "h:MM:ss TT Z",
    isoDate: "yyyy-mm-dd",
    isoTime: "HH:MM:ss",
    isoDateTime: "yyyy-mm-dd'T'HH:MM:ss",
    isoUtcDateTime: "UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"
};
dateFormat.i18n = {
    dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
};
Date.prototype.format = function (a, b) {
    return dateFormat(this, a, b)
};
jQuery(document)
    .ready(function () {
        jQuery(".helpLink")
            .live("click", function (a) {
                var b = this.id;
                removeHelpDiv();
                var c = document.createElement("div");
                c.id = "bgDiv";
                c.className = "bgDiv";
                c.setAttribute("onclick", "removeHelpDiv()");
                document.body.appendChild(c);
                var d = document.createElement("div");
                d.id = "helpDiv";
                d.className = "helpBox";
                d.innerHTML = "<br>Loading...";
                document.body.appendChild(d);
                jQuery("#helpDiv")
                    .css({
                        position: "absolute",
                        top: a.pageY,
                        left: a.pageX
                    });
                jQuery(d)
                    .load("/service/get_doc_rest.cfm", {
                        fld: b,
                        addCtl: 1
                    })
            });
        jQuery("#c_collection_cust")
            .click(function (a) {
                var b = document.createElement("div");
                b.id = "bgDiv";
                b.className = "bgDiv";
                b.setAttribute("onclick", "closeAndRefresh()");
                document.body.appendChild(b);
                var c = document.createElement("div");
                c.id = "customDiv";
                c.className = "sscustomBox";
                c.innerHTML = "<br>Loading...";
                document.body.appendChild(c);
                var d = "/includes/SpecSearch/changeCollection.cfm";
                jQuery(c)
                    .load(d, {}, function () {
                        viewport.init("#customDiv");
                        viewport.init("#bgDiv")
                    })
            });
        jQuery("#c_identifiers_cust")
            .click(function (a) {
                var b = document.createElement("div");
                b.id = "bgDiv";
                b.className = "bgDiv";
                b.setAttribute("onclick", "closeAndRefresh()");
                document.body.appendChild(b);
                var c = document.createElement("div");
                c.id = "customDiv";
                c.className = "sscustomBox";
                c.innerHTML = "<br>Loading...";
                document.body.appendChild(c);
                var d = "/includes/SpecSearch/customIDs.cfm";
                jQuery(c)
                    .load(d, {}, function () {
                        viewport.init("#customDiv");
                        viewport.init("#bgDiv")
                    })
            })
    });
if (self != top) {
    if (parent.frames[0].thisStyle) {
        changeStyle(parent.frames[0].thisStyle)
    }
}(function (a) {
    a.fn.superfish = function (b) {
        var c = a.fn.superfish,
            d = c.c,
            e = a(['<span class="', d.arrowClass, '"> &#187;</span>'].join("")),
            f = function () {
                var b = a(this),
                    c = h(b);
                clearTimeout(c.sfTimer);
                b.showSuperfishUl()
                    .siblings()
                    .hideSuperfishUl()
            },
            g = function () {
                var b = a(this),
                    d = h(b),
                    e = c.op;
                clearTimeout(d.sfTimer);
                d.sfTimer = setTimeout(function () {
                    e.retainPath = a.inArray(b[0], e.$path) > -1;
                    b.hideSuperfishUl();
                    if (e.$path.length && b.parents(["li.", e.hoverClass].join(""))
                        .length < 1) {
                        f.call(e.$path)
                    }
                }, e.delay)
            },
            h = function (a) {
                var b = a.parents(["ul.", d.menuClass, ":first"].join(""))[0];
                c.op = c.o[b.serial];
                return b
            },
            i = function (a) {
                a.addClass(d.anchorClass)
                    .append(e.clone())
            };
        return this.each(function () {
                var e = this.serial = c.o.length;
                var h = a.extend({}, c.defaults, b);
                h.$path = a("li." + h.pathClass, this)
                    .slice(0, h.pathLevels)
                    .each(function () {
                        a(this)
                            .addClass([h.hoverClass, d.bcClass].join(" "))
                            .filter("li:has(ul)")
                            .removeClass(h.pathClass)
                    });
                c.o[e] = c.op = h;
                a("li:has(ul)", this)[a.fn.hoverIntent && !h.disableHI ? "hoverIntent" : "hover"](f, g)
                    .each(function () {
                        if (h.autoArrows) i(a(">a:first-child", this))
                    })
                    .not("." + d.bcClass)
                    .hideSuperfishUl();
                var j = a("a", this);
                j.each(function (a) {
                    var b = j.eq(a)
                        .parents("li");
                    j.eq(a)
                        .focus(function () {
                            f.call(b)
                        })
                        .blur(function () {
                            g.call(b)
                        })
                });
                h.onInit.call(this)
            })
            .each(function () {
                var b = [d.menuClass];
                if (c.op.dropShadows && !(a.browser.msie && a.browser.version < 7)) b.push(d.shadowClass);
                a(this)
                    .addClass(b.join(" "))
            })
    };
    var b = a.fn.superfish;
    b.o = [];
    b.op = {};
    b.IE7fix = function () {
        var c = b.op;
        if (a.browser.msie && a.browser.version > 6 && c.dropShadows && c.animation.opacity != undefined) this.toggleClass(b.c.shadowClass + "-off")
    };
    b.c = {
        bcClass: "sf-breadcrumb",
        menuClass: "sf-js-enabled",
        anchorClass: "sf-with-ul",
        arrowClass: "sf-sub-indicator",
        shadowClass: "sf-shadow"
    };
    b.defaults = {
        hoverClass: "sfHover",
        pathClass: "overideThisToUse",
        pathLevels: 1,
        delay: 800,
        animation: {
            opacity: "show"
        },
        speed: "normal",
        autoArrows: true,
        dropShadows: true,
        disableHI: false,
        onInit: function () {},
        onBeforeShow: function () {},
        onShow: function () {},
        onHide: function () {}
    };
    a.fn.extend({
        hideSuperfishUl: function () {
            var c = b.op,
                d = c.retainPath === true ? c.$path : "";
            c.retainPath = false;
            var e = a(["li.", c.hoverClass].join(""), this)
                .add(this)
                .not(d)
                .removeClass(c.hoverClass)
                .find(">ul")
                .hide()
                .css("visibility", "hidden");
            c.onHide.call(e);
            return this
        },
        showSuperfishUl: function () {
            var a = b.op,
                c = b.c.shadowClass + "-off",
                d = this.addClass(a.hoverClass)
                .find(">ul:hidden")
                .css("visibility", "visible");
            b.IE7fix.call(d);
            a.onBeforeShow.call(d);
            d.animate(a.animation, a.speed, function () {
                b.IE7fix.call(d);
                a.onShow.call(d)
            });
            return this
        }
    })
})(jQuery);
(function (a) {
    a.fn.supersubs = function (b) {
        var c = a.extend({}, a.fn.supersubs.defaults, b);
        return this.each(function () {
            var b = a(this);
            var d = a.meta ? a.extend({}, c, b.data()) : c;
            var e = a('<li id="menu-fontsize">&#8212;</li>')
                .css({
                    padding: 0,
                    position: "absolute",
                    top: "-999em",
                    width: "auto"
                })
                .appendTo(b)
                .width();
            a("#menu-fontsize")
                .remove();
            $ULs = b.find("ul");
            $ULs.each(function (b) {
                var c = $ULs.eq(b);
                var f = c.children();
                var g = f.children("a");
                var h = f.css("white-space", "nowrap")
                    .css("float");
                var i = c.add(f)
                    .add(g)
                    .css({
                        "float": "none",
                        width: "auto"
                    })
                    .end()
                    .end()[0].clientWidth / e;
                i += d.extraWidth;
                if (i > d.maxWidth) {
                    i = d.maxWidth
                } else if (i < d.minWidth) {
                    i = d.minWidth
                }
                i += "em";
                c.css("width", i);
                f.css({
                        "float": h,
                        width: "100%",
                        "white-space": "normal"
                    })
                    .each(function () {
                        var b = a(">ul", this);
                        var c = b.css("left") !== undefined ? "left" : "right";
                        b.css(c, i)
                    })
            })
        })
    };
    a.fn.supersubs.defaults = {
        minWidth: 9,
        maxWidth: 25,
        extraWidth: 0
    }
})(jQuery);
(function (a) {
    a.fn.hoverIntent = function (b, c) {
        var d = {
            sensitivity: 7,
            interval: 100,
            timeout: 0
        };
        d = a.extend(d, c ? {
            over: b,
            out: c
        } : b);
        var e, f, g, h;
        var i = function (a) {
            e = a.pageX;
            f = a.pageY
        };
        var j = function (b, c) {
            c.hoverIntent_t = clearTimeout(c.hoverIntent_t);
            if (Math.abs(g - e) + Math.abs(h - f) < d.sensitivity) {
                a(c)
                    .unbind("mousemove", i);
                c.hoverIntent_s = 1;
                return d.over.apply(c, [b])
            } else {
                g = e;
                h = f;
                c.hoverIntent_t = setTimeout(function () {
                    j(b, c)
                }, d.interval)
            }
        };
        var k = function (a, b) {
            b.hoverIntent_t = clearTimeout(b.hoverIntent_t);
            b.hoverIntent_s = 0;
            return d.out.apply(b, [a])
        };
        var l = function (b) {
            var c = (b.type == "mouseover" ? b.fromElement : b.toElement) || b.relatedTarget;
            while (c && c != this) {
                try {
                    c = c.parentNode
                } catch (b) {
                    c = this
                }
            }
            if (c == this) {
                return false
            }
            var e = jQuery.extend({}, b);
            var f = this;
            if (f.hoverIntent_t) {
                f.hoverIntent_t = clearTimeout(f.hoverIntent_t)
            }
            if (b.type == "mouseover") {
                g = e.pageX;
                h = e.pageY;
                a(f)
                    .bind("mousemove", i);
                if (f.hoverIntent_s != 1) {
                    f.hoverIntent_t = setTimeout(function () {
                        j(e, f)
                    }, d.interval)
                }
            } else {
                a(f)
                    .unbind("mousemove", i);
                if (f.hoverIntent_s == 1) {
                    f.hoverIntent_t = setTimeout(function () {
                        k(e, f)
                    }, d.timeout)
                }
            }
        };
        return this.mouseover(l)
            .mouseout(l)
    }
})(jQuery)
