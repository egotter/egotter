sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git tmux dstat monit tree dstat mysql-server mysql-devel ruby22-devel
sudo update-alternatives --set ruby /usr/bin/ruby2.2

gem install --no-ri --no-rdoc bundler
git clone https://github.com/ts-3156/egotter.git
cd egotter
bundle install --path .bundle

sudo rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum --enablerepo=remi,epel install -y redis
# cp /etc/redis.conf /etc/redis.conf.bak
# cp ./setup/etc/redis.conf /etc/redis.conf
sudo chkconfig redis on
sudo service redis start

# sudo chkconfig mysqld on
# sudo service mysqld start

# monit monitor all
# cp ./setup/etc/init.d/sidekiq /etc/init.d/sidekiq

# cp /etc/monit.conf /etc/monit.conf.bak
# cp ./setup/etc/monit.conf /etc/monit.conf
# cp ./setup/etc/monit.d/sidekiq /etc/monit.d/sidekiq
sudo service monit start
sudo chkconfig monit on

bundle exec rake db:create db:migrate
bundle exec rails s --binding=0.0.0.0

# https://gist.githubusercontent.com/ts-3156/5373957/raw/e179785a48f88e120285be6978f0ea578d308628/.bashrc
# bot.json, cluster_bad_words.json, cluster_good_words.json, .env

# 0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58 * * * * /bin/bash -l -c 'cd /home/ec2-user/egotter && RAILS_ENV=development bundle exec rake update_job_dispatcher:run --silent >> /home/ec2-user/egotter/log/crontab.log 2>&1'

# https://app.datadoghq.com/account/settings#agent/aws
# cp ./setup/etc/rsyslog.d/sidekiq /etc/rsyslog.d/sidekiq

# https://papertrailapp.com/systems/setup
