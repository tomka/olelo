description 'Shell utility'

class Olelo::Shell
  def run(data = nil)
    self.class.run(@cmd.compact.join(' | '), data)
  end

  def cmd(*args)
    yield(args) if block_given?
    (@cmd ||= []) << args.join(' ')
    self
  end

  def method_missing(*args, &block)
    cmd(*args, &block)
  end

  def self.method_missing(*args, &block)
    new.cmd(*args, &block)
  end

  def self.escape(*args)
    args.map {|s| "'" + s.to_s.gsub("'", "'\\\\''") + "'" }.join(' ')
  end

  def self.run(cmd, data = nil)
    return `#{cmd}` if !data
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      output = ''
      len = 0
      begin
        while len < data.length
          if found = IO.select([stdout], [stdin], nil, 0)
            len += stdin.write_nonblock(data[len..-1]) if found[1].first
            output << stdout.read_nonblock(1048576) if found[0].first
          end
        end
      rescue Errno::EPIPE
      end
      stdin.close
      begin
        output << stdout.read
      rescue Errno::EAGAIN
        retry
      end
      output
    end
  end
end
