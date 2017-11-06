# frozen_string_literal: true

module AfterSignInPathLeadable
  extend ActiveSupport::Concern

  protected

  def after_sign_in_path_for(resource)
    after_sign_in_path = resolve_url(location_after_sign_in)

    if home_paths(resource).include?((after_sign_in_path || '').split('?').first)
      root_path
    else
      after_sign_in_path || root_path
    end
  end

  private

  def home_paths(resource)
    paths = [about_path]
    if single_user_mode? && resource.is_a?(User)
      paths << short_account_path(username: resource.account)
    end
    paths
  end

  def resolve_url(url)
    uri = URI.parse(url)
    if !uri.host || uri.host == request.host
      uri.query ? "#{uri.path}?#{uri.query}" : uri.path
    else
      nil
    end
  rescue URI::InvalidURIError => e
    nil
  end

  def location_after_sign_in
    fail NotImplementedError
  end
end
