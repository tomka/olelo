(function($) {
    $.store = {
	load: function() {
	    var data = '';
	    var i = 0;
	    var part;
	    while (part = $.cookie('store' + i)) {
		data += part;
		++i;
	    }
	    $.store.data = data.length != 0 ? $.evalJSON(data) : {};
	},
	get: function(name, fallback) {
	    return $.store.data[name] || fallback;
	},
	set: function(name, value) {
	    $.store.data[name] = value;
	    var data = $.toJSON($.store.data);
	    var blocksize = 1024;
	    for (var i = 0; blocksize * i < data.length; ++i)
		$.cookie('store' + i, data.substr(i * blocksize, blocksize), { expires: 365*100, path: '/' });
	}
    };
    $.store.load();
})(jQuery);
