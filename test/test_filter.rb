require 'wiki/filter'

class TC_Filter < Test::Unit::TestCase

  class SimplePrependMachine
    extend Wiki::Filter
    
    def process(data)
      data + "\nfound"
    end

    prepend_method :process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    prepend_method :process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class PrependSugarMachine
    extend Wiki::Filter
    
    def process(data)
      data + "\nfound"
    end

    prepend_process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    prepend_process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class SimpleAppendMachine
    extend Wiki::Filter
    
    def process(data)
      data + "\nfound"
    end

    append_method :process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    append_method :process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class AppendSugarMachine
    extend Wiki::Filter
    
    def process(data)
      data + "\nfound"
    end

    append_process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    append_process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class SimpleAroundMachine
    extend Wiki::Filter

    def work(data)
      "work with " + data
    end

    around_method :work do |proc, data|
      proc["before " + data] + " after"
    end

    def work2(data1, data2)
      ["1 " + data1, "2 " + data2]
    end

    around_method :work2 do |proc, data1, data2|
      a, b = proc["before " + data1, "before " + data2]
      [a + " after", b + " after"]
    end
  end

  class AroundSugarMachine
    extend Wiki::Filter

    def work(data)
      "work with " + data
    end

    around_work do |proc, data|
      proc["before " + data] + " after"
    end

    def work2(data1, data2)
      ["1 " + data1, "2 " + data2]
    end

    around_work2 do |proc, data1, data2|
      a, b = proc["before " + data1, "before " + data2]
      [a + " after", b + " after"]
    end
  end

  class SuperMachine
    extend Wiki::Filter

    def work(a, b)
      ["#{a}1", "#{b}1"]
    end

    prepend_work do |a,b|
      ["#{a}2", "#{b}2"]
    end

    append_work do |a,b|
      ["#{a}3", "#{b}3"]
    end

    around_work do |proc,a,b|
      a, b = proc["4#{a}", "4#{b}"]
      ["#{a}5", "#{b}5"]
    end
  end

  class SuperMachine2
    extend Wiki::Filter

    def work(a, b)
      ["#{a}1", "#{b}1"]
    end

    def work_step2(a, b)
      ["#{a}2", "#{b}2"]
    end

    def work_step3(a, b)
      ["#{a}3", "#{b}3"]
    end

    def work_step4(proc, a, b)
      a, b = proc["4#{a}", "4#{b}"]
      ["#{a}5", "#{b}5"]
    end

    prepend_work :work_step2
    append_work :work_step3
    around_work :work_step4
  end

  def test_prepend
    machine = SimplePrependMachine.new
    assert_equal "metal\nmelt\nfound", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n1\n2", a
    assert_equal "b\n1\n2", b
  end

  def test_sugar_prepend
    machine = PrependSugarMachine.new
    assert_equal "metal\nmelt\nfound", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n1\n2", a
    assert_equal "b\n1\n2", b
  end

  def test_append
    machine = SimpleAppendMachine.new
    assert_equal "metal\nfound\nmelt", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n2\n1", a
    assert_equal "b\n2\n1", b
  end

  def test_sugar_append
    machine = AppendSugarMachine.new
    assert_equal "metal\nfound\nmelt", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n2\n1", a
    assert_equal "b\n2\n1", b
  end

  def test_around
    machine = SimpleAroundMachine.new
    assert_equal "work with before ruby after", machine.work('ruby')

    a,b = machine.work2("a", "b")
    assert_equal "1 before a after", a
    assert_equal "2 before b after", b
  end

  def test_around
    machine = AroundSugarMachine.new
    assert_equal "work with before ruby after", machine.work('ruby')

    a,b = machine.work2("a", "b")
    assert_equal "1 before a after", a
    assert_equal "2 before b after", b
  end

  def test_super
    machine = SuperMachine.new
    a,b = machine.work("a", "b")
    assert_equal "4a2135", a
    assert_equal "4b2135", b
  end

  def test_super2
    machine = SuperMachine2.new
    a,b = machine.work("a", "b")
    assert_equal "4a2135", a
    assert_equal "4b2135", b
  end
end
