# 非确定性有限自动机

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

# test
rulebook = NFARulebook.new([
                             FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
                             FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
                             FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
                           ])

NFA = Struct.new(:current_states, :accept_states, :rulebook) do
  def accepting?
    (self.current_states & accept_states).any?
  end

  def current_state(states)
    rulebook.follow_free_moves(states)
  end

  # 读取字符， 计算下一步的状态集合
  def read_character(character)
    # 计算当前状态自由移动后的状态
    self.current_states = current_state(self.current_states)
    self.current_states = rulebook.next_states(self.current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end
# test
NFA.new(Set[1], [4], rulebook).accepting?

# 为每个NFA创建一个对象
NFADesign = Struct.new(:start_state, :accept_states, :rulebook) do
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

# test
rulebook = NFARulebook.new([
                             FARule.new(1, nil, 2), FARule.new(1, nil, 4),
                             FARule.new(2, 'a', 3),
                             FARule.new(3, 'a', 2),
                             FARule.new(4, 'a', 5),
                             FARule.new(5, 'a', 6),
                             FARule.new(6, 'a', 4)
                           ])
nfa_design = NFADesign.new(1, [2, 4], rulebook)
nfa_design.accepts?('aa')
nfa_design.accepts?('aaa')
nfa_design.accepts?('aaaaa')
nfa_design.accepts?('aaaaaa')
