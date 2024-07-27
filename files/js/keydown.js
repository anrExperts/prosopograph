function KeyPress(e) {
    var evtobj = window.event ? event : e
    if (evtobj.key == 1 && evtobj.ctrlKey) var toogle = 'sources';
    if (evtobj.key == 2 && evtobj.ctrlKey) var toogle = 'identity';
    if (evtobj.key == 3 && evtobj.ctrlKey) var toogle = 'existDates';
    if (evtobj.key == 4 && evtobj.ctrlKey) var toogle = 'functions';
    if (evtobj.key == 5 && evtobj.ctrlKey) var toogle = 'occupations';
    if (evtobj.key == 6 && evtobj.ctrlKey) var toogle = 'places';
    if (evtobj.key == 7 && evtobj.ctrlKey) var toogle = 'biogHist';
    if (evtobj.key == 8 && evtobj.ctrlKey) var toogle = 'relations';
    if (evtobj.key == 9 && evtobj.ctrlKey) var toogle = 'comment';

    XsltForms_xmlevents.dispatch(document.getElementById("entity"), "callbackKeydown", null, null, null, null, { response: toogle });
}

document.onkeydown = KeyPress;