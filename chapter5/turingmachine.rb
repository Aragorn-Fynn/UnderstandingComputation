# 确定性图灵机 = NFA + 纸带

# 纸带
Tape = Struct.new(:left, :middle, :right, :blank) do
  def inspect
    "#<Tape #{left.join}(#{middle})#{right.join}>"
  end

  # 向纸带当前位置写入一个字符
  def write(character)
    Tape.new(left, character, right, blank)
  end

  # 纸带左移
  def move_head_left
    Tape.new(left[0..-2], left.last || blank, [middle] + right, blank)
  end

  # 纸带右移
  def move_head_right
    Tape.new(left + [middle], right.first || blank, right.drop(1), blank)
  end
end

# 配置
TMConfiguration = Struct.new(:state, :tape)

# 规则
TMRule = Struct.new(:state, :character, :next_state, :write_character, :direction) do
  # 判断当前规则是否匹配
  def applies_to?(configuration)
    state == configuration.state && character == configuration.tape.middle
  end

  # 计算接下来的配置
  def follow(configuration)
    TMConfiguration.new(next_state, next_tape(configuration))
  end

  # 计算下个纸带
  def next_tape(configuration)
    written_tape = configuration.tape.write(write_character)
    case direction
    when :left
      written_tape.move_head_left
    when :right
      written_tape.move_head_right
    end
  end
end

# 规则手册
DTMRulebook = Struct.new(:rules) do
  def applies_to?(configuration)
    !rule_for(configuration).nil?
  end

  # 计算下个配置
  def next_configuration(configuration)
    rule_for(configuration).follow(configuration)
  end

  # 找到匹配的规则
  def rule_for(configuration)
    rules.detect { |rule| rule.applies_to?(configuration) }
  end
end

DTM = Struct.new(:current_configuration, :accept_states, :rulebook) do
  # 判断当前状态是否可以被接受
  def accepting?
    accept_states.include?(current_configuration.state)
  end

  # 判断当前状态是否是阻塞状态
  def stuck?
    !accepting? && !rulebook.applies_to?(current_configuration)
  end

  # 转移到下个配置
  def step
    self.current_configuration = rulebook.next_configuration(current_configuration)
  end

  # 运行图灵机
  def run
    step until accepting? || stuck?
  end
end

# test
# 递增二进制数
rulebook = DTMRulebook.new([
                             TMRule.new(1, '0', 2, '1', :right),
                             TMRule.new(1, '1', 1, '0', :left),
                             TMRule.new(1, '_', 2, '1', :right),
                             TMRule.new(2, '0', 2, '0', :right),
                             TMRule.new(2, '1', 2, '1', :right),
                             TMRule.new(2, '_', 3, '_', :left)
                           ])
tape = Tape.new(%w[1 0 1], '1', [], '_')
dtm = DTM.new(TMConfiguration.new(1, tape), [3], rulebook)
dtm.run
dtm.current_configuration

# 识别包含同样数量a, b, c字符的字符串
rulebook = DTMRulebook.new([
                             # 向右扫描， 查找a
                             TMRule.new(1, 'X', 1, 'X', :right), # 跳过 X
                             TMRule.new(1, 'a', 2, 'X', :right), # 删除a, 进入 2
                             TMRule.new(1, '_', 6, '_', :left), # 查找空格， 进入状态6(接受)
                             # 状态2： 向右扫描， 查找b
                             TMRule.new(2, 'a', 2, 'a', :right), # 跳过 a
                             TMRule.new(2, 'X', 2, 'X', :right), # 跳过 X
                             TMRule.new(2, 'b', 3, 'X', :right), # 删除b, 进入状态 3
                             # 状态3： 向右扫描， 查找c
                             TMRule.new(3, 'b', 3, 'b', :right), # 跳过 b
                             TMRule.new(3, 'X', 3, 'X', :right), # 跳过 X
                             TMRule.new(3, 'c', 4, 'X', :right), # 删除c，进入状态 4
                             # 状态4：向右扫描，ֱ查找字符串结束标记
                             TMRule.new(4, 'c', 4, 'c', :right), # 跳过 c
                             TMRule.new(4, '_', 5, '_', :left), # ֱ查找空格，进入状态 5
                             # 状态5：向左扫描，ֱ查找字符串开始标记
                             TMRule.new(5, 'a', 5, 'a', :left), # 跳过 a
                             TMRule.new(5, 'b', 5, 'b', :left), # 跳过 b
                             TMRule.new(5, 'c', 5, 'c', :left), # 跳过 c
                             TMRule.new(5, 'X', 5, 'X', :left), # 跳过 X
                             TMRule.new(5, '_', 1, '_', :right) # 查找空格， 进入状态1
                           ])

tape = Tape.new([], 'a', %w[a a b b b c c c], '_')
dtm = DTM.new(TMConfiguration.new(1, tape), [6], rulebook)
dtm.run; dtm.current_configuration
