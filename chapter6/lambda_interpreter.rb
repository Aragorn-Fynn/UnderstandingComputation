# 实现 lambda表达式解释器

# 变量
LCVariable = Struct.new(:name) do
  # 替换变量
  def replace(name, replacement)
    if self.name == name
      replacement
    else
      self
    end
  end

  def callable?
    false
  end

  def reducible?
    false
  end

  def to_s
    name.to_s
  end

  def inspect
    to_s
  end
end

# 函数定义
LCFunction = Struct.new(:parameter, :body) do
  # 替换变量
  def replace(name, replacement)
    if parameter == name
      self
    else
      LCFunction.new(parameter, body.replace(name, replacement))
    end
  end

  # 调用函数
  def call(argument)
    body.replace(parameter, argument)
  end


  def callable?
    true
  end

  def reducible?
    false
  end

  def to_s
    "-> #{parameter} { #{body} }"
  end

  def inspect
    to_s
  end
end

# 函数调用
LCCall = Struct.new(:left, :right) do
  # 替换变量
  def replace(name, replacement)
    LCCall.new(left.replace(name, replacement), right.replace(name, replacement))
  end

  def callable?
    false
  end

  def reducible?
    left.reducible? || right.reducible? || left.callable?
  end

  # 规约
  def reduce
    if left.reducible?
      LCCall.new(left.reduce, right)
    elsif right.reducible?
      LCCall.new(left, right.reduce)
    else
      left.call(right)
    end
  end

  def to_s
    "#{left}[#{right}]"
  end

  def inspect
    to_s
  end
end

expression = LCCall.new(LCCall.new(add, one), one)
while expression.reducible?
  puts expression
  expression = expression.reduce
end; puts expression

require 'treetop'
Treetop.load('chapter6/lambda_calculus')
parse_tree = LambdaCalculusParser.new.parse('-> x { x[x] }[-> y { y }]')
expression = parse_tree.to_ast
expression.reduce
