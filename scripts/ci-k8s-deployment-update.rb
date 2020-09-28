require 'json'

kubernetes_image=ARGV[0]

# get json string
s = File.read('./deployment.json')

# parse and convert JSON to Ruby
obj = JSON.parse(s)

# update container image
obj['spec']['template']['spec']['containers'].first['image'] = kubernetes_image
# update container DEPLOYMENT_TIMESTAMP env
obj['spec']['template']['spec']['containers'].first['env'].each do |kv|
  kv['value'] = Time.now.to_i if kv['name'] == 'DEPLOYMENT_TIMESTAMP'
end

# put json string
File.write('./deployment.json', obj.to_json)
