# frozen_string_literal: true

class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AfterSignInPathLeadable

  def qiita
    auth_hash = request.env['omniauth.auth']

    if current_user
      qiita_authorization = QiitaAuthorization.find_or_initialize_by(uid: auth_hash[:uid]) do |qiita_authorization|
        qiita_authorization.token = auth_hash[:credentials][:token]
        qiita_authorization.user = current_user
      end

      if qiita_authorization.save
        flash[:notice] = I18n.t('omniauth_callbacks.success')
      else
        flash[:alert] = I18n.t('omniauth_callbacks.failure')
      end
      redirect_to after_sign_in_path_for(current_user)
    else
      if authorization = QiitaAuthorization.find_by(uid: auth_hash[:uid])
        sign_in(authorization.user)
        redirect_to after_sign_in_path_for(authorization.user)
      else
        store_omniauth_data
        redirect_to new_user_oauth_registration_path
      end
    end
  end

  private

  def store_omniauth_data
    session[:devise_omniauth_auth] = request.env['omniauth.auth']
    session[:devise_omniauth_origin] = request.env['omniauth.origin']
  end

  # @override
  def location_after_sign_in
    request.env['omniauth.origin'].presence || stored_location_for(:user)
  end
end
