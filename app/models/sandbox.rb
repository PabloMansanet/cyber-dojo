
class Sandbox

  def initialize(avatar)
    @parent = avatar
  end

  def avatar
    @parent
  end

  def path
    avatar.path + 'sandbox/'
  end

  def start
    dir.make
    avatar.visible_files.each { |filename, content| git_add(filename, content) }
  end

  def save_files(delta, files)
    delta[:deleted].each { |filename| git_rm(filename) }
    delta[:new    ].each { |filename| git_add(filename, filter(filename, files)) }
    delta[:changed].each { |filename|   write(filename, filter(filename, files)) }
  end

  def run_tests(time_limit)
    runner.run(self, './cyber-dojo.sh', time_limit)
  end

  private

  include ExternalParentChain

  def filter(filename, files)
    content = avatar.kata.language.filter(filename, files[filename])
    files[filename] = content
  end

  def git_add(filename, content)
    write(filename, content)
    git.add(path, filename)
  end

  def git_rm(filename)
    git.rm(path, filename)
  end

end
