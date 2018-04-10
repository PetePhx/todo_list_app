require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)
    tuple = result.first
    { id: tuple["id"], name: tuple["name"], todos: [] }
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"], name: tuple["name"], todos: [] }
    end
  end

  def create_new_list(list_name)
    # @session[:lists] << { id: next_list_id, name: list_name, todos: [] }
  end

  def delete_list(id)
    # @session[:lists].delete_if { |ls| ls[:id] == id }
  end

  def update_list_name(list_id, new_name)
    # list = find_list(list_id)
    # list[:name] = new_name
  end

  def create_new_todo(list_id, todo_name)
    # list = find_list(list_id)
    # id = next_element_id(list[:todos])
    # list[:todos] << { id: id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    # list = find_list(list_id)
    # list[:todos].find { |todo| todo[:id] == todo_id }[:completed] = new_status
  end

  def mark_all_todos_as_completed(list_id)
    # list = find_list(list_id)
    # list[:todos].each { |todo| todo[:completed] = true }
  end
end