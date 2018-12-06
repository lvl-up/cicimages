require_relative 'template'

module Content
  module Helpers
    include RenderMethods

    def all_files_in(name)
      Dir.glob("#{name}/**/*", File::FNM_DOTMATCH).find_all { |file| !%w[. ..].include?(File.basename(file)) }
    end

    def all_updated(paths, project_root_dir)
      paths.find_all { |path| template_updated?(path, project_root_dir) }.collect do |template|
        Template.new(template, project_root_dir)
      end
    end

    def exercise_structure
      @exercise_structure ||= YAML.safe_load(File.read(ENV['SCAFFOLD_STRUCTURE']))
    end

    def exercise_directories(path)
      Dir["#{path}/**/.templates"]
    end

    def print_rendering_banner(template_path)
      template_message = "# Generating template: #{template_path} in path: #{ENV['exercise_path']} #"
      top_and_tail = ''.rjust(template_message.length, '#')
      say "#{top_and_tail}\n#{template_message}\n#{top_and_tail}"
    end

    def process_template(original_dir, template)
      template_dir = template.dir
      Dir.chdir template_dir
      ENV['exercise_path'] = template_dir.gsub(original_dir, '')
      print_rendering_banner(template.path)
      !render_exercise(template.path, digest_component: options[:digest_component])
    ensure
      Dir.chdir original_dir
    end

    def quiet?
      options[:verbose] == false
    end

    def scaffold_path
      @scaffold_path ||= ENV['SCAFFOLD_PATH']
    end

    def register_environment(environment_variables_string)
      environment_variables = environment_variables_string.to_s.scan(%r{([\w+.]+)\s*=\s*([\w+./-]+)?}).to_h
      environment_variables.each { |key, value| ENV[key] = value }
    end

    def templates(path)
      exercise_directories(path).collect do |templates_dir|
        Dir["#{File.expand_path(templates_dir)}/*.md.erb"]
      end.flatten
    end

    def template_updated?(template, project_root_dir)
      template = template.is_a?(String) ? Template.new(template, project_root_dir) : template

      return true unless File.exist?(template.rendered_file_path)

      digest = digest(path: template.dir,
                      digest_component: options[:digest_component],
                      excludes: excluded_files(template.full_path))

      !File.read(template.rendered_file_path).include?(digest)
    end
  end

end