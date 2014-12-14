helpers Sinatra::ContentFor
helpers do
  def protected!
    # override with auth logic
  end
end

before '/protected/*' do
  puts 'should be printing auth token'
  puts settings.auth_token
  protected!
end

get '/protected/admin/?' do
  protected!
  'it works'
end