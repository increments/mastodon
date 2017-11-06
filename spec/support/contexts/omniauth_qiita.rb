# frozen_string_literal: true

shared_context 'mock qiita omniauth' do
  let(:qiita_auth) do
    {
      provider: 'qiita',
      uid: 'test_uid',
      info: {
        email: 'test@example.com',
        name: 'test_name',
        image: 'http://example.com/image.jpg'
      },
      credentials: {
        token: 'credentialstoken',
        refresh_token: 'credentialssecret',
      },
      extra: {
        raw_info: {}
      }
    }
  end

  before { OmniAuth.config.mock_auth[:qiita] = OmniAuth::AuthHash.new(qiita_auth) }
  after { OmniAuth.config.mock_auth[:qiita] = nil }
end
