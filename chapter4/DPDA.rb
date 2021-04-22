# 确定性下推自动机 = DFA + Stack

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

# 规则手册
DPDARulebook = Struct.new(:rules) do
  # 返回下个配置
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end

  # 找到匹配的规则
  def rule_for(configuration, character)
    rules.detect { |rule| rule.applies_to?(configuration, character) }
  end

  # 判断是否有匹配的规则
  def applies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end

  # 自由移动
  def follow_free_moves(configuration)
    if applies_to?(configuration, nil)
      follow_free_moves(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

# 确定性下推自动机
class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  # 判断当前状态是否可以被接受
  def accepting?
    accept_states.include?(current_configuration.state)
  end

  # 返回当前状态
  def current_configuration
    rulebook.follow_free_moves(super)
  end

  def next_configuration(character)
    # 如果有匹配的规则， 就应用；否则， 就转移到stuck状态。
    if rulebook.applies_to?(current_configuration, character)
      rulebook.next_configuration(current_configuration, character)
    else
      current_configuration.stuck
    end
  end

  def stuck?
    current_configuration.stuck?
  end

  # 读取字符
  def read_character(character)
    self.current_configuration = (next_configuration(character))
  end

  # 读字符串
  def read_string(string)
    string.chars.each do |character|
      read_character(character) unless stuck?
    end
  end
end

# 每个NPDA都生成一个新的
DPDADesign = Struct.new(:start_state, :bottom_character,
                        :accept_states, :rulebook) do
  def accepts?(string)
    to_dpda.tap { |dpda| dpda.read_string(string) }.accepting?
  end

  def to_dpda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    DPDA.new(start_configuration, accept_states, rulebook)
  end
end

# 识别平衡括号字符串的规则手册
rulebook = DPDARulebook.new([
                              PDARule.new(1, '(', 2, '$', ['b', '$']),
                              PDARule.new(2, '(', 2, 'b', %w[b b]),
                              PDARule.new(2, ')', 2, 'b', []),
                              PDARule.new(2, nil, 1, '$', ['$'])
                            ])
#test
dpda_design = DPDADesign.new(1, '$', [1], rulebook)
dpda_design.accepts?('(((((((((())))))))))')
dpda_design.accepts?('()(())((()))(()(()))')
dpda_design.accepts?('(()(()(()()(()()))()')

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
dpda.read_string('())'); dpda.current_configuration
dpda.accepting?
dpda.stuck?
dpda_design.accepts?('())')
