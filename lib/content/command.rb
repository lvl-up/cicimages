require 'erb'
require 'thor'
require 'rake'
require 'json'

require_relative 'instructions'
require_relative 'render_methods'
require_relative 'helpers'
require_relative 'errors'

module Content
  class Command < Thor
    def self.exit_on_failure?
      true
    end

    desc 'requiring_update', 'generate checksum'
    option :digest_component,
           type: :string,
           required: false,
           default: '',
           desc: 'value to be considered when generating digest'

    def requiring_update(path = '.')
      directories = if File.directory?(path)
                      templates(path)
                    else
                      [template]
                    end

      results = directories.find_all do |temp|
        template_updated?(temp, Dir.pwd)
      end.flatten

      say results.to_json
    end

    desc 'generate', 'render templates'
    option :verbose, type: :boolean, default: false
    option :environment_variables, type: :string, required: false
    option :digest_component,
           type: :string,
           required: false,
           desc: 'value to be considered when generating digest',
           default: ''

    def generate(path = '.')
      register_environment(options[:environment_variables])

      templates = File.directory?(path) ? templates(path) : [path]

      original_dir = Dir.pwd
      failures = all_updated(templates, original_dir).find_all do |template|
        process_template(original_dir, template)
      end

      raise CourseContentRenderingError, failures.collect(&:path) unless failures.empty?
    end

    desc 'create <NAME>', 'create a new exercise'

    def create(name)
      say "Creating new exercise: #{name}"
      FileUtils.mkdir_p(name)

      exercise_structure['directories'].each do |directory|
        FileUtils.mkdir_p("#{name}/#{directory}")
      end

      FileUtils.cp_r("#{scaffold_path}/.", name)

      all_files_in(name).each { |path| say "Created: #{path}" }

      say ok 'Complete'
    end

    no_commands do
      include Helpers
    end
  end
end
