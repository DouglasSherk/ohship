module DeviseHelper
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def resource_class
    User
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  # XXX: HACKHACKHACK! We have no idea why this is needed or happening.
  def devise_error_messages!
    html = ""

    return html if resource.errors.empty?

    errors_number = 0 

    html << "<ul class=\"#{resource_name}_errors_list\">"

    saved_key = ""
    resource.errors.each do |key, value|
      if key != saved_key
        html << "<li class=\"#{key} error\"> #{key.capitalize} #{value} </li>"
        errors_number += 1
      end
      saved_key = key
    end

    unsolved_errors = pluralize(errors_number, "unresolved error")
    html = "<h2 class=\"#{resource_name}_errors_title\"> You have #{unsolved_errors} </h2>" + html
    html << "</ul>"

    return html.html_safe
  end
end
