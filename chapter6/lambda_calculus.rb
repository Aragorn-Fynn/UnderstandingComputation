# 使用lambda演算， 解决FizzBuzz问题

# 正整数--邱奇数
ZERO = ->(_p) { ->(x) { x } }
ONE = ->(p) { ->(x) { p[x] } }
TWO = ->(p) { ->(x) { p[p[x]] } }
THREE = ->(p) { ->(x) { p[p[p[x]]] } }
FIVE = ->(p) { ->(x) { p[p[p[p[p[x]]]]] } }
FIFTEEN = ->(p) { ->(x) { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]] } }
HUNDRED = lambda { |p|
  lambda { |x|
    p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
  }
}

# test
def to_integer(proc)
  proc[->(n) { n + 1 }][0]
end
to_integer(ZERO)
to_integer(THREE)

# 布尔值
TRUE = ->(x) { ->(_y) { x } }
FALSE = ->(_x) { ->(y) { y } }

# test
def to_boolean(proc)
  proc[true][false]
end
to_boolean(TRUE)
to_boolean(FALSE)

# if语句
IF = lambda { |b|
    lambda { |x|
      b[x]
    }
  }

# 谓词
IS_ZERO = ->(n) { n[->(_x) { FALSE }][TRUE] }

# 有序对
PAIR = ->(x) { ->(y) { ->(f) { f[x][y] } } }
LEFT = ->(p) { p[->(x) { ->(_y) { x } }] }
RIGHT = ->(p) { p[->(_x) { ->(y) { y } }] }

# 递增
INCREMENT = ->(n) { ->(p) { ->(x) { p[n[p][x]] } } }

# 递减
SLIDE = ->(p) { PAIR[RIGHT[p]][INCREMENT[RIGHT[p]]] }
DECREMENT = ->(n) { LEFT[n[SLIDE][PAIR[ZERO][ZERO]]] }

# 加减乘幂
ADD = ->(m) { ->(n) { n[INCREMENT][m] } }
SUBTRACT = ->(m) { ->(n) { n[DECREMENT][m] } }
MULTIPLY = ->(m) { ->(n) { n[ADD[m]][ZERO] } }
POWER = ->(m) { ->(n) { n[MULTIPLY[m]][ONE] } }
IS_LESS_OR_EQUAL =
  lambda { |m|
    lambda { |n|
      IS_ZERO[SUBTRACT[m][n]]
    }
  }

DIV =
  Z[lambda { |f|
      lambda { |m|
        lambda { |n|
          IF[IS_LESS_OR_EQUAL[n][m]][
          lambda { |x|
            INCREMENT[f[SUBTRACT[m][n]][n]][x]
          }
          ][
          ZERO
          ]
        }
      }
    } ]

# Y组合子
Y = ->(f) { ->(x) { f[x[x]] }[->(x) { f[x[x]] }] }
# Z组合子
Z = ->(f) { ->(x) { f[->(y) { x[x][y] }] }[->(x) { f[->(y) { x[x][y] }] }] }

# 取余
MOD =
  Z[lambda { |f|
      lambda { |m|
        lambda { |n|
          IF[IS_LESS_OR_EQUAL[n][m]][
          lambda { |x|
            f[SUBTRACT[m][n]][n][x]
          }
          ][
          m
          ]
        }
      }
    } ]

# 列表
EMPTY = PAIR[TRUE][TRUE]
UNSHIFT = lambda { |l|
  lambda { |x|
    PAIR[FALSE][PAIR[x][l]]
  }
}

FOLD =
  Z[lambda { |f|
    lambda { |l|
      lambda { |x|
        lambda { |g|
          IF[IS_EMPTY[l]][
          x
          ][
          lambda { |y|
            g[f[REST[l]][x][g]][FIRST[l]][y]
          }
          ]
        }
      }
    }
  }]

PUSH =
  lambda { |l|
    lambda { |x|
      FOLD[l][UNSHIFT[EMPTY][x]][UNSHIFT]
    }
  }

IS_EMPTY = LEFT
FIRST = ->(l) { LEFT[RIGHT[l]] }
REST = ->(l) { RIGHT[RIGHT[l]] }
#test
def to_array(proc)
  array = []
  until to_boolean(IS_EMPTY[proc])
    array.push(FIRST[proc])
    proc = REST[proc]
  end
  array
end

# 范围 1..100
RANGE =
  Z[lambda { |f|
    lambda { |m|
      lambda { |n|
        IF[IS_LESS_OR_EQUAL[m][n]][
        lambda { |x|
          UNSHIFT[f[INCREMENT[m]][n]][m][x]
        }
        ][
        EMPTY
        ]
      }
    }
  }]

# map
FOLD =
  Z[lambda { |f|
    lambda { |l|
      lambda { |x|
        lambda { |g|
          IF[IS_EMPTY[l]][
          x
          ][
          lambda { |y|
            g[f[REST[l]][x][g]][FIRST[l]][y]
          }
          ]
        }
      }
    }
  }]

MAP =
  lambda { |k|
    lambda { |f|
      FOLD[k][EMPTY][
      ->(l) { ->(x) { UNSHIFT[l][f[x]] } }
      ]
    }
  }

# 字符串
TEN = MULTIPLY[TWO][FIVE]
B = TEN
F = INCREMENT[B]
I = INCREMENT[F]
U = INCREMENT[I]
ZED = INCREMENT[U]
FIZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][I]][F]
BUZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][U]][B]
FIZZBUZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[BUZZ][ZED]][ZED]][I]][F]

# test
def to_char(c)
  '0123456789BFiuz'.slice(to_integer(c))
end

def to_string(s)
  to_array(s).map { |c| to_char(c) }.join
end

TO_DIGITS =
  Z[lambda { |f|
      lambda { |n|
        PUSH[
    IF[IS_LESS_OR_EQUAL[n][DECREMENT[TEN]]][
    EMPTY
    ][
    lambda { |x|
      f[DIV[n][TEN]][x]
    }
    ]
    ][MOD[n][TEN]]
      }
    } ]

# 解决方案
solution =
  MAP[RANGE[ONE][HUNDRED]][lambda { |n|
    IF[IS_ZERO[MOD[n][FIFTEEN]]][
    FIZZBUZZ
    ][IF[IS_ZERO[MOD[n][THREE]]][
    FIZZ
    ][IF[IS_ZERO[MOD[n][FIVE]]][
    BUZZ
    ][
    TO_DIGITS[n]
    ]]]
  }]

to_array(solution).each do |p|
  puts to_string(p)
end; nil
