module DigestMethods
  def digest(path:, digest_component:, excludes: [])
    excludes = paths(*excludes)

    files = files(path).sort.reject do |f|
      excludes.include?(f) || ignored?(path, f)
    end

    content = files.map { |f| File.read(f) }.join
    Digest::MD5.hexdigest(content << digest_component).to_s
  end

  def excluded_files(template)
    all_files_templates = files(templates_directory(template))
    rendered_files = all_files_templates.collect { |t| filename(t) }.find_all { |f| File.exist?(f) }
    all_files_templates.reject { |file| file == template }.concat(rendered_files)
  end

  def paths(*paths)
    paths.find_all { |excluded_file| File.exist?(excluded_file) }.collect { |path| full_path(path) }
  end

  private

  def files(path)
    files = paths(*Dir.glob("#{path}/**/*", ::File::FNM_DOTMATCH))
    files.find_all { |f| !File.directory?(f) }
  end

  def filename(template)
    "#{File.expand_path("#{File.dirname(template)}/..")}/#{File.basename(template, '.erb')}"
  end

  def full_path(path)
    File.expand_path(path)
  end

  def git_ignore_content(path)
    git_ignore_file = "#{path}/.gitignore"
    File.exist?(git_ignore_file) ? File.read(git_ignore_file) : ''
  end

  def ignored?(path, file)
    ignored_files(path).find { |ignore| file.include?(ignore) || Pathname.new(file).fnmatch?(ignore) }
  end

  def ignored_files(path)
    files = git_ignore_content(path).lines.collect { |line| sanitise(line) }
    files << '.git'
  end
end
