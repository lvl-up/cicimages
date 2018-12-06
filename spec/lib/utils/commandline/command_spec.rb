require 'utils/commandline'
module Commandline
  describe Command do
    include_context :command

    describe '#run' do
      context 'fail_on_error true' do
        subject {described_class.new('boom', raise_on_error: true)}
        it 'returns the result object' do
          expect {subject.run}.to raise_error(described_class::Error) do |exception|
            expected_return = Return.new(stdout: '', stderr: 'bash: boom: command not found', exit_code: 127)
            expect(exception.command_return).to eq(expected_return)
          end
        end
      end

      context 'dir set' do
        subject {described_class.new('pwd', dir: Dir.pwd)}

        it 'runs the command in that directory' do
          expect(subject.run).to eq(Return.new(stdout: Dir.pwd, stderr: '', exit_code: 0))
        end
      end

      context 'silent false' do
        subject {described_class.new('echo hello', silent: false)}

        it 'prints out the output from stdout' do
          subject.run
          expect(stdout.string).to eq("hello\n")
        end
      end

      context 'environment variables set' do
        subject {described_class.new('echo "hello ${MYVAR}"', env: {'MYVAR' => 'world'})}
        it 'passes them to the command' do
          result = subject.run
          expect(result.stdout).to eq('hello world')
        end
      end

      subject {described_class.new('echo hello')}

      it 'returns the result object' do
        result = subject.run
        expect(result).to eq(Return.new(stdout: 'hello', stderr: '', exit_code: 0))
      end
    end
  end
end
