$(function() {
    $('.thumbs a').click(function() {
	$('.screen').html('<img src="' + this.href + '"/>');
	return false;
    });
});
