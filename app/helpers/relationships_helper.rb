module RelationshipsHelper
   def add_create_relationship_worker_if_needed(uids, user_id:, screen_names:)
     return if request.device_type == :crawler

     values = {
       session_id:   fingerprint,
       uids:         uids,
       screen_names: screen_names,
       user_id:      user_id,
       via:          params[:via] ? params[:via] : '',
       device_type:  request.device_type,
       os:           request.os,
       browser:      request.browser,
       user_agent:   truncated_user_agent,
       referer:      truncated_referer,
       referral:     find_referral,
       channel:      find_referral,
     }
     CreateRelationshipWorker.perform_async(values)
   end
end