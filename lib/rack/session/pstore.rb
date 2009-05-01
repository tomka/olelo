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

      def set_session(env, session_id, new_session, options)
        @store.transaction do
          session = @store[session_id]
          if options[:renew] or options[:drop]
            @store.delete session_id
            return false if options[:drop]
            session_id = generate_sid
            @store[session_id] = 0
          end
          old_session = new_session.instance_variable_get('@old') || {}
          session = merge_sessions(session_id, old_session, new_session, session)
          @store[session_id] = session
          return session_id
        end
      end

      private

      def merge_sessions(sid, old, new, cur=nil)
        cur ||= {}
        unless Hash === old and Hash === new
          warn 'Bad old or new sessions provided.'
          return cur
        end

        delete = old.keys - new.keys
        delete.each{|k| cur.delete k }

        update = new.keys.select{|k| new[k] != old[k] }
        update.each{|k| cur[k] = new[k] }

        cur
      end
    end
  end
end
