# config/deploy.rb 
require "bundler/capistrano"
set :application, "Wepoll"

default_run_options[:pty] = true 
#$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
#require "rvm/capistrano"                  # Load RVM's capistrano plugin.
#set :rvm_ruby_string, '1.9.3@rails_3_2'        # Or whatever env you want it to run in.
#set :rvm_type, :user  # Copy the exact line. I really mean :user here

set :scm,             :git
set :repository,      "git@github.com:wafflestudio/wepoll.git"
set :branch,          "master"
set :migrate_target,  :current
set :ssh_options,     { :forward_agent => true, :username => "ubuntu", :keys => "#{ENV['HOME']}/.ssh/wepoll.pem" }
set :rails_env,       "production"
set :deploy_to,       "/home/ubuntu/wepoll"
set :normalize_asset_timestamps, false
set :scm_passphrase, 'wepoll'
set :deploy_via, :remote_cache
set (:shared_path) { fetch(:deploy_to) + "/shared/rails_app/"}


#  * executing "mkdir -p /home/ubuntu/wepoll /home/ubuntu/wepoll/shared /home/ubuntu/wepoll/shared/public/system /home/ubuntu/wepoll/shared/log /home/ubuntu/wepoll/shared/tmp/pids &&  chmod g+w /home/ubuntu/wepoll /home/ubuntu/wepoll/shared /home/ubuntu/wepoll/shared/public/system /home/ubuntu/wepoll/shared/log /home/ubuntu/wepoll/shared/tmp/pids"

set :user,            "ubuntu"
set :group,           "admin"
set :use_sudo,        false

role :web,    "ec2-122-248-219-209.ap-southeast-1.compute.amazonaws.com"
#role :app,    "ec2-122-248-219-209.ap-southeast-1.compute.amazonaws.com"
#role :db,     "ec2-122-248-219-209.ap-southeast-1.compute.amazonaws.com", :primary => true

set(:latest_release)  { fetch(:current_path) + "/rails_app" }
set(:release_path)    { fetch(:current_path) + "/rails_app" }
set(:current_release) { fetch(:current_path) + "/rails_app" }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

## Use our ruby-1.9.3-p125@rails_3_2 gemset
set :default_environment, {
  'PATH' => "/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@rails_3_2/bin:/home/ubuntu/.rvm/bin:$PATH",
  'RUBY_VERSION' => 'ruby-1.9.3-p125',
  'GEM_HOME'     => '/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@rails_3_2',
  'GEM_PATH'     => '/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@rails_3_2:/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@global',
  'BUNDLE_PATH'  => '/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@rails_3_2',  # If you are using bundler.
  'RAILS_ENV' => 'production'
}

default_run_options[:shell] = 'bash'

namespace :assets do
  task :compile, :roles => :web, :except => { :no_release => true } do
    run "cd #{current_path}/rails_app; rm -rf public/assets/*"
    run "cd #{current_path}/rails_app; bundle exec rake assets:precompile RAILS_ENV=production"
  end
end
before "deploy:restart", "assets:compile"

namespace :deploy do
  desc "Deploy your application"
  task :default do
    update
    restart
  end

  desc "Setup your git-based deployment app"
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
  end

  task :cold do
    update
    migrate
  end

  task :update do
    transaction do
      update_code
    end
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end

  desc "Update the database (overwritten to avoid symlink)"
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids &&
      mkdir -p #{latest_release}/public &&
      mkdir -p #{latest_release}/tmp &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -s #{shared_path}/system #{latest_release}/public/system &&
      ln -s #{shared_path}/pids #{latest_release}/tmp/pids &&
      ln -sf #{shared_path}/database.yml #{latest_release}/config/database.yml
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = fetch(:public_children, %w(images stylesheets javascripts)).map { |p| "#{latest_release}/public/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat /tmp/unicorn.wepoll.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path}/rails_app ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat /tmp/unicorn.wepoll.pid`"
  end  

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end

    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}/rails_app; #{rake} #{cmd}"
end

