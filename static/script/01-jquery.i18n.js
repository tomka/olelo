// Very simple i18n plugin
// Written by Daniel Mendler
(function($) {
        var locale = null, translations = {};
        $.translations = function(t) {
                for (var lang in t) {
                        if (!translations[lang]) {
                                translations[lang] = t[lang];
                                continue;
                        }
                        for (var key in t[lang])
                                translations[lang][key] = t[lang][key];
                }
        };
        function lookup(locale, name, args) {
                var t = translations[locale], s;
                if (t && (s = t[name])) {
                        for (var key in args)
                                s = s.replace(new RegExp('#{' + key + '}', 'g'), args[key]);
                        return s;
                }
        }
        $.t = function(name, args) {
                if (!locale) {
                        var html = $('html');
                        locale = html.attr('lang') || html.attr('xml:lang') || 'en';
                }
                var i, s = lookup(locale, name, args);
                if (!s && (i = locale.indexOf('-')))
                        s = lookup(locale.substr(0, i), name, args);
                return s || '#' + name;
         };
})(jQuery);
