description  'Tilt filter'
dependencies 'engine/filter'
require      'tilt'

class TiltFilter < Filter
  def initialize(options)
    super
    raise "Option 'tilt_template' is required" if !options[:tilt_template]
    @template_class = Tilt[options[:tilt_template]] || raise("Tilt template '#{options[:tilt_template]}' not found")
  end

  def filter(context, content)
    template = @template_class.new(options[:tilt_options]) { content }
    template.render(context)
  end
end

Filter.register :tilt, TiltFilter
