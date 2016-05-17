class IntApi::MarketplacesController < ApplicationController

  skip_filter :fetch_community, :check_http_auth

  before_filter :set_access_control_headers

  NewMarketplaceForm = Form::NewMarketplace

  # Creates a marketplace and an admin user for that marketplace
  def create
    form = NewMarketplaceForm.new(params)
    return render status: 400, json: form.errors unless form.valid?

    # As there's no community yet, we store the global service name to thread
    # so that mail confirmation email is sent from global service name instead
    # of the just created marketplace's name
    ApplicationHelper.store_community_service_name_to_thread(APP_CONFIG.global_service_name)

    marketplace = MarketplaceService::API::Marketplaces.create(
      params.slice(:marketplace_name,
                   :marketplace_type,
                   :marketplace_country,
                   :marketplace_language)
            .merge(payment_process: :preauthorize)
    )

    # Create initial trial plan
    plan = {
      expires_at: Time.now.change({ hour: 9, min: 0, sec: 0 }) + 31.days
    }
    PlanService::API::Api.plans.create_initial_trial(community_id: marketplace[:id], plan: plan)

    if marketplace
      TransactionService::API::Api.settings.provision(
        community_id: marketplace[:id],
        payment_gateway: :paypal,
        payment_process: :preauthorize,
        active: true)
    end

    user = UserService::API::Users.create_user({
        given_name: params[:admin_first_name],
        family_name: params[:admin_last_name],
        email: params[:admin_email],
        password: params[:admin_password],
        locale: params[:marketplace_language]},
        marketplace[:id]).data

    auth_token = UserService::API::AuthTokens.create_login_token(user[:id])
    url = URLUtils.append_query_param(marketplace[:url], "auth", auth_token[:token])

    assign_onboarding_feature_flag(community_id: marketplace[:id])

    # TODO handle error cases with proper response

    render status: 201, json: {"marketplace_url" => url, "marketplace_id" => marketplace[:id]}
  end

  def create_prospect_email
    email = params[:email]
    render json: [ "Email missing from payload" ], :status => 400 and return if email.blank?

    ProspectEmail.create(:email => email)

    head 200, content_type: "application/json"
  end
  
  def login
    person = Person.find_by_email(params[:email])
    sign_in(person)
    redirect_to root_path
  end

  def signup
    @current_community = Community.first
    # Make person a member of the current community
    @person, email = new_person(params, @current_community)
    
    membership = CommunityMembership.new(:person => @person, :community => @current_community, :consent => @current_community.consent)
    membership.status = "pending_email_confirmation"
    membership.save!
    session[:invitation_code] = nil

    session[:person_id] = @person.id

    # If invite was used, reduce usages left
    # invitation.use_once! if invitation.present?

    Delayed::Job.enqueue(CommunityJoinedJob.new(@person.id, @current_community.id)) if @current_community

    render  json: ["Successful"], status:  200 

  end

  private

  def build_devise_resource_from_person(person_params)
    person_params.delete(:terms) #remove terms part which confuses Devise

    # This part is copied from Devise's regstration_controller#create
    # build_resource(person_params)
    # resource
  end

  def set_access_control_headers
    # TODO change this to more strict setting when done testing
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def assign_onboarding_feature_flag(community_id:)
    if(rand < 0.5)
      FeatureFlagService::API::Api.features.enable(community_id: community_id, features: [:onboarding_redesign_v1])
    end
  end

    # Create a new person by params and current community
    def new_person(params, current_community)
      person = Person.create
      person.locale =  params[:locale] || APP_CONFIG.default_locale
      person.test_group_number = 1 + rand(4)
      person.community_id = 1
      person.email = params[:person][:email]
      person.password = params[:person][:password]
      person.password2 = params[:person][:password]
      person.username = params[:person][:username]

      email = Email.new(:person => person, :address => params[:person][:email].downcase, :send_notifications => true, community_id: current_community.id)
      # params["person"].delete(:email)
      # params["person"].delete(:first_name)
      # params["person"].delete(:last_name)
      # params["person"][:password2] = params[:person][:password]

      # person = build_devise_resource_from_person(params[:person])
      # person.create(params[:person])
      person.emails << email

      person.inherit_settings_from(current_community)

      if person.save!(validate: false)
        sign_in(person)
      end

      person.set_default_preferences
      [person, email]
    end
end
