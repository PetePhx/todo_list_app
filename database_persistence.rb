require "pg"

class DatabasePersistence
  def initialize(logger)
    # @db = PG.connect(dbname: "todos")
    @db = if Sinatra::Base.production?
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todos")
      end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(list_id)
    # todos = find_todos_for_list(list_id)
    sql = <<~SQL
          SELECT lists.id, lists.name,
            COUNT(todos.id) AS todos_count,
            COUNT(NULLIF(completed, TRUE)) AS todos_remaining_count
            FROM lists LEFT JOIN todos
            ON lists.id = list_id
            WHERE lists.id = $1
            GROUP BY lists.id
            ORDER BY lists.id;
    SQL
    result = query(sql, list_id)
    tuple_to_list_hash(result.first)
  end

  def all_lists
    sql = <<~SQL
          SELECT lists.id, lists.name,
            COUNT(todos.id) AS todos_count,
            COUNT(NULLIF(completed, TRUE)) AS todos_remaining_count
            FROM lists LEFT JOIN todos
            ON lists.id = list_id
            GROUP BY lists.id
            ORDER BY lists.id;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def create_new_list(list_name)
    query("INSERT INTO lists (name) VALUES ($1);", list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1;", id)
    query("DELETE FROM lists WHERE id = $1;", id)
  end

  def update_list_name(list_id, new_name)
    query("UPDATE lists SET name = $1 WHERE id = $2", new_name, list_id)
  end

  def create_new_todo(list_id, todo_name)
    query("INSERT INTO todos (list_id, name) VALUES ($1, $2);",
          list_id,
          todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    query("DELETE FROM todos WHERE list_id = $1 AND id = $2;",
          list_id,
          todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    query("UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;",
          { true => "TRUE", false => "FALSE" }[new_status],
          list_id,
          todo_id)
  end

  def mark_all_todos_as_completed(list_id)
    query("UPDATE todos SET completed = TRUE WHERE list_id = $1;",
          list_id)
  end

  def find_todos_for_list(list_id)
    sql_todos = "SELECT * FROM todos WHERE list_id = $1;"
    result_todos = query(sql_todos, list_id)
    result_todos.map do |tuple|
      { id: tuple["id"].to_i,
        list_id: tuple["list_id"].to_i,
        name: tuple["name"],
        completed: tuple["completed"] == "t" }
    end
  end

  private

    def tuple_to_list_hash(tuple)
      { id: tuple["id"].to_i,
        name: tuple["name"],
        todos_count: tuple["todos_count"].to_i,
        todos_remaining_count: tuple["todos_remaining_count"].to_i }
    end
end
