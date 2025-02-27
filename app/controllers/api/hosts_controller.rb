module Api
  class HostsController < BaseController
    CREDENTIALS_ATTR = "credentials".freeze
    AUTH_TYPE_ATTR = "auth_type".freeze
    DEFAULT_AUTH_TYPE = "default".freeze

    include Subcollections::CustomAttributes
    include Subcollections::Lans
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id, data = {})
      credentials = data.delete(CREDENTIALS_ATTR)
      raise BadRequestError, "Cannot update non-credentials attributes of host resource" if data.any?
      resource_search(id, type, collection_class(:hosts)).tap do |host|
        all_credentials = Array.wrap(credentials).each_with_object({}) do |creds, hash|
          auth_type = creds.delete(AUTH_TYPE_ATTR) || DEFAULT_AUTH_TYPE
          creds.symbolize_keys!
          creds.reverse_merge!(:userid => host.authentication_userid(auth_type))
          hash[auth_type.to_sym] = creds
        end
        host.update_authentication(all_credentials) if all_credentials.present?
      end
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end
  end
end
