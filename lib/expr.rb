module Expr

  INTEGER = /\d+/
  REAL = /\d*\.\d*(?:[eE][-+]?\d+)?/
  STRING = /'(?:[^']|\\')+'|"(?:[^"]|\\")+"/
  NAME = /[\w_]+/
  FUNCTIONS = %w(sin cos tan sinh cosh tanh asin acos atan asinh atanh sqrt log ln log10 log2 exp floor ceil string int float rand)
  OPERATOR = [ %w(||), %w(&&), %w(== != <= >= < >), %w(+ -),
             %w(<< >>), %w(& | ^), %w(* / %), %w(**) ]

  OP = {}
  (OPERATOR + [FUNCTIONS]).each_with_index do |ops,i|
    ops.each { |op| OP[op] = i }
  end

  TOKENIZER = Regexp.new("#{REAL.source}|#{INTEGER.source}|#{STRING.source}|#{NAME.source}|\\(|\\)|,|" +
                         OP.keys.map { |op| Regexp.quote(op) }.join('|'))

  def self.eval(expr, vars = {})
    tokens = expr.scan(TOKENIZER)
    stack, post = [], []
    tokens.each do |tok|
      if tok == '('
        stack << '('
      elsif tok == ')' || tok == ','
        op(post, stack.pop) while !stack.empty? && stack.last != '('
        stack.pop if tok == ')'
      elsif FUNCTIONS.include?(tok)
        stack << tok
      elsif OP.include?(tok)
        op(post, stack.pop) while !stack.empty? && stack.last != '(' && OP[stack.last] >= OP[tok]
        stack << tok
      elsif tok =~ STRING
        post << tok[1..-2]
      elsif tok =~ REAL
        post << tok.to_f
      elsif tok =~ INTEGER
        post << tok.to_i
      else
        post << (vars[tok] || vars[tok.to_sym])
      end
    end
    op(post, stack.pop) while !stack.empty?
    post[0]
  end

  def self.op(stack, op)
    stack << \
    if FUNCTIONS.include?(op)
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
      end
    else
      b = stack.pop
      a = stack.pop
      case op
      when '==' then a == b
      when '!=' then a != b
      when '<=' then a <= b
      when '>=' then a >= b
      when '<'  then a < b
      when '>'  then a > b
      when '+'  then a + b
      when '-'  then a - b
      when '*'  then a * b
      when '/'  then a / b
      when '**' then a ** b
      end
    end
  rescue
    nil
  end

end
