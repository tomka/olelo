// Fetch gists from github and embed them
// Written by Daniel Mendler
(function($) {
    // Replace with numeric entities for xhtml compatibility
    var entities = {
            gt   : 62,
            lt   : 60,
            quot : 34,
            nbsp : 160,
            amp  : 38
    };
    // Underline access key
    $.fn.gist = function() {
        this.each(function() {
            var div = $(this), id = div.attr('id').match(/\d+/)[0];
            $.getJSON('http://gist.github.com/'+ id +'.json?callback=?', function(gist) {
                for (var i in entities)
                        gist.div = gist.div.replace(new RegExp('&' + i + ';', 'g'), '&#' + entities[i] + ';');
                div.replaceWith(gist.div);
            });
        });
    };
})(jQuery);
