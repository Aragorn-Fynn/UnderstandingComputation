#设计一台机器， 用这台机器按照这种语言的语法操作反复规约， 直到求出值
#数字
class Number < Struct.new(:value)
end

#加法
class Add < Struct.new(:left, :right)
end

#乘法
class Multiply < Struct.new(:left, :right)
end

#手工构造AST
Add.new(
    Multiply.new(Number.new(1), Number.new(2)),
    Multiply.new(Number.new(3), Number.new(4))
)

#定义字符串表示
class Number
    def to_s
        value.to_s
    end

    def inspect
        "«#{self}»"
    end
end

class Add
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "«#{self}»"
    end
end

class Multiply
    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "«#{self}»"
    end    
end

#判断是否可以规约
class Number
    def reducible?
        false
    end
end


class Add
    def reducible?
        true
    end
end

class Multiply
    def reducible?
        true
    end
end

# 规约
class Add
    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end
end

class Multiply
    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible?
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end
end


#布尔值
class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "«#{self}»"
    end
    
    def reducible?
        false
    end
end

#小于表达式
class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

#变量
class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end
    
    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end
end

#环境记录了变量到值的映射， 使用环境对变量规约
class Variable
    def reduce(environment)
        environment[name]
    end
end

#实例化一个机器， 并规约各个表达式
Machine.new(
    Add.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4))
    )
).run

#语句
class DoNothing
    def to_s
        'do-nothing'
    end

    def inspect
        "«#{self}»"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end
    
    def reducible?
        false
    end
end

#赋值语句
class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end
    def inspect
        "«#{self}»"
    end
    def reducible?
        true
    end
    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)), environment]
        else
            [DoNothing.new, environment.merge({ name => expression })]
        end
    end
end

#if语句
class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end
    def inspect
        "«#{self}»"
    end
    def reducible?
        true
    end
    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end

#序列
class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end
    def inspect
        "«#{self}»"
    end
    def reducible?
        true
    end
    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end

#while循环
class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) { #{body} }"
    end
    def inspect
        "«#{self}»"
    end
    def reducible?
        true
    end
    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end

#虚拟机， 不断规约， 直到不能规约为止
class Machine < Struct.new(:statement, :environment)
    def step
        self.statement, self.environment = statement.reduce(environment)
    end

    def run
        while expression.reducible?
            puts "#{statement}, #{environment}"
            step
        end
        puts "#{statement}, #{environment}"
    end

end
