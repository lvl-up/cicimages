require 'digest'
require 'tmpdir'
require_relative 'instructions'
require_relative 'digest_methods'


module Content
  module RenderMethods
    include Commandline::Output
    include Instructions
    include DigestMethods

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def render_exercise(template, digest_component: '')
      say "Rendering: #{template}"
      template = full_path(template)
      current_dir = Dir.pwd

      content = render(template)
      File.open(filename(template), 'w') { |f| f.write("#{content}\n#{stamp(digest_component, template)}") }

      say ok "Finished: #{template}"
      true
    rescue StandardError => e
      say error "Failed to generate file from: #{template}"
      say "#{e.message}\n#{e.backtrace}"
      false
    ensure
      Dir.chdir(current_dir)
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def render_file_path(template)
      template.gsub(%r{.templates/.*?erb}, File.basename(template)).gsub('.erb', '')
    end

    def templates_directory(template)
      full_path(File.dirname(template))
    end

    private

    def anonymise(string)
      substitutes.each do |key, value|
        string = string.gsub(key, value)
      end
      string
    end

    def stamp(digest_component, template)
      "  \n\nRevision: #{digest(path: full_path("#{templates_directory(template)}/.."),
                                digest_component: digest_component.to_s,
                                excludes: excluded_files(template))}"
    end

    def reset
      @result = nil
      @after_rendering_commands = []
    end

    def render(template)
      reset
      template_content = File.read(File.expand_path(template))

      erb_template = ERB.new(template_content)

      result = run_in_temp_dir?(template_content) ? render_in_temp_dir(erb_template) : erb_template.result(binding)

      anonymise(result)
    ensure
      after_rendering_commands.each { |command| test_command(command) }
      say '' if quiet?
    end

    def filename(template)
      "#{File.expand_path("#{File.dirname(template)}/..")}/#{File.basename(template, '.erb')}"
    end

    def render_in_temp_dir(erb_template)
      output = nil
      Dir.mktmpdir do |path|
        original_dir = Dir.pwd
        Dir.chdir(path)
        output = erb_template.result(binding)
        Dir.chdir(original_dir)
      end
      output
    end

    def run_in_temp_dir?(template_content)
      /<%#\s*instruction:run_in_temp_directory\s*%>/.match?(template_content)
    end

    def sanitise(string)
      string.chomp.strip
    end
  end
end
