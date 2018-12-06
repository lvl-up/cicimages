module Content
  class Template
    attr_reader :dir, :path, :full_path

    def initialize(path, _project_root_dir)
      @full_path = path
      @dir = parent_directory(path)
      @path = relative_path(path, dir)
    end

    def rendered_file_path
      full_path.gsub(%r{.templates/.*?erb}, filename).gsub('.erb', '')
    end

    def filename
      File.basename(path)
    end

    private

    def parent_directory(dir)
      File.expand_path("#{File.dirname(dir)}/..").to_s
    end

    def relative_path(full_path, root)
      ".#{File.expand_path(full_path).gsub(File.expand_path(root), '')}"
    end
  end
end
