desc "Setup application"
task :bootstrap => [:environment, "setup:reset",
                    "setup:create_admin",
                    "setup:default_group",
                    "setup:create_widgets"] do
end

desc "Upgrade"
task :upgrade => [:environment] do
end

namespace :setup do
  desc "Reset databases"
  task :reset => [:environment] do
    MongoMapper.connection.drop_database(MongoMapper.database.name)
  end

  desc "Reset admin password"
  task :reset_password => :environment do
    admin = User.find_by_login("admin")
    admin.crypted_password = nil
    admin.password = "admins"
    admin.password_confirmation = "admins"
    admin.save
  end

  desc "Create the default group"
  task :default_group => [:environment] do
    default_tags = %w[technology business science politics religion
                               sports entertainment gaming lifestyle offbeat]

    subdomain = AppConfig.application_name.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].strip.gsub(/\s+/, "-").downcase
    default_group = Group.new(:name => AppConfig.application_name,
                              :domain => AppConfig.domain,
                              :subdomain => subdomain,
                              :domain => AppConfig.domain,
                              :description => "question-and-answer website",
                              :legend => "question and answer website",
                              :default_tags => default_tags,
                              :state => "active")

    default_group.save!
    if admin = User.find_by_login("admin")
      default_group.owner = admin
      default_group.add_member(admin, "owner")
    end
    default_group.logo = File.open(RAILS_ROOT+"/public/images/logo.png")
    default_group.save
  end

  desc "Create default widgets"
  task :create_widgets => :environment do
    default_group = Group.find_by_domain(AppConfig.domain)

    default_group.widgets << GroupsWidget.create(:position => 0)
    default_group.widgets << UsersWidget.create(:position => 1)
    default_group.widgets << BadgesWidget.create(:position => 2)
    default_group.save!
  end

  desc "Create admin user"
  task :create_admin => [:environment] do
    admin = User.new(:login => "admin", :password => "admins",
                                        :password_confirmation => "admins",
                                        :email => "shapado@example.com",
                                        :role => "admin")
    admin.save!
  end

  desc "Create user"
  task :create_user => [:environment] do
    user = User.new(:login => "user", :password => "user123",
                                      :password_confirmation => "user123",
                                      :email => "user@example.com",
                                      :role => "user")
    user.save!
  end

  desc "Reindex data"
  task :reindex => [:environment] do
    Question.find_each do |question|
      question._keywords = []
      question.save(:validate => false)
    end

    Answer.find_each do |answer|
      answer._keywords = []
      answer.save(:validate => false)
    end
  end
end

