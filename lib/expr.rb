module Expr

  NUMBER = /\d+/
  STRING = /'(?:[^']|\\')+'|"(?:[^"]|\\")+"/
  NAME = /[\w_]+/
  OPERATOR = [ %w(||), %w(&&), %w(== != <= >= < >), %w(+ -),
               %w(<< >>), %w(& | ^), %w(* / %), %w(**) ]

  OP = {}
  OPERATOR.each_with_index do |ops,i|
    ops.each { |op| OP[op] = i }
  end

  TOKENIZER = Regexp.new("#{NUMBER.source}|#{STRING.source}|#{NAME.source}|\\(|\\)|" +
                         OP.keys.map { |op| Regexp.quote(op) }.join('|'))

  def self.eval(expr, vars = {})
    tokens = expr.scan(TOKENIZER)
    stack, post = [], []
    tokens.each do |tok|
      if tok == '('
        stack << '('
      elsif tok == ')'
        op(post, stack.pop) while !stack.empty? && stack.last != '('
        stack.pop
      elsif OP.include?(tok)
        op(post, stack.pop) while !stack.empty? && stack.last != '(' && OP[stack.last] >= OP[tok]
        stack << tok
      elsif tok =~ STRING
        post << tok[1..-2]
      elsif tok =~ NUMBER
        post << tok.to_i
      else
        post << (vars[tok] || vars[tok.to_sym])
      end
    end
    op(post, stack.pop) while !stack.empty?
    post[0]
  end

  def self.op(stack, op)
    b = stack.pop
    a = stack.pop
    stack << case op
             when '==' then a == b
             when '!=' then a != b
             when '<=' then a <= b
             when '>=' then a >= b
             when '<' then a < b
             when '>' then a > b
             when '+' then a + b
             when '-' then a - b
             when '*' then a * b
             when '/' then a / b
             when '**' then a ** b
             end
  end

end
