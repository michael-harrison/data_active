module StepHelper
  def StepHelper.load_fixtures(path)
    fixtures_folder = path
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }

    if defined? Fixtures == nil
      Fixtures.reset_cache
      Fixtures.create_fixtures(fixtures_folder, fixtures)
    else
      ActiveRecord::Fixtures.reset_cache
      ActiveRecord::Fixtures.create_fixtures(fixtures_folder, fixtures)
    end
  end
end

