shared_examples 'container wrapper' do |image:, env: {}|
  include_context :shell_spec, script_root: 'support/bin/'
  let!(:run_command) { stubbed_env.stub_command('run_command') }

  it "wraps a call to #{top_level_description}" do
    execute_script
    env = env.to_a.collect { |array| array.join('=') }.join
    expect(run_command).to be_called_with_arguments(image, "#{env} #{self.class.top_level_description}".strip)
  end

  it 'passes args on to container' do
    execute_script(['args'])
    expect(run_command).to be_called_with_arguments(anything, anything, 'args')
  end
end
