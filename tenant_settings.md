# Settings that are Configurable Per Tenant
(applicable only for use with the Rooms application)

To add a settings for a specific tenant, use the following rake task: `rake db:tenants:settings:upsert[<tenant uid>, <setting key>, <setting value>]`

| Setting Key |	Description | Defaults  |
| ----------  | ----------  | ----------  |
| bigbluebutton_url | The URL of the BBB server to be used | |
| bigbluebutton_secret | The secret for the BBB server to be used | |
| handler_params | The launch parameters to use for creating the room ID. To add more than one parameter, use the following syntax: "param1\\,param2". For example: "context_id\\,resource_link_id" | The default value is 'resource_link_id'. |
| enable_shared_rooms | Whether or not to enable the shared rooms feature. | The default is false. |
| hide_build_tag | Whether or not to hide the build tag. | The default is false. |
| bigbluebutton_moderator_roles | This changes the roles that will be considered moderators in the Rooms app and in Big Blue Button. To change more than one moderator role, use the following syntax: "moderator1\\,moderator2". For example: "Learner\\,Teacher". | The default moderator roles include the "Instructor","Faculty","Teacher","Mentor","Administrator", and "Admin". |
| room_setting_defaults | This sets the room's default settings in the rooms app. To change more than one room setting, use the following syntax: "{setting1:0\\,setting2:1}". In this case, 0 means false and 1 means true. For example: "{lockSettingsDisablePublicChat:1\\,lockSettingsDisableNote:0}". | The default room settings are lockSettingsDisableCam:0, lockSettingsDisableMic:0, lockSettingsDisablePrivateChat:0, lockSettingsDisablePublicChat:0, lockSettingsDisableNote:0, autoStartRecording:0, allowStartStopRecording:1, waitForModerator:1, allModerators:0, record:1. |