# 非确定性有限自动机， 由确定性有限自动机的单个配置变为一个可能的配置集合。

# 栈
Stack = Struct.new(:contents) do
  # 推入一个字符
  def push(character)
    Stack.new([character] + contents)
  end

  # 弹出一个字符
  def pop
    Stack.new(contents.drop(1))
  end

  # 获取栈顶字符
  def top
    contents.first
  end

  # 栈的字符串表示
  def inspect
    "#<Stack (#{top})#{contents.drop(1).join}>"
  end
end

# 配置 = Stack + current state
PDAConfiguration = Struct.new(:state, :stack) do
  STUCK_STATE = Object.new

  # 定义阻塞态
  def stuck
    PDAConfiguration.new(STUCK_STATE, stack)
  end

  # 判断当前状态是否是阻塞状态
  def stuck?
    state == STUCK_STATE
  end
end

# 规则
PDARule = Struct.new(:state, :character, :next_state, :pop_character, :push_characters) do
  # 当前状态和栈是否匹配当前规则
  def applies_to?(configuration, character)
    state == configuration.state &&
      pop_character == configuration.stack.top &&
      self.character == character
  end

  # 返回下一个配置
  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration))
  end

  # 根据规则从栈中弹出、 推入字符
  def next_stack(configuration)
    popped_stack = configuration.stack.pop
    push_characters.reverse
                   .inject(popped_stack) { |stack, character| stack.push(character) }
  end
end

require 'set'
NPDARulebook = Struct.new(:rules) do
  # 计算下个可能状态的集合
  def next_configurations(configurations, character)
    configurations.flat_map { |config| follow_rules_for(config, character) }.to_set
  end

  # 可能有多条匹配的规则
  def follow_rules_for(configuration, character)
    rules_for(configuration, character).map { |rule| rule.follow(configuration) }
  end

  # 匹配的规则的集合
  def rules_for(configuration, character)
    rules.select { |rule| rule.applies_to?(configuration, character) }
  end

  # 自由移动
  def follow_free_moves(configurations)
    more_configurations = next_configurations(configurations, nil)
    if more_configurations.subset?(configurations)
      configurations
    else
      follow_free_moves(configurations + more_configurations)
    end
  end
end

# 非去定性有限状态自动机
class NPDA < Struct.new(:current_configurations, :accept_states, :rulebook)
  # 判断当前可能状态的集合是否可以被接受
  def accepting?
    current_configurations.any? { |config| accept_states.include?(config.state) }
  end

  # 读取字符， 计算下个可能状态的集合
  def read_character(character)
    self.current_configurations =
      rulebook.next_configurations(current_configurations, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end

  def current_configurations
    rulebook.follow_free_moves(super)
  end
end

# 每次生成新的NPDA
NPDADesign = Struct.new(:start_state, :bottom_character, :accept_states, :rulebook) do
  def accepts?(string)
    to_npda.tap { |npda| npda.read_string(string) }.accepting?
  end

  def to_npda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    NPDA.new(Set[start_configuration], accept_states, rulebook)
  end
end

# 识别偶数字符数回文子串的规则
rulebook = NPDARulebook.new([
                              PDARule.new(1, 'a', 1, '$', ['a', '$']),
                              PDARule.new(1, 'a', 1, 'a', %w[a a]),
                              PDARule.new(1, 'a', 1, 'b', %w[a b]),
                              PDARule.new(1, 'b', 1, '$', ['b', '$']),
                              PDARule.new(1, 'b', 1, 'a', %w[b a]),
                              PDARule.new(1, 'b', 1, 'b', %w[b b]),
                              PDARule.new(1, nil, 2, '$', ['$']),
                              PDARule.new(1, nil, 2, 'a', ['a']),
                              PDARule.new(1, nil, 2, 'b', ['b']),
                              PDARule.new(2, 'a', 2, 'a', []),
                              PDARule.new(2, 'b', 2, 'b', []),
                              PDARule.new(2, nil, 3, '$', ['$'])
                            ])

npda_design = NPDADesign.new(1, '$', [3], rulebook)
npda_design.accepts?('abba')
npda_design.accepts?('babbaabbab')
npda_design.accepts?('abb')
npda_design.accepts?('baabaa')
