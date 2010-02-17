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
        $.t = function(name, opts) {
                if (!locale) {
                        var html = $('html');
                        locale = html.attr('lang') || html.attr('xml:lang') || 'en';
                }
                var t = translations[locale], s;
                if (t && (s = t[name])) {
                        for (var key in opts)
                                s = s.replace(new RegExp('#{' + key + '}', 'g'), opts[key]);
                        return s;
                }
                return '#' + name;
         };
})(jQuery);
