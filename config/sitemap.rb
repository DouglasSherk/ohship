# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://ohship.me"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  add details_path, :priority => 0.9
  add new_user_registration_path, :priority => 0.7
  add concierge_path, :priority => 0.5
  add estimate_path, :priority => 0.4
  add contact_path, :priority => 0.3
  add prohibited_path, :priority => 0.2
  add terms_path, :priority => 0.1
  add refer_path
  add new_user_session_path
end
