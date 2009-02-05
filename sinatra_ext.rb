require 'sinatra/base'

class Sinatra::Base
  def self.pattern(key, pattern)
    @patterns ||= {}
    @patterns[key] = pattern
  end

  private

  def self.replace_regex(path, opts = {})
    keys = []
    patterns = opts.merge(@patterns)
    path.gsub!(/:(\w+)/) {|key|
      key = $1.to_sym
      keys << key
      patterns.has_key?(key) ? '(' + patterns[key].source + ')' : '([^/?&#\.]+)'
    }
    return Regexp.new('^' + path + '$'), keys
  end
  
  def insert_params(params, keys)
    (0..keys.length-1).each do |i|
      params[keys[i]] = params[:captures][i]
    end
  end
  
  %w(get put post delete head).each do |method|
    instance_eval %Q{
      alias old_#{method} #{method}
      def #{method}(*paths, &block)
        opts = paths.last.is_a?(Hash) ? paths.pop : {}
        paths.each do |path|
          path, keys = replace_regex(path, opts)
          old_#{method}(path, opts) do
            insert_params(params, keys)
            instance_eval(&block)
          end
        end
      end
    }
  end

end
