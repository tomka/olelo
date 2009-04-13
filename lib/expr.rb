require 'complex'

module Expr

  INTEGER = /\d+/
  REAL = /(?:\d*\.\d+(?:[eE][-+]?\d+)?|\d+[eE][-+]?\d+)/
  STRING = /'(?:[^']|\\')+'|"(?:[^"]|\\")+"/
  SYMBOL = /[\w_]+/
  FUNCTIONS = %w(sin cos tan sinh cosh tanh asin acos atan asinh atanh sqrt log ln log10 log2 exp
                 floor ceil string int float rand conj im re round abs minus plus not)
  OPERATOR = [ %w(|| or), %w(&& and), %w(== != <= >= < >), %w(+ -),
             %w(<< >>), %w(& | ^), %w(* / % div mod), %w(**), %w(!) ]
  UNARY = {
    '+' => 'plus',
    '-' => 'minus',
    '!' => 'not'
  }
  CONSTANTS = {
    'true'  => true,
    'false' => false,
    'nil'   => nil,
    'e'     => Math::E,
    'pi'    => Math::PI,
    'i'     => Complex::I
  }

  OP = {}
  (OPERATOR + [FUNCTIONS]).each_with_index do |ops,i|
    ops.each { |op| OP[op] = i }
  end

  TOKENIZER = Regexp.new("#{REAL.source}|#{INTEGER.source}|#{STRING.source}|#{SYMBOL.source}|\\(|\\)|,|" +
                         OP.keys.map { |op| Regexp.quote(op) }.join('|'))

  def self.eval(expr, vars = {})
    table = CONSTANTS.dup
    vars.each_pair {|k,v| table[k.downcase] = v }
    tokens = expr.scan(TOKENIZER)
    stack, post = [], []
    prev = nil
    tokens.each do |tok|
      if tok == '('
        stack << '('
      elsif tok == ')'
        op(post, stack.pop) while !stack.empty? && stack.last != '('
        raise(SyntaxError, "Unexpected token )") if stack.empty?
        stack.pop
      elsif tok == ','
        op(post, stack.pop) while !stack.empty? && stack.last != '('
      elsif FUNCTIONS.include?(tok.downcase)
        stack << tok.downcase
      elsif OP.include?(tok)
        if (prev == nil || OP.include?(prev)) && UNARY.include?(tok)
          stack << UNARY[tok]
        else
          op(post, stack.pop) while !stack.empty? && stack.last != '(' && OP[stack.last] >= OP[tok]
          stack << tok
        end
      elsif tok =~ STRING
        post << tok[1..-2]
      elsif tok =~ REAL
        post << tok.to_f
      elsif tok =~ INTEGER
        post << tok.to_i
      else
        tok.downcase!
        raise(NameError, "Symbol #{tok} is undefined") if !table.include?(tok)
        post << table[tok]
      end
      prev = tok
    end
    op(post, stack.pop) while !stack.empty?
    post[0]
  end

  def self.op(stack, op)
    stack << \
    if FUNCTIONS.include?(op)
      raise(SyntaxError, "Not enough operands on the stack") if stack.empty?
      a = stack.pop
      case op
      when 'sin'    then Math.sin(a)
      when 'cos'    then Math.cos(a)
      when 'tan'    then Math.tan(a)
      when 'sinh'   then Math.sinh(a)
      when 'cosh'   then Math.cosh(a)
      when 'tanh'   then Math.tanh(a)
      when 'asin'   then Math.asin(a)
      when 'acos'   then Math.acos(a)
      when 'atan'   then Math.atan(a)
      when 'asinh'  then Math.asinh(a)
      when 'atanh'  then Math.atanh(a)
      when 'sqrt'   then Math.sqrt(a)
      when 'log'    then Math.log(a)
      when 'ln'     then Math.log(a)
      when 'log10'  then Math.log10(a)
      when 'log2'   then Math.log2(a)
      when 'exp'    then Math.exp(a)
      when 'floor'  then Math.floor(a)
      when 'ceil'   then Math.ceil(a)
      when 'string' then a.to_s
      when 'float'  then a.to_f
      when 'int'    then a.to_i
      when 'rand'   then rand
      when 'conj'   then a.conj
      when 'im'     then a.imag
      when 're'     then a.real
      when 'round'  then a.round
      when 'abs'    then a.abs
      when 'plus'   then a
      when 'minus'  then -a
      when 'not'    then !a
      end
    else
      raise(SyntaxError, "Not enough operands on the stack") if stack.size < 2
      b = stack.pop
      a = stack.pop
      case op
      when '||'  then a || b
      when 'or'  then a || b
      when '&&'  then a && b
      when 'and' then a && b
      when '=='  then a == b
      when '!='  then a != b
      when '<='  then a <= b
      when '>='  then a >= b
      when '<'   then a < b
      when '>'   then a > b
      when '+'   then a + b
      when '-'   then a - b
      when '*'   then a * b
      when '/'   then a / b
      when 'div' then a.div(b)
      when '%'   then a % b
      when 'mod' then a % b
      when '**'  then a ** b
      when '<<'  then a << b
      when '>>'  then a >> b
      when '&'   then a & b
      when '|'   then a | b
      when '^'   then a ^ b
      else
        raise(SyntaxError, "Unexpected token #{op}")
      end
    end
  end

end
