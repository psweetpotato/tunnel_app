require 'pry'

describe "Feeds Page" do
  before(:each) do
    visit '/profile'
    fill_in 'obsession', with: 'test'
    click_button 'submit'
  end

  it 'has a link to the profile edit page' do
    find_link('Profile').click
    expect(page).to have_css('checkbox')
  end


end
