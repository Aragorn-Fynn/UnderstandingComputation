# 词法分析器
class LexicalAnalyzer < Struct.new(:string)
  GRAMMAR = [
    { token: 'i', pattern: /if/ }, # if 关键字
    { token: 'e', pattern: /else/ }, # else 关键字
    { token: 'w', pattern: /while/ }, # while 关键字
    { token: 'd', pattern: /do-nothing/ }, # do-nothing 关键字
    { token: '(', pattern: /\(/ }, # 左小括号
    { token: ')', pattern: /\)/ }, # 右小括号
    { token: '{', pattern: /\{/ }, # 左大括号
    { token: '}', pattern: /\}/ }, # 右大括号
    { token: ';', pattern: /;/ }, # 分号
    { token: '=', pattern: /=/ }, # 等号
    { token: '+', pattern: /\+/ }, # 加号
    { token: '*', pattern: /\*/ }, # 乘号
    { token: '<', pattern: /</ }, #  小于号
    { token: 'n', pattern: /[0-9]+/ }, # 数字
    { token: 'b', pattern: /true|false/ }, # 布尔值
    { token: 'v', pattern: /[a-z]+/ } # 变量名
  ]

  def analyze
    [].tap do |tokens|
      tokens.push(next_token) while more_tokens?
    end
  end

  def more_tokens?
    !string.empty?
  end

  def next_token
    rule, match = rule_matching(string)
    self.string = string_after(match)
    rule[:token]
  end

  def rule_matching(string)
    matches = GRAMMAR.map { |rule| match_at_beginning(rule[:pattern], string) }
    rules_with_matches = GRAMMAR.zip(matches).reject { |_rule, match| match.nil? }
    rule_with_longest_match(rules_with_matches)
  end

  def match_at_beginning(pattern, string)
    /\A#{pattern}/.match(string)
  end

  def rule_with_longest_match(rules_with_matches)
    rules_with_matches.max_by { |_rule, match| match.to_s.length }
  end

  def string_after(match)
    match.post_match.lstrip
  end
end

LexicalAnalyzer.new('y = x * 7').analyze
LexicalAnalyzer.new('while (x < 5) { x = x * 3 }').analyze
LexicalAnalyzer.new('if (x < 10) { y = true; x = 0 } else { do-nothing }').analyze

# 把CFG 转换为 PDA

#<语句>		     ::= <while> | <赋值>
#<while>		   ::= 'w' '(' <表达式> ')' '{' < 语句 > '}'
#<赋值>		      ::= 'v' '=' < 表达式 >
#<表达式>	      ::= < 小于表达式 >
#< 小于表达式 > ::= <乘> '<' < 小于表达式 > | <乘> 
#<乘>			      ::= < 名词 > '*' <乘> | <名词>
#<名词>		      ::= 'n' | 'v'

#开始， 我们把S推入栈中， 因为我们要识别语句。
start_rule = PDARule.new(1, nil, 2, '$', ['S', '$'])
# 把一个符号扩展成其他符号和单词组成的序列
symbol_rules = [
  # <statement> ::= <while> | <assign>
  PDARule.new(2, nil, 2, 'S', ['W']),
  PDARule.new(2, nil, 2, 'S', ['A']),
  # <while> ::= 'w' '(' <expression> ')' '{' <statement> '}'
  PDARule.new(2, nil, 2, 'W', ['w', '(', 'E', ')', '{', 'S', '}']),
  # <assign> ::= 'v' '=' <expression>
  PDARule.new(2, nil, 2, 'A', ['v', '=', 'E']),
  # <expression> ::= <less-than>
  PDARule.new(2, nil, 2, 'E', ['L']),
  # <less-than> ::= <multiply> '<' <less-than> | <multiply>
  PDARule.new(2, nil, 2, 'L', ['M', '<', 'L']),
  PDARule.new(2, nil, 2, 'L', ['M']),
  # <multiply> ::= <term> '*' <multiply> | <term>
  PDARule.new(2, nil, 2, 'M', ['T', '*', 'M']),
  PDARule.new(2, nil, 2, 'M', ['T']),
  # <term> ::= 'n' | 'v'
  PDARule.new(2, nil, 2, 'T', ['n']),
  PDARule.new(2, nil, 2, 'T', ['v'])
]

# 给每个单词一个PDA规则
token_rules = LexicalAnalyzer::GRAMMAR.map do |rule|
  PDARule.new(2, rule[:token], 2, rule[:token], [])
end

#栈为空时， 机器进入接受状态
stop_rule = PDARule.new(2, nil, 3, '$', ['$'])

rulebook = NPDARulebook.new([start_rule, stop_rule] + symbol_rules + token_rules)
npda_design = NPDADesign.new(1, '$', [3], rulebook)
token_string = LexicalAnalyzer.new('while (x < 5) { x = x * 3 }').analyze.join
npda_design.accepts?(token_string)
npda_design.accepts?(LexicalAnalyzer.new('while (x < 5 x = x * }').analyze.join)
