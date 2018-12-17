describe 'wrapped_commands.sh' do
  include_context :shell_spec, script_root: 'support/bin/sh/functions'

  describe '#content_before' do
    it 'returns the content before the given delimeter' do
      input = 'a=b'
      result = execute("echo #{input} | content_before '='")
      expect(result).to_not have_error
      expect(result.stdout).to eq('a')
    end
  end

  describe '#content_after' do
    it 'returns the content after the given delimeter' do
      input = 'a=b'
      result = execute("echo #{input} | content_after '='")
      expect(result).to_not have_error
      expect(result.stdout).to eq('b')
    end
  end

  describe '#sanitise_value' do
    context 'value surrounded with double quotes' do
      it 'leaves the value alone' do
        value = 'value'
        result = execute_function(%(sanitise_value  "\"#{value}\""))
        expect(result).to_not have_error
        expect(result.stdout).to eq(%(\"#{value}\"))
      end
    end

    context 'value not surrounded with double quotes' do
      it 'surrounds the value with double quotes' do
        value = 'value'
        result = execute_function(%(sanitise_value  "#{value}"))
        expect(result).to_not have_error
        expect(result.stdout).to eq(%(\"#{value}\"))
      end
    end
  end

  describe '#sanitise_option' do
    context 'option is in format: option=value' do
      it 'surrounds the value with quotes' do
        input = '--option=value'
        result = execute_function(%(sanitise_option #{input}))
        expect(result).to_not have_error
        expect(result.stdout).to eq('--option="value"')
      end
    end

    context 'option is in format: option="value"' do
      it 'leaves everything alone' do
        input = '--option="value"'
        result = execute_function(%(sanitise_option #{input}))
        expect(result).to_not have_error
        expect(result.stdout).to eq(input)
      end
    end

    context 'option is in format: option="key=value"' do
      it 'leaves everything alone' do
        input = '--option="key=value"'
        result = execute_function(%(sanitise_option #{input}))
        expect(result).to_not have_error
        expect(result.stdout).to eq(input)
      end
    end
  end

  describe '#build_command' do
    it 'quotes options in the command' do
      input = "command --this=that --foo 'bar'"
      result = execute_function(%(build_command #{input}))
      expect(result).to_not have_error
      expect(result.stdout).to eq('command --this="that" --foo "bar"')
    end
  end

  describe '#standard_docker_options' do
    it 'outputs the standard options' do
      result = execute_function('standard_docker_options')
      expect(result.stdout).to eq('-t --privileged --network cic -w /mnt/cic_working_dir')
    end
  end

  describe '#docker_mounts' do
    it 'outputs the mounts' do
      result = execute_function('docker_mounts', 'TRACKS_PATH' => :tracks_path.to_s,
                                                 'SCAFFOLD_PATH' => :scaffold_path.to_s,
                                                 'SCAFFOLD_STRUCTURE' => :scaffold_structure.to_s,
                                                 'EXERCISES_PATH' => :exercises_path.to_s)

      expected = '-v /var/run/docker.sock:/var/run/docker.sock '
      expected << '-v /sys/fs/cgroup:/sys/fs/cgroup:ro '
      expected << '-v tracks_path:/cic/tracks '
      expected << '-v scaffold_path:/cic/scaffold '
      expected << '-v scaffold_structure:/cic/scaffold/scaffold.yml '
      expected << '-v exercises_path:/cic/exercises '
      expected << '-v /Users/leon/.netrc:/root/.netrc '
      expected << "-v #{Dir.pwd}:/mnt/cic_working_dir"
      expect(result.stdout).to eq(expected)
    end
  end

  describe '#options_and_mounts' do
    before do
      stubbed_env.stub_command(:docker_mounts.to_s).outputs(:docker_mounts, to: :stdout)
      stubbed_env.stub_command(:standard_docker_options.to_s).outputs(:standard_docker_options, to: :stdout)
    end

    context 'extra options' do
      it 'adds the options' do
        result = execute_function('options_and_mounts extra_options')
        expect(result.stdout.chomp).to eq('docker_mounts extra_options standard_docker_options')
      end
    end

    it 'outputs the standard docker optins and mounts' do
      result = execute_function('options_and_mounts')
      expect(result.stdout.chomp).to eq('docker_mounts  standard_docker_options')
    end
  end

  describe '#run' do
    it 'calls docker with the required parameters' do
      stubbed_env.stub_command('bootstrap_cic_environment').outputs('cic_environment')

      docker = stubbed_env.stub_command('docker')
      result = execute_function('run options image command arg')

      expect(result).to_not have_error
      expected_args = ['run', 'options', 'image', '/bin/bash', '-ilc', 'cic_environment command "arg"']
      expect(docker).to be_called_with_arguments(*expected_args)
    end

    it 'calls docker correctly', :integration do
      result = execute("run -i ubuntu 'echo hello'")
      expect(result.stdout).to eq('hello')
    end
  end

  describe '#run_command' do
    it 'calls run' do
      run = stubbed_env.stub_command('run')
      stubbed_env.stub_command('options_and_mounts').outputs('standard_options', to: :stdout)

      expect(execute_function('run_interactive_command image command arg')).to_not have_error
      expect(run).to be_called_with_arguments('standard_options', 'image', 'command', 'arg')
    end
  end

  describe '#run_interactive_command' do
    it 'calls run with a requirement for an interactive session' do
      run = stubbed_env.stub_command('run')
      stubbed_env.stub_command('options_and_mounts').with_args('-i').outputs('standard_options', to: :stdout)

      expect(execute_function('run_interactive_command image command arg')).to_not have_error
      expect(run).to be_called_with_arguments('standard_options', 'image', 'command', 'arg')
    end
  end
end
