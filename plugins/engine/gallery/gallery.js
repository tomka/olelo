function shadow(html) {
    return '<div class="shadow-outer"><div class="shadow"><div class="shadow"><div class="shadow"><div class="shadow"><div class="shadow-inner">' +
	html + '</div></div></div></div></div></div>';
}

$(function() {
    $('.thumbs a').each(function() {
	$(this).html(shadow($(this).html()));
    });
    $('.thumbs a').click(function() {
	$('.screen').html(shadow('<img src="' + this.href + '"/>'));
	return false;
    });
});
