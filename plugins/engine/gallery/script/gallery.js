(function() {
    var preloaded = [];
    function preloadImage(src) {
        var preload = document.createElement('img');
        preload.src = src;
        preloaded.push(preload);
    }

    function initGallery() {
        var screen = $('#gallery-screen');
        if (screen.length) {
            var img1 = $('<img/>'),
                img2 = $('<img/>');

            screen.append(img1).append(img2);

            $('#gallery-thumbs a').click(function() {
                img2.hide().attr('src', this.href);
                img1.fadeOut('slow');
                img2.fadeIn('slow');
                var tmp = img1;
                img1 = img2;
                img2 = tmp;
                return false;
            }).each(function() {
                preloadImage(this.href);
            });
        }
    }

    $('#page').bind('pageLoaded', initGallery);
    initGallery();
})();
