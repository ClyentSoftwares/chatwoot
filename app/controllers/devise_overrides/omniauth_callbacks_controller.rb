class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper

  def omniauth_success
    Rails.logger.info "Auth hash: #{auth_hash.inspect}"
    get_resource_from_auth_hash
    @resource.present? ? sign_in_user : sign_up_user
  rescue StandardError => e
    Rails.logger.error "Authentication error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to login_page_url(error: 'authentication_failed')
  end

  def redirect_callbacks
    # derive target redirect route from 'resource_class' param, which was set
    # before authentication.
    devise_mapping = get_devise_mapping
    redirect_route = get_redirect_route(devise_mapping)

    # Remove extra and credential params from session to avoid a CookieOverflow.
    session['dta.omniauth.auth'] = request.env['omniauth.auth'].except('extra').except('credentials')
    session['dta.omniauth.params'] = request.env['omniauth.params']

    redirect_to redirect_route, { status: 307 }.merge({})
  end

  private

  def sign_in_user
    @resource.skip_confirmation! if confirmable_enabled?

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token)
  end

  def sign_up_user
    create_account_for_user

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@user.email)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @user.generate_sso_auth_token)
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { email: email, sso_auth_token: sso_auth_token }.compact
    params[:error] = error if error.present?

    "#{frontend_url}/app/login?#{params.to_query}"
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_auth_hash # rubocop:disable Naming/AccessorMethodName
    case auth_hash['provider']
    when 'openid_connect'
      @resource = resource_class.where(
        uid: auth_hash['uid']
      ).first
    else
      redirect_to login_page_url(error: 'unknown_provider')
    end
  end

  def create_account_for_user
    ActiveRecord::Base.transaction do
      first_user = User.count.zero?
      @account = first_user ? create_default_account : Account.first
      @user = create_user(auth_hash, first_user)
      associate_user_with_account(@user, @account, first_user)
      @user
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create user account: #{e.message}")
    raise
  end

  def create_default_account
    Account.create!(name: 'Default', locale: I18n.locale).tap do |account|
      Current.account = account
    end
  end

  def create_user(auth_hash, first_user)
    info = auth_hash['info']
    user = User.create!(
      provider: auth_hash['provider'],
      email: info['email'],
      name: info['name'],
      uid: auth_hash['uid'],
      type: first_user ? 'SuperAdmin' : nil
    )
    user.confirm
    user
  end

  def associate_user_with_account(user, account, first_user)
    AccountUser.create!(
      account: account,
      user: user,
      role: first_user ? AccountUser.roles['administrator'] : AccountUser.roles['agent']
    )
  end

  def default_devise_mapping
    'user'
  end
end
