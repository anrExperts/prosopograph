/*
* This function add "selected" class to xforms tabs
*/
document.addEventListener('click', function handleClick(event) {
    var target = event.target;
    var newActiveTab = target.closest('xforms-trigger.tab');
    console.log('change tab');

    if(target.closest('xforms-trigger.tab')) {
        const prevActiveTab = document.querySelectorAll('*');
        prevActiveTab.forEach((element) => { element.classList.remove("selected") });

        newActiveTab.classList.add('selected')
    }
});