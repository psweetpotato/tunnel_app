require 'pry'

describe "Feeds Page" do
  before(:each) do
    visit '/profile'
    fill_in 'obsession', with: 'test'
    click_button 'submit'
  end

  it 'has a link to the profile edit page' do
    find_link('Profile').click
    expect(page).to have_css('input[type=checkbox]')
  end

  it 'has 3 feeds' do
    expect(page).to have_css('section', count: 3 )
  end

  it 'has a link to the twitter show page' do
    find_link('Twitter').click
    expect(page).to have_content('Twitter')
  end

  it 'has a link to the times show page' do
    find_link('The Times').click
    expect(page).to have_content('News')
  end

  it 'has a link to the google graph show page' do
    find_link('Google Trending').click
    expect(page).to have_content('Trending')
  end


end
