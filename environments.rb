configure :development do
    ActiveRecord::Base.establish_connection(YAML.load(File.read('config/pg.yml'))['default'])
end
