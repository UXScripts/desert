require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Desert
describe Manager, :shared => true do
  it_should_behave_like "Desert::Manager fixture"

  def register_all_plugins
    roots = []
    Dir["#{RAILS_ROOT}/vendor/plugins/*"].each do |dir|
      unless dir =~ /\.svn/
        roots << dir
        manager.register_plugin dir
      end
    end
    roots
  end
end

describe Manager, ".method_missing" do
  it_should_behave_like "Desert::Manager"

  it "proxies to Manager instance" do
    Desert::Manager.plugins.should === Desert::Manager.instance.plugins
  end
end

describe Manager, "#instance" do
  it_should_behave_like "Desert::Manager"

  it "is a ComponenManager object" do
    Desert::Manager.instance.is_a?(Desert::Manager).should == true
  end

  it "is a singleton" do
    Desert::Manager.instance.should === Desert::Manager.instance
  end
end

describe Manager, "#register_plugin" do
  it_should_behave_like "Desert::Manager"

  before do
    @plugin_root = "#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy"
    @plugin = @manager.register_plugin(@plugin_root)
  end

  it "creates a Plugin object based on the path" do
    @plugin.path.should == File.expand_path(@plugin_root)
    @plugin.name.should == "acts_as_spiffy"
  end

  it "adds the plugin to the list" do
    @manager.plugins.should == [@plugin]
  end

  it "does not add plugin when plugin is already on list" do
    @plugin = @manager.register_plugin(@plugin_root)
    @manager.plugins.should == [@plugin]
  end

  it "allows pending plugin registration when a block is passed in" do
    plugin2_root = "#{RAILS_ROOT}/vendor/plugins/super_spiffy"
    @manager.register_plugin(plugin2_root) do
      @manager.plugins.should_not include(Plugin.new(plugin2_root))
      @manager.load_paths.should include("#{File.expand_path(plugin2_root)}/lib")
    end
  end
end

describe Manager, "#load_paths" do
  it_should_behave_like "Desert::Manager"
  attr_accessor :manager

  before do
    Dependencies.load_paths << "#{RAILS_ROOT}/spec/external_files"

    @other_load_path = "#{RAILS_ROOT}/app/helpers/another_dir"
    $LOAD_PATH << @other_load_path
  end

  after do
    $LOAD_PATH.delete(@other_load_path)
  end

  it "returns all of the load paths ordered by plugins and then Rails directories" do
    roots = register_all_plugins

    expected_load_paths = []
    roots.each do |plugin_root|
      expected_load_paths.concat [
        "#{plugin_root}/app",
        "#{plugin_root}/app/models",
        "#{plugin_root}/app/controllers",
        "#{plugin_root}/app/helpers",
        "#{plugin_root}/lib"
      ]
    end

    rails_root = File.expand_path(RAILS_ROOT)
    expected_load_paths.concat [
      "#{rails_root}/app",
      "#{rails_root}/app/models",
      "#{rails_root}/app/controllers",
      "#{rails_root}/app/helpers",
      "#{rails_root}/lib",
      "#{rails_root}/spec/external_files"
    ]
    manager.load_paths.should == expected_load_paths
  end
end

describe Manager, "#directory_on_load_path?" do
  it_should_behave_like "Desert::Manager"

  it "returns true when there is a directory on the Rails load path" do
    Desert::Manager.
      directory_on_load_path?("spiffy").should be_true
  end

  it "returns false when there is a file but no directory on load path" do
    Desert::Manager.
      directory_on_load_path?("spiffy_helper").should be_false
  end

  it "returns false when there is no directory on load path" do
    Desert::Manager.
      directory_on_load_path?("i_dont_exist").should be_false
  end
end

describe Manager, "#find_plugin" do
  it_should_behave_like "Desert::Manager"

  before do
    @plugin_root = "#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy"
    @manager.register_plugin @plugin_root
  end

  it "returns true when registered plugin name passed in" do
    @manager.find_plugin('acts_as_spiffy').
      should == Plugin.new(@plugin_root)
  end

  it "returns false when nonregistered plugin name passed in" do
    @manager.find_plugin('acts_as_absent').
      should == nil
  end

  it "returns true when registered plugin directory passed in" do
    @manager.find_plugin(@plugin_root).
      should == Plugin.new(@plugin_root)
  end

  it "returns false when nonregistered plugin directory passed in" do
    @manager.find_plugin("#{RAILS_ROOT}/vendor/plugins/non_existent").
      should == nil
  end
end

describe Manager, "#plugin_exists?" do
  it_should_behave_like "Desert::Manager"

  before do
    @plugin_root = "#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy"
    @manager.register_plugin @plugin_root
  end

  it "returns true when registered plugin name passed in" do
    @manager.plugin_exists?('acts_as_spiffy').should be_true
  end

  it "returns false when nonregistered plugin name passed in" do
    @manager.plugin_exists?('acts_as_absent').should be_false
  end

  it "returns true when registered plugin directory passed in" do
    @manager.plugin_exists?(@plugin_root).should be_true
  end

  it "returns false when nonregistered plugin directory passed in" do
    @manager.plugin_exists?("#{RAILS_ROOT}/vendor/plugins/non_existent").should be_false
  end
end

describe Manager, "#plugin_path" do
  it_should_behave_like "Desert::Manager"

  before do
    @plugin_root = "#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy"
    @manager.register_plugin @plugin_root
  end

  it "returns the path for the passed in plugin name" do
    @manager.plugin_path('acts_as_spiffy').should == File.expand_path(@plugin_root)
  end

  it "returns nil when plugin does not exist" do
    @manager.plugin_path('acts_as_absent').should be_nil
  end
end

describe Manager, "#files_on_load_path" do
  it_should_behave_like "Desert::Manager"
  attr_reader :roots, :manager, :plugin_root

  before do
    @roots = register_all_plugins
    @acts_as_spiffy_path = File.expand_path("#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy")
    @manager.register_plugin @acts_as_spiffy_path
    @super_spiffy_path = File.expand_path("#{RAILS_ROOT}/vendor/plugins/super_spiffy")
    @manager.register_plugin @super_spiffy_path
    @plugin_root = "#{RAILS_ROOT}/vendor/plugins"
  end
  
  it "returns the list of file paths that match the passed in value" do
    manager.files_on_load_path("spiffy_helper").should == [
      "#{plugin_root}/acts_as_spiffy/app/helpers/spiffy_helper.rb",
      "#{plugin_root}/aa_depends_on_acts_as_spiffy/app/helpers/spiffy_helper.rb",
      "#{plugin_root}/the_grand_poobah/app/helpers/spiffy_helper.rb",
      "#{plugin_root}/super_spiffy/app/helpers/spiffy_helper.rb",
      "#{RAILS_ROOT}/app/helpers/spiffy_helper.rb"
    ]
  end
end

describe Manager, "#layout_paths" do
  it_should_behave_like "Desert::Manager"

  before do
    @acts_as_spiffy_path = File.expand_path("#{RAILS_ROOT}/vendor/plugins/acts_as_spiffy")
    @manager.register_plugin @acts_as_spiffy_path
    @super_spiffy_path = File.expand_path("#{RAILS_ROOT}/vendor/plugins/super_spiffy")
    @manager.register_plugin @super_spiffy_path
  end

  it "returns the layout paths ordered by precedence" do
    @manager.layout_paths.should == [
      "#{@super_spiffy_path}/app/views/layouts",
      "#{@acts_as_spiffy_path}/app/views/layouts",
    ]
  end
end
end