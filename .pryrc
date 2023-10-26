if Rails.env.development? || Rails.env.test?
  # This introduces the `table` statement
  extend Hirb::Console

end

AwesomePrint.defaults = { limit: 10 }
