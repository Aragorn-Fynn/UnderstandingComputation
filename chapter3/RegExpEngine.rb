# 正则表达式引擎

# 有限自动机规则， 根据自动机当前状态和读取到的字符计算下个状态
FARule = Struct.new(:state, :character, :next_state) do
  # 判断当前规则是否匹配
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow
    next_state
  end

  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

require 'set'

# 规则手册， 每个状态读取一个字符之后可能转移到多个状态
NFARulebook = Struct.new(:rules) do
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end

  # 自由移动：不需要读取字符， 就可以转移状态
  def follow_free_moves(states)
    more_states = next_states(states, nil)
    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states)
    end
  end
end

NFA = Struct.new(:current_states, :accept_states, :rulebook) do
  def accepting?
    (current_states & accept_states).any?
  end

  def current_state(states)
    rulebook.follow_free_moves(states)
  end

  # 读取字符， 计算下一步的状态集合
  def read_character(character)
    # 计算当前状态自由移动后的状态
    self.current_states = current_state(current_states)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

# 为每个NFA创建一个对象
NFADesign = Struct.new(:start_state, :accept_states, :rulebook) do
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end




module Pattern
  def bracket(outer_precedence)
    if precedence < outer_precedence
      '(' + to_s + ')'
    else
      to_s
    end
  end

  def inspect
    "/#{self}/"
  end

  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

# 空字符串
class Empty
  include Pattern
  def to_s
    ''
  end

  def precedence
    3
  end

  # 转换为NFA, 因为只接受空字符串， 所以没有规则
  def to_nfa_design
    start_state = Object.new
    accept_states = [start_state]
    rulebook = NFARulebook.new([])
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

# 字符: a、b、c
Literal = Struct.new(:character) do
  include Pattern
  def to_s
    character
  end

  def precedence
    3
  end

  # 转换为DFA， 起始状态读取一个字符转换到接受状态
  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rule = FARule.new(start_state, character, accept_state)
    rulebook = NFARulebook.new([rule])
    NFADesign.new(start_state, [accept_state], rulebook)
  end
end

# 连接： ab
Concatenate = Struct.new(:first, :second) do
  include Pattern
  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join
  end

  def precedence
    1
  end

  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design
    start_state = first_nfa_design.start_state
    accept_states = second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = first_nfa_design.accept_states.map do |state|
      FARule.new(state, nil, second_nfa_design.start_state)
    end
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

# 选择： a|b
Choose = Struct.new(:first, :second) do
  include Pattern
  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
  end

  def precedence
    0
  end

  def to_nfa_design
    first_nfa_design = first.to_nfa_design
    second_nfa_design = second.to_nfa_design
    start_state = Object.new
    accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
    rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
    extra_rules = [first_nfa_design, second_nfa_design].map do |nfa_design|
      FARule.new(start_state, nil, nfa_design.start_state)
    end
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

# 重复： a*
Repeat = Struct.new(:pattern) do
  include Pattern
  def to_s
    pattern.bracket(precedence) + '*'
  end

  def precedence
    2
  end

  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design
    start_state = Object.new
    accept_states = pattern_nfa_design.accept_states + [start_state]
    rules = pattern_nfa_design.rulebook.rules
    extra_rules =
      pattern_nfa_design.accept_states.map do |accept_state|
        FARule.new(accept_state, nil, pattern_nfa_design.start_state)
      end +
      [FARule.new(start_state, nil, pattern_nfa_design.start_state)]
    rulebook = NFARulebook.new(rules + extra_rules)
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

# test
pattern =
  Repeat.new(
    Choose.new(
      Concatenate.new(Literal.new('a'), Literal.new('b')),
      Literal.new('a')
    )
  )

nfa_design = Empty.new.to_nfa_design
nfa_design.accepts?('')
nfa_design.accepts?('a')
nfa_design = Literal.new('a').to_nfa_design
nfa_design.accepts?('')
nfa_design.accepts?('a')
nfa_design.accepts?('b')
Empty.new.matches?('a')
Literal.new('a').matches?('a')

pattern = Concatenate.new(Literal.new('a'), Literal.new('b'))
pattern.matches?('a')
pattern.matches?('ab')
pattern.matches?('abc')

pattern = Choose.new(Literal.new('a'), Literal.new('b'))
pattern.matches?('a')
pattern.matches?('b')
pattern.matches?('c')

pattern = Repeat.new(Literal.new('a'))
pattern.matches?('')
pattern.matches?('a')
pattern.matches?('aaaa')
pattern.matches?('b')

pattern =
  Repeat.new(
    Concatenate.new(
      Literal.new('a'),
      Choose.new(Empty.new, Literal.new('b'))
    )
  )
pattern.matches?('')
pattern.matches?('a')
pattern.matches?('abab')
pattern.matches?('abaab')
pattern.matches?('abba')

require 'treetop'
Treetop.load('chapter3/pattern')
parse_tree = PatternParser.new.parse('(a(|b))*')
pattern = parse_tree.to_ast
pattern.matches?('abaab')
pattern.matches?('abba')
