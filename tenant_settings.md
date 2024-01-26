# Settings that are Configurable Per Tenant 
(applicable only for use with the Rooms application)

To add a settings for a specific tenant, use the following rake task: `rake db:tenants:settings:upsert[<tenant uid>, <setting key>, <setting value>]`

| Setting Key |	Description |
| ----------  | ----------  |
| bigbluebutton_url | The URL of the BBB server to be used |
| bigbluebutton_secret | The secret for the BBB server to be used |
| handler_params | The launch parameters to use for creating the room ID. To add more than one parameter, use the following syntax: "param1\\,param2". For example: "context_id\\,resource_link_id" |
| enable_shared_rooms | Whether or not to enable the shared rooms feature. The default is false. |


