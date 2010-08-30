if (window.Olelo) {
    var match = match = /text\/x-(\w+)/.exec(Olelo.page_mime);
    if (match)
	$('#edit-content').markupEditor(match[1]);
}
