description  'Background worker'

module Olelo::Worker
  def self.start
    @queue = Queue.new
    Thread.new do
      loop do
        begin
          @queue.pop.call
        rescue => ex
          Plugin.current.logger.error(ex)
        end
      end
    end
  end

  def self.defer(&block)
    @queue << block
  end
end

Application.hook :start do
  Worker.start
end
