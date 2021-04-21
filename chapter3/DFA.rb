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

# 规则手册：从多个规则中找到一个规则， 并且计算下个状态。
DFARulebook = Struct.new(:rules) do
  def next_state(state, character)
    rule_for(state, character).follow
  end

  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

# test
rulebook = DFARulebook.new([
                             FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
                             FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
                             FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)
                           ])

# DFA: 读取字符串， 判断字符串是否可以被当前DFA接受
DFA = Struct.new(:current_state, :accept_states, :rulebook) do
  # 判断当前状态是否可以接受
  def accepting?
    accept_states.include?(current_state)
  end

  # 读取一个字符
  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end

  # 读取字符串
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

dfa = DFA.new(1, [3], rulebook); dfa.accepting?
dfa.read_string('baaab'); dfa.accepting?

DFADesign = Struct.new(:start_state, :accept_states, :rulebook) do
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

#test
dfa_design = DFADesign.new(1, [3], rulebook)
dfa_design.accepts?('a')
dfa_design.accepts?('baa')
dfa_design.accepts?('baba')