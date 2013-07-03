require 'torquebox-capistrano-support'
require 'bundler/capistrano'



# SCM
server       "192.241.133.191", :web, :app, :primary => true
set :repository,        "https://github.com/cfitz/neo4j-test-app.git"
set :branch,            "master"
set :user,              "torquebox"
set :scm,               :git
set :scm_verbose,       true
set :use_sudo,          false
#set :bundle_dir, '/opt/apps/beacon.se/shared/bundle'

# Production server
set :deploy_to,         "/opt/apps/192.241.133.191"
set :torquebox_home,    "/opt/torquebox/current"
set :jboss_init_script, "/etc/init.d/jboss-as-standalone"
set :rails_env, 'production'
set :app_context,       "/"
set :app_ruby_version, '1.9'
set :application, "dissertation.wmu.se"

default_environment['JRUBY_OPTS'] = '--1.9'
default_environment['PATH'] = '/opt/torquebox/current/jboss/bin:/opt/torquebox/current/jruby/bin:/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin:/root/bin'

before 'deploy:finalize_update', 'deploy:assets:symlink'
after 'deploy:update_code', 'deploy:assets:precompile'

after 'deploy:update', 'deploy:resymlink'

default_run_options[:pty] = true  # Must be set for the password prompt from git to work
set :deploy_via, :remote_cache


namespace :deploy do
  desc "relink db directory"
   #if you use sqlite
   task :resymlink, :roles => :app do
     run "mkdir -p #{shared_path}/db; rm -rf #{current_path}/db && ln -s #{shared_path}/db #{current_path}/db && chown -R torquebox:torquebox  #{current_path}/db"
   end
   
   
    namespace :assets do
      # If you want to force the compilation of assets, just set the ENV['COMPILE_ASSETS']
       task :precompile, :roles => :web do
         from = source.next_revision(current_revision) 
         force_compile = ENV['COMPILE_ASSETS']
         if ( force_compile) or (capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ lib/assets/ app/assets/ | wc -l").to_i > 0 )
           run_locally("rake assets:clean && rake assets:precompile")
           run_locally "cd public && tar -jcf assets.tar.bz2 assets"
           top.upload "public/assets.tar.bz2", "#{shared_path}", :via => :scp
           run "cd #{shared_path} && tar -jxf assets.tar.bz2 && rm assets.tar.bz2"
           run_locally "rm public/assets.tar.bz2"
           run_locally("rake assets:clean")
         else
          logger.info "Skipping asset precompilation because there were no asset changes"
         end
       end
       
       task :symlink, roles: :web do
         run ("rm -rf #{latest_release}/public/assets &&
               mkdir -p #{latest_release}/public &&
               mkdir -p #{shared_path}/assets &&
               ln -s #{shared_path}/assets #{latest_release}/public/assets")
       end
       
       
    end
end

 

