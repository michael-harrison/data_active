module StepHelper
  def StepHelper.load_fixtures(path)
    fixtures = Dir[File.join(path, '*.yml')].map {|f| File.basename(f, '.yml') }

    if defined? Fixtures == nil
      puts 'create via Fixtures'
      Fixtures.reset_cache
      Fixtures.create_fixtures(path, fixtures)
    else
      puts 'create via ActiveRecord::Fixtures'
      ActiveRecord::Fixtures.reset_cache
      ActiveRecord::Fixtures.create_fixtures(path, fixtures)
    end
  end
end

