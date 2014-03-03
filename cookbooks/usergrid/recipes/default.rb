#
# Cookbook Name:: usergrid
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#
service "cassandra" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
service "tomcat" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
git "/opt/usergrid" do
	user "root"
  repository "https://github.com/usergrid/usergrid.git"
  reference "master"
  action :export
  depth 1
  notifies :run, 'bash[install_sdk]', :immediately
end
http_request "database_setup" do
	action :nothing
  url "http://localhost:8080/system/database/setup"
  headers({"Authorization" => "Basic #{Base64.encode64("superuser:test")}"})
  retries 3
  retry_delay 5
end
http_request "superuser_setup" do
	action :nothing
  url "http://localhost:8080/system/superuser/setup"
  headers({"Authorization" => "Basic #{Base64.encode64("superuser:test")}"})
  retries 3
  retry_delay 5
end
bash "install_sdk" do
  user "root"
  cwd "/opt/usergrid/sdks/java"
  code <<-EOH
  mvn clean install -DskipTests
  EOH
  notifies :run, 'bash[build_stack]', :immediately
end
bash "build_stack" do
  user "root"
  cwd "/opt/usergrid/stack"
  code <<-EOH
  mvn clean package -DskipTests
  EOH
  ignore_failure true
  notifies :run, 'bash[deploy_war]', :immediately
end

# bash "remove_default_root" do
#   user "root"
#   cwd "/var/lib/tomcat6/webapps"
#   code <<-EOH
#   rm -rf ./ROOT
#   EOH
#   not_if { ::File.exists?("/var/lib/tomcat6/webapps/ROOT.war") }
# end

bash "deploy_war" do
  user "root"
  cwd "/opt/usergrid/stack/rest/target/"
  code <<-EOH
  rm -rf /var/lib/tomcat6/webapps/ROOT
  cp ROOT.war /var/lib/tomcat6/webapps/
  EOH
  #creates "/var/lib/tomcat6/webapps/ROOT.war"
  notifies :create, 'cookbook_file[usergrid-custom.properties]', :immediately
end
# bash "deploy_properties_file" do
#   user "root"
#   cwd "/vagrant/"
#   code <<-EOH
#   cp usergrid-custom.properties /var/lib/tomcat6/webapps/ROOT/WEB-INF/classes
#   EOH
#   retries 3
#   retry_delay 5
# end
cookbook_file "usergrid-custom.properties" do
	user "root"
	group "tomcat6"
  path "/var/lib/tomcat6/webapps/ROOT/WEB-INF/classes/usergrid-custom.properties"
  action :nothing
  #creates "/var/lib/tomcat6/webapps/ROOT/WEB-INF/classes/usergrid-custom.properties"
  retries 3
  retry_delay 5
  notifies :get, 'http_request[database_setup]', :delayed
  notifies :get, 'http_request[superuser_setup]', :delayed
end
