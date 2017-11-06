# frozen_string_literal: true

require 'rails_helper'

describe Auth::OmniauthCallbacksController, type: :controller do
  describe 'GET #qiita' do
    include_context 'mock qiita omniauth'

    let(:omniauth_auth) { qiita_auth }
    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = omniauth_auth
      request.env['omniauth.origin'] = try(:omniauth_origin)
    end

    subject { -> { get :qiita } }

    context 'when signed in' do
      before { sign_in(user) }
      let(:user) { Fabricate(:user) }

      context 'and current user is not linked to an qiita account' do
        it 'links the user to the qiita account' do
          is_expected.to change { user.reload.qiita_authorization }.from(nil).to(be_truthy)
        end
      end

      context 'and omniauth.origin is empty' do
        it 'redirect_to root_path' do
          subject.call
          expect(response).to be_redirect
          expect(response).to redirect_to(root_path)
        end
      end

      context 'and omniauth.origin is about_url' do
        let(:omniauth_origin) { about_url }

        it 'redirect_to root_path' do
          subject.call
          expect(response).to be_redirect
          expect(response).to redirect_to(root_path)
        end
      end

      context 'and omniauth.origin is settings_qiita_authorizations_url' do
        let(:omniauth_origin) { settings_qiita_authorizations_url }

        it 'redirect_to settings_qiita_authorizations_path' do
          subject.call
          expect(response).to be_redirect
          expect(response).to redirect_to(settings_qiita_authorizations_path)
        end
      end
    end

    context 'when not signed in' do
      context 'and there are a user linked to the qiita account' do
        let(:user) { Fabricate(:user) }
        let!(:qiita_authorization) { Fabricate(:qiita_authorization, uid: omniauth_auth[:uid], user: user) }

        it 'logs the user in' do
          subject.call
          expect(controller.current_user).to eq user
        end

        context 'and omniauth.origin is empty' do
          it 'redirect_to root_path' do
            subject.call
            expect(response).to be_redirect
            expect(response).to redirect_to(root_path)
          end
        end

        context 'and omniauth.origin is about_url' do
          let(:omniauth_origin) { about_url }

          it 'redirect_to root_path' do
            subject.call
            expect(response).to be_redirect
            expect(response).to redirect_to(root_path)
          end
        end

        context 'and omniauth.origin is settings_qiita_authorizations_url' do
          let(:omniauth_origin) { settings_qiita_authorizations_url }

          it 'redirect_to settings_qiita_authorizations_path' do
            subject.call
            expect(response).to be_redirect
            expect(response).to redirect_to(settings_qiita_authorizations_path)
          end
        end
      end

      context 'and there are no user linked to the qiita account' do
        it 'redirects to new_user_oauth_registration_path' do
          subject.call
          expect(response).to redirect_to(new_user_oauth_registration_path)
        end

        context 'when omniauth.origin is a url' do
          let(:omniauth_origin) { root_url }

          it 'stores the omniauth origin to session' do
            subject.call
            expect(session[:devise_omniauth_origin]).to be(omniauth_origin)
          end
        end

        it 'stores the omniauth data to session to build form' do
          subject.call
          expect(Form::OauthRegistration.from_omniauth_auth(session[:devise_omniauth_auth])).to have_attributes({
            provider: omniauth_auth[:provider],
            avatar: omniauth_auth[:info][:image],
            uid: omniauth_auth[:uid],
            username: omniauth_auth[:uid],
            token: omniauth_auth[:credentials][:token],
          })
        end
      end
    end
  end
end
