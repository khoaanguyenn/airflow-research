class PointRules
  attr_reader :point_rules

  def initialize(point_rules)
    @point_rules = point_rules.fetch('rules').map { |rule| PointRule.new(rule) }
  end

  def apply(transactions)
    transactions.map do |transaction|
      @point_rules.map { |rule| rule.apply(transaction) }.sum
    end.sum
  end
end

class PointRule
  attr_reader :rule_name, :points, :type

  def initialize(point_rule)
    _rule_name, action = point_rule.flatten
    @reward_points = action.fetch('reward_points')
    @spend_amount = action.fetch('spend_amount')
    @from = @spend_amount['from']
    @to = @spend_amount['to']
  end

  def apply(transaction)
    spending_amount = transaction.transaction_amount
    if (@from..@to).cover?(spending_amount)
      @reward_points
    else
      0
    end
  end
end

class PointCalculator
  attr_reader :point_rules

  def initialize(point_rules)
    @point_rules = point_rules
  end

  def calculate(transactions)
    point_rules.apply(transactions)
  end
end
