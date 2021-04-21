# 指称语义， 将一个语言翻译为另一个语言

class Number
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Boolean
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Variable
  def to_ruby
    "-> e { e[#{name.inspect}] }"
  end
end

class Add
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end
end

class Multiply
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
  end
end

class LessThan
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end
end

class Assign
  def to_ruby
    "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
  end
end

class DoNothing
  def to_ruby
    '-> e { e }'
  end
end

class If
  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e)" +
      " then (#{consequence.to_ruby}).call(e)" +
      " else (#{alternative.to_ruby}).call(e)" +
      ' end }'
  end
end

class Sequence
  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end
end

class While
  def to_ruby
    '-> e {' +
      " while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" +
      ' e' +
      ' }'
  end
end

# test
statement =
  While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
  )
# 转换成ruby程序
proc = eval(statement.to_ruby)
# 执行
proc.call({ x: 1 })

require 'treetop'
Treetop.load('chapter2/simple')
parse_tree = SimpleParser.new.parse('while (x < 5) { x = x * 3 }')
statement = parse_tree.to_ast
eval(statement.to_ruby).call({ x: Number.new(1)})
