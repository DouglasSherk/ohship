STRIPE_CONFIG = YAML.load_file Rails.root.join("config", "environments", "stripe", "#{Rails.env}.yml")
