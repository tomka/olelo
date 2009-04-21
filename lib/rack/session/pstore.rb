require 'rack/session/abstract/id'

module Rack
  module Session
    class PStore < Abstract::ID
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge({
        :file => '/tmp/rack.pstore'
      })

      def initialize(app, options={})
        super
        @store = ::PStore.new(@default_options[:file])
      end

      private

      def get_session(env, sid)
        session = @store.transaction do
          unless sess = @store[sid] and ((expires = sess[:expire_at]).nil? or expires > Time.now)
            @store.roots.each do |k|
              v = @store[k]
              @store.delete(k) if expiry = v[:expire_at] && expiry < Time.now
            end
            begin
              sid = generate_sid
            end while @store.root?(sid)
          end
          @store[sid] ||= {}
        end
        [sid, session]
      end

      def set_session(env, sid)
        options = env['rack.session.options']
        expiry = options[:expire_after] && options[:at]+options[:expire_after]
        @store.transaction do
          old_session = @store[sid]
          old_session[:expire_at] = expiry if expiry
          session = old_session.merge(env['rack.session'])
          @store[sid] = session
        end
        true
      end
    end
  end
end
