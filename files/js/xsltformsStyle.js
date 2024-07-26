function repeat() {
    var element = document.querySelectorAll('div.xforms-repeat');
    for (var i = 0; i &lt; element.length; i++) {
        if (element[i].querySelectorAll('div.xforms-repeat').length > 0) {
            element[i].classList.add('repeat');
        }
    }
}