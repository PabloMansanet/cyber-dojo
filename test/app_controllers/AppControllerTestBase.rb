
ENV['RAILS_ENV'] = 'test' # ????

gem 'minitest'
require 'minitest/autorun'

root = './../..'

require_relative root + '/test/test_coverage'
require_relative root + '/test/all'
require_relative root + '/config/environment'
require_relative root + '/test/TestDomainHelpers'
require_relative root + '/test/TestExternalHelpers'
require_relative root + '/test/TestHexIdHelpers'
require_relative './ParamsMaker'

class AppControllerTestBase < ActionDispatch::IntegrationTest

  def self.tmp_key
    'CYBER_DOJO_TMP_ROOT'
  end

  def self.tmp_root
    root = ENV[tmp_key]
    fail RuntimeError.new("ENV['#{tmp_key}'] not exported") if root.nil?
    root.end_with?('/') ? root : (root + '/')
  end

  fail RuntimeError.new("#ENV[#{tmp_key}] not set") if tmp_root.nil?
  FileUtils.mkdir_p(tmp_root)
  fail RuntimeError.new("#{tmp_root} does not exist") unless File.directory?(tmp_root)

  def setup
    super
    tmp_root = self.class.tmp_root
    `rm -rf #{tmp_root}/*`
    `rm -rf #{tmp_root}/.git`
    `mkdir -p #{tmp_root}`
    set_katas_root(tmp_root + 'katas')
    set_one_self_class('OneSelfDummy')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include TestDomainHelpers
  include TestExternalHelpers
  include TestHexIdHelpers

  def create_kata(language_name = random_language, exercise_name = random_exercise)
    parts = language_name.split(',')
    params = {
      language: parts[0].strip,
          test: parts[1].strip,
      exercise: exercise_name
    }
    get 'setup/save', params
    @id = json['id']
  end

  def enter
    params = { :format => :json, :id => @id }
    get 'dojo/enter', params
    assert_response :success
    avatar_name = json['avatar_name']
    assert_not_nil avatar_name
    @avatar = katas[@id].avatars[avatar_name]
    @params_maker = ParamsMaker.new(@avatar)
    @avatar
  end

  def enter_full
    params = { :format => :json, :id => @id }
    get 'dojo/enter', params
    assert_response :success
  end

  def re_enter
    params = { :format => :json, :id => @id }
    get 'dojo/re_enter', params
    assert_response :success
  end

  def kata_edit
    params = { :id => @id, :avatar => @avatar.name }
    get 'kata/edit', params
    assert_response :success
  end

  def change_file(filename, content)
    @params_maker.change_file(filename, content)
  end

  def run_tests
    params = { :format => :js, :id => @id, :avatar => @avatar.name }
    post 'kata/run_tests', params.merge(@params_maker.params)
    @params_maker = ParamsMaker.new(@avatar)
    assert_response :success
  end

  def stub_test_output(rag)
    # todo: refactor
    #       copied from test/TestHelpers.rb stub_test_colours (private)
    disk = HostDisk.new
    root = File.expand_path(File.dirname(__FILE__) + '/..') + '/app_lib/test_output'
    assert [:red,:amber,:green].include? rag
    path = "#{root}/#{@avatar.kata.language.unit_test_framework}/#{rag}"
    all_outputs = disk[path].each_file.collect{|filename| filename}
    filename = all_outputs.shuffle[0]
    output = disk[path].read(filename)
    dojo.runner.stub_output(output)
  end

  def json
    ActiveSupport::JSON.decode html
  end

  def html
    @response.body
  end

  def dir_of(object)
    disk[object.path]
  end

private

  def random_language
    # languages.collect....
    # will cause TestRunner.runnable?() to be executed...
    # which means I can't later Stub a different TestRunner...
    'Ruby, TestUnit'  # todo
  end

  def random_exercise
    'Yatzy' # todo
  end

end
