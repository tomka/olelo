author      'Daniel Mendler'
description 'Anti-Spam'
require 'net/http'

class SpamEvaluator
  def self.bad_words
    @bad_words ||= File.read(File.join(File.dirname(__FILE__), 'antispam.words')).split("\n")
  end

  def initialize(user, params, resource)
    @user = user
    @params = params
    @resource = resource
  end

  def evaluate
    level = 0
    SpamEvaluator.instance_methods.select {|m| m.to_s.begins_with?('eval_') }.each do |m|
      level += send(m) || 0
    end
    level.to_i
  end

  def eval_uri_percentage
    data = @params[:content].to_s
    if data.size > 0
      size = 0
      data.scan(/((http|ftp):\/\/\S+?)(?=([,.?!:;"'\)])?(\s|$))/) { size += $1.size }
      ((size.to_f / data.size) * 300).to_i
    end
  end

  def eval_change_size
    data = @params[:content].to_s
    if !@resource.new? && @resource.content.size > 1024
      ratio = data.size.to_f / @resource.content.size
      if ratio == 0
        100
      elsif ratio < 1
        50 / ratio
      else
        50 * ratio
      end
    end
  end

  def eval_spam_words
    data = @params[:content].to_s.downcase
    SpamEvaluator.bad_words.any? {|word| data.index(word) } ? 100 : 0
  end

  def eval_uri_in_message
    @params[:message].to_s =~ %r{http://} ? 100 : 0
  end

  def eval_anonymous
    @user.anonymous? ? 50 : -50
  end

  def eval_invalid_encoding
    @params[:content].to_s.valid_encoding? ? 0 : 50
  end

  def eval_entropy
    counters = Array.new(256) {0}
    total = 0

    @params[:content].to_s.each_byte do |a|
      counters[a] += 1
      total += 1
    end

    h = 0
    counters.each do |count|
      p  = count.to_f / total
      h -= p * (Math.log(p) / Math.log(2)) if p > 0
    end

    (3 - h) * 50
  end
end

class Wiki::App
  hook(:before_edit_form_buttons) do
    if @show_captcha
      %{<br/><label for="recaptcha">#{:enter_captcha.t}</label><br/><div id="recaptcha"></div><br/>}
    end
  end

  hook(:after_script) do
    if @show_captcha
      %{<script type="text/javascript"  src="https://api-secure.recaptcha.net/js/recaptcha_ajax.js"></script>
        <script type="text/javascript">
          $(function() {
            Recaptcha.create('#{Config.recaptcha.public}',
              'recaptcha', {
              theme: 'clean',
              callback: Recaptcha.focus_response_field
            });
          });
        </script>}.unindent
    end
  end

  hook(:before_page_save) do |page|
    if (action?(:new) || action?(:edit)) && !captcha_valid?
      level = SpamEvaluator.new(user, params, @resource).evaluate
      message(:info, :spam_level.t(:level => level)) if !Config.production?
      if level >= 100
        @show_captcha = true
        halt haml(request.put? ? :edit : :new)
      end
    end
  end

  private

  def captcha_valid?
    if params[:recaptcha_challenge_field] && params[:recaptcha_response_field]
      response = Net::HTTP.post_form(URI.parse('http://api-verify.recaptcha.net/verify'),
                                     'privatekey' => Config.recaptcha.private,
                                     'remoteip'   => request.ip,
                                     'challenge'  => params[:recaptcha_challenge_field],
                                     'response'   => params[:recaptcha_response_field])
      if response.body.split("\n").first == 'true'
        message(:info, :captcha_valid.t)
        true
      else
        message(:error, :captcha_invalid.t)
        false
      end
    end
  end
end
