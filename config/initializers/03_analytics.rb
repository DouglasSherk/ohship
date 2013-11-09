ANALYTICS_CONFIG = YAML.load_file Rails.root.join("config", "environments", "analytics", "#{Rails.env}.yml")
Analytics = AnalyticsRuby  # alias for convenience
Analytics.init(secret: ANALYTICS_CONFIG["SEGMENT_SECRET"])
