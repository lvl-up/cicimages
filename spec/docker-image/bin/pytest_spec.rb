describe 'pytest' do
  it_behaves_like 'container wrapper', image: 'cicimages/wrappers-pytest:latest', env: { 'PYTHONDONTWRITEBYTECODE': 1 }
end
