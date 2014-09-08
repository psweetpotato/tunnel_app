require 'pry'

describe "Profile Page" do
  before(:each) do
    visit '/profile'
  end

  it 'prompts user for an obsession' do
    expect(page).to have_content("obsession")
  end

  it 'redirects to the dashboard' do
    fill_in 'obsession', with: 'test'
    click_button 'submit'
    expect(page).to have_content("test")
  end

  it 'prompts user for new obsession when one does not return results' do
    fill_in 'obsession', with: 'aghjkl'
    click_button 'submit'
    expect(page).to have_content("too cool")
  end

end
