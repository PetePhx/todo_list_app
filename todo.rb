require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def all_todos_done?(list)
    count_todos(list) >= 1 && count_todos_remaining(list).zero?
  end

  def list_class(list)
    "complete" if all_todos_done?(list)
  end

  def count_todos_remaining(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def count_todos(list)
    list[:todos].size
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View the list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a specific list
get "/lists/:id" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :list, layout: :layout
end

# Render the edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :edit_list, layout: :layout
end

# Update an existing list
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@id}"
  end
end

# Delete a list
post "/lists/:id/delete" do
  @id = params[:id].to_i
  session[:lists].delete_at(@id) # if @session[:lists][@id]
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add a new todo item to a list
post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  text = params['todo'].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo item has been added."
    redirect "/lists/#{@id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do |list_id, todo_id|
  session[:lists][list_id.to_i][:todos].delete_at(todo_id.to_i)
  session[:success] = "The todo item has been deleted."
  redirect "/lists/#{list_id}"
end

# Mark an item completed/incomplete
post "/lists/:list_id/todos/:todo_id" do |list_id, todo_id|
  @list = session[:lists][list_id.to_i]
  @list[:todos][todo_id.to_i][:completed] = case params[:completed]
                                            when "true" then true
                                            when "false" then false
                                            end
  session[:success] = "The todo item has been updated."
  redirect "/lists/#{list_id}"
end

# Mark all items as complete
post "/lists/:list_id/complete_all" do |list_id|
  @list = session[:lists][list_id.to_i]
  todos = session[:lists][list_id.to_i][:todos]
  todos.each { |todo| todo[:completed] = true }
  session[:success] = "All todo items are marked as complete."
  redirect "/lists/#{list_id}"
end
