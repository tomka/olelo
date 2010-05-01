(function($) {
    $('#gallery-screen').html('<img id="gallery-image1"/><img id="gallery-image2"/>');

    var img1 = $('#gallery-image1');
    var img2 = $('#gallery-image2');
    var preloaded = [];

    $('#gallery-thumbs a').click(function(e) {
	e.preventDefault();
        img2.hide().attr('src', this.href);
        img1.fadeOut('slow');
        img2.fadeIn('slow');
        var tmp = img1;
        img1 = img2;
        img2 = tmp;
        return false;
    }).each(function() {
      var preload = document.createElement('img');
      preload.src = this.href;
      preloaded.push(preload);
    });
})(jQuery);
