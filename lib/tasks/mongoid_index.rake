namespace :db do
    task :create_indexes, :environment do |t, args|
        unless args[:environment]
            puts "Must provide an environment"
            exit
        end

        yaml = YAML.load_file("config/mongoid.yml")

        env_info = yaml[args[:environment]]
        unless env_info
            puts "Unknown environment"
            exit
        end

        Mongoid.configure do |config|
            config.from_hash(env_info)
        end

        StatisticItem.create_indexes
        # MyModels::Thing2.create_indexes
        # MyModels::Thing3.create_indexes
    end
end