require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def all_todos_done?(list)
    count_todos(list) >= 1 && count_todos_remaining(list).zero?
  end

  def list_class(list)
    all_todos_done?(list) ? "complete" : ""
  end

  def todo_class(todo)
    todo[:completed] ? "complete" : ""
  end

  def count_todos_remaining(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def count_todos(list)
    list[:todos].size
  end

  def sort_lists(list_arr, &block)
    list_arr.each_with_index.sort_by do |list, _|
      all_todos_done?(list) ? 1 : 0
    end.each(&block)
  end

  def sort_todos(list, &block)
    list[:todos].each_with_index.sort_by do |todo, _|
      todo[:completed] ? 1 : 0
    end.each(&block)
  end

  def espace_html(content)
    Rack::Utils.escape_html(content)
  end
end

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list was not found."
  redirect("/lists")
end

def next_element_id(elements)
  max = elements.map { |todo| todo[:id] }.max || 0
  max + 1
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
  @list = load_list(@id)
  erb :list, layout: :layout
end

# Render the edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = load_list(@id)
  erb :edit_list, layout: :layout
end

# Update an existing list
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = load_list(@id)

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
  session[:lists].delete_at(@id)
  if env["HTTP_X_REQUESTED_WITH"] = "XMLHttpRequest"
    # status 204 # request successful, no content
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# Add a new todo item to a list
post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = load_list(@id)
  text = params['todo'].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }
    session[:success] = "The todo item has been added."
    redirect "/lists/#{@id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do |list_id, todo_id|
  @list = load_list(list_id.to_i)
  @list[:todos].delete_if { |todo| todo[:id] == todo_id.to_i }
  if env["HTTP_X_REQUESTED_WITH"] = "XMLHttpRequest"
    status 204 # request successful, no content
  else
    session[:success] = "The todo item has been deleted."
    redirect "/lists/#{list_id}"
  end
end

# Mark an item completed/incomplete
post "/lists/:list_id/todos/:todo_id" do |list_id, todo_id|
  @list = load_list(list_id.to_i)
  @list[:todos].find { |todo| todo[:id] == todo_id.to_i }[:completed] =
    case params[:completed]
    when "true" then true
    when "false" then false
    end
  session[:success] = "The todo item has been updated."
  redirect "/lists/#{list_id}"
end

# Mark all items as complete
post "/lists/:list_id/complete_all" do |list_id|
  @list = load_list(list_id.to_i)
  todos = @list[:todos]
  todos.each { |todo| todo[:completed] = true }
  session[:success] = "All todo items are marked as complete."
  redirect "/lists/#{list_id}"
end
