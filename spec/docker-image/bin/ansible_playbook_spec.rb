describe 'ansible-playbook' do
  it_behaves_like 'container wrapper', image: 'cicimages/wrappers-ansible:latest'
end
