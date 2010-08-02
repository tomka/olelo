description 'Semaphore class'

class Olelo::Semaphore
  def initialize(counter = 1)
    @mutex = Mutex.new
    @cond = ConditionVariable.new
    @counter = counter
  end

  def enter
    @mutex.synchronize do
      @cond.wait(@mutex) if (@counter -= 1) < 0
    end
  end

  def leave
    @mutex.synchronize do
      @cond.signal if (@counter += 1) <= 0
    end
  end

  def synchronize
    enter
    yield
  ensure
    leave
  end
end
