function generateid(param) {
    let id;
    if(param !== null) {
        id = param + '_' + (performance.now().toString(36)+Math.random().toString(36)).replace(/\./g,"");
    } else {
        id = (performance.now().toString(36)+Math.random().toString(36)).replace(/\./g,"");
    }

    XsltForms_xmlevents.dispatch(document.getElementById("entity"), "callbackevent", null, null, null, null, { response: id });
}
console.log("generateid() est chagée")