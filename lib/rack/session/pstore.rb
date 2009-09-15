# -*- coding: utf-8 -*-
require 'rack/session/abstract/id'
require 'pstore'
require 'fileutils'

module Rack
  module Session
    class PStore < Abstract::ID
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge({
        :file => '/tmp/rack.pstore'
      })

      def initialize(app, options={})
        super
        FileUtils.mkdir_p ::File.dirname(@default_options[:file]), :mode => 0755
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
          if options[:drop]
	    @store.delete session_id
	  elsif options[:renew]
            @store.delete session_id
            session_id = generate_sid
          end
          @store[session_id] = new_session
	  session_id
	end
      end

    end
  end
end
