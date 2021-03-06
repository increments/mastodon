# frozen_string_literal: true

class Form::AdminSettings
  include ActiveModel::Model

  delegate(
    :site_contact_username,
    :site_contact_username=,
    :site_contact_email,
    :site_contact_email=,
    :site_title,
    :site_title=,
    :site_description,
    :site_description=,
    :site_extended_description,
    :site_extended_description=,
    :site_terms,
    :site_terms=,
    :open_registrations,
    :open_registrations=,
    :closed_registrations_message,
    :closed_registrations_message=,
    :open_deletion,
    :open_deletion=,
    :timeline_preview,
    :timeline_preview=,
    :show_staff_badge,
    :show_staff_badge=,
    :bootstrap_timeline_accounts,
    :bootstrap_timeline_accounts=,
    :min_invite_role,
    :min_invite_role=,
    :prohibit_registrations_except_qiita_oauth,
    :prohibit_registrations_except_qiita_oauth=,
    :activity_api_enabled,
    :activity_api_enabled=,
    :peers_api_enabled,
    :peers_api_enabled=,
    :show_known_fediverse_at_about_page,
    :show_known_fediverse_at_about_page=,
    to: Setting
  )
end
