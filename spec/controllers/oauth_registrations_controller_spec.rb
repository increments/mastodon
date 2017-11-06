require 'rails_helper'
require 'securerandom'

RSpec.describe OauthRegistrationsController, type: :controller do
  include_context 'mock qiita omniauth'

  let(:omniauth_auth) { qiita_auth }
  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    stub_request(:get, qiita_auth[:info][:image]).to_return(request_fixture('avatar.txt'))
  end

  shared_context 'store omniauth data' do
    before do
      session[:devise_omniauth_auth] = omniauth_auth
      session[:devise_omniauth_origin] = try(:omniauth_origin)
    end
  end

  describe 'GET #new' do
    subject { -> { get :new } }

    context 'when omniauth data are stored' do
      include_context 'store omniauth data'

      it 'returns 200' do
        subject.call
        expect(response).to have_http_status(:success)
      end
    end

    context 'when omniauth data are not stored' do
      it 'redirect_to root_path' do
        subject.call
        expect(response).to be_redirect
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #create' do
    subject { -> { post :create, { params: { form_oauth_registration: form_params } } } }

    context 'when omniauth data are stored' do
      include_context 'store omniauth data'

      context 'and email and username is given' do
        let(:form_params) { { email: email, username: username } }
        let(:username) { 'foo' }
        let(:email) { 'foo@example.com' }

        it { is_expected.to change { User.find_by(account: Account.find_by(username: username), email: email) }.from(nil).to(be_truthy) }
        it { is_expected.to change { QiitaAuthorization.find_by(user: User.find_by(email: email), uid: omniauth_auth[:uid], token: omniauth_auth[:credentials][:token]) }.from(nil).to(be_truthy) }

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
    end

    context 'when omniauth data are not stored' do
      let(:form_params) { { email: email, username: username } }
      let(:username) { 'foo' }
      let(:email) { 'foo@example.com' }

      it 'redirect_to root_path' do
        subject.call
        expect(response).to be_redirect
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
