Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil), {
    provider_ignores_state: true
  }

  provider :openid_connect, {
    name: :openid_connect,
    scope: ENV.fetch('OIDC_SCOPES', nil).split,
    response_type: :code,
    uid_field: ENV.fetch('OIDC_UID_FIELD', 'sub'),
    discovery: true,
    issuer: ENV.fetch('OIDC_ISSUER', nil),
    client_options: {
      identifier: ENV.fetch('OIDC_CLIENT_ID', nil),
      secret: ENV.fetch('OIDC_CLIENT_SECRET', nil),
      redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/openid_connect/callback"
    }
  }
end
