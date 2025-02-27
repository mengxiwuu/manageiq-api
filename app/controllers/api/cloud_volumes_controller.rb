module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = CloudVolume.class_by_ems(ext_management_system)
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      task_id = klass.create_volume_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Volume #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))

      raise BadRequestError, cloud_volume.unsupported_reason(:update) unless cloud_volume.supports?(:update)

      task_id = cloud_volume.update_volume_queue(User.current_user, data)
      action_result(true, "Updating #{cloud_volume.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def safe_delete_resource(type, id, _data = {})
      api_resource(type, id, "Deleting") do |cloud_volume|
        ensure_supports(type, cloud_volume, :safe_delete)
        {:task_id => cloud_volume.safe_delete_volume_queue(User.current_userid)}
      end
    end

    def delete_resource_main_action(_type, cloud_volume, _data)
      # TODO: ensure_supports(type, cloud_volume, :delete)
      {:task_id => cloud_volume.delete_volume_queue(User.current_userid)}
    end

    def options
      if (id = params["id"])
        render_update_resource_options(id)
      elsif (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end
  end
end
