require 'rubygems'
require 'httparty'

class GitBox
  include HTTParty
  
  attr_accessor :project, :user, :pass, :server, :tasklist, :task, :status, :message

  # Initialize
  def initialize
    @project = self.read_config("project")
    @user = self.read_config("user")
    @pass = self.read_config("pass")
    @server = self.read_config("server")
    @tasklist = self.read_config("tasklist")
    @task = ''
    @status = ''
    @message = ''
    
    if(@pass == '')
      self.require_password
    end
    
  end

  # Choose task list
  def choose_task_list
    default = ""
    task_list_hash = Hash.new()
    tasks = get_project_task_list()
    puts "Select task list id:"
    tasks["task_lists"].each do |tasklist|
      if task_list_hash.empty?
        default = "#{tasklist["id"]}"
        print "* #{tasklist["id"]}: #{tasklist["name"]}\n"
      else
        print "  #{tasklist["id"]}: #{tasklist["name"]}\n"
      end
      task_list_hash[tasklist["id"]] = [tasklist["id"], tasklist["name"]]
    end
    
    # Read user input
    response = self.get_user_input(2)

    # Default
    if(response=="") then response=default end

    # Validate user input
    if !task_list_hash[response]
      puts "  not a valid task list id"
      return false
    end

    @tasklist = task_list_hash[response][0]
  end
  
  # Choose task
  def choose_task
    default = ""
    task_hash = Hash.new()
    tasks = self.get_project_tasks
    puts "Select task id for task list #{@tasklist}:"
    tasks["task_list"]["tasks"].each do |task|
      if task_hash.empty?
        default = task["id"]
        print "* #{task["id"]}: #{task["name"]}\n"
      else
        print "  #{task["id"]}: #{task["name"]}\n"
      end
      task_hash[task["id"]] = [task["id"], task["name"], task["status"]]
    end
    
    # Read user input
    response = self.get_user_input(2)

    # Default
    if (response == "") then response = default end

    # Validate user input
    if !task_hash[response]
      puts "  not a valid task id"
      return false
    end
    
    # Return result
    @task = task_hash[response]
  end
  
  # Choose status
  def choose_status
    puts "Select new status for '#{@task[1]}' (#{@task[2]}):"
    status_list = { "1" => "open", "2" => "hold", "3" => "solve", "4" => "reject" }
    status_list.each do |status, name|
      if (status == @task[2] or (@task[2] == 0 and status == 1))
        print "* #{status}: #{name}\n"
      else
        print "  #{status}: #{name}\n"
      end
    end
    response = self.get_user_input(2, 1)

    # Default
    if (response == "") then
      if (@task[2] == 0)
        response = "1"
      else
        response = @task[2]
      end
    else
      print(" -> ok\n")
      STDOUT.flush
    end

    # Validate user input
    if !status_list[response]
      puts "  not a valid status"
      return false
    end
    
    # Return result
    @status = response
  end
  
  # User input
  def choose_user
    default = ''
    user_hash = Hash.new()
    project = self.get_project_info()
    puts "Who are you?"
    project["project"]["people"]["person"].each do |user|
      if (user["username"] == @user)
        default = user["id"]
        print "* #{user["id"]}: #{user["username"]}\n"
      else
        print "  #{user["id"]}: #{user["username"]}\n"
      end
      user_hash[user["id"]] = [user["id"], user["username"]]
    end

    # Read user input
    response = self.get_user_input(2)

    # Default
    if (response == "") then response = default end

    # Validate user input
    if !user_hash[response]
      puts "  not a valid user id"
      return false
    end
    sel_user = user_hash[response]

    # Need Password?
    if (sel_user[1] != @user)
      @user = sel_user[1]
      self.require_password
    end
  end
  
  # Get commit message
  def get_message
    @message = ''
    f = File.open(".git/COMMIT_EDITMSG", "r") 
    f.each_line do |line| 
      if(line[0].chr != "#")
        @message += line
      end
    end
  end
  
  # Ask user for password
  def require_password
    puts "Enter Password:"
    print("  ")
    STDOUT.flush
    @pass = `exec < /dev/tty && stty -echo && read result && stty echo && echo $result`.chomp
    print("\n")
    STDOUT.flush
  end
  
  # Get user input
  def get_user_input(p=2,n=0)
    print("".ljust(p))
    STDOUT.flush
    if(n == 0)
      `exec < /dev/tty && read result && echo $result`.chomp
    else
      `exec < /dev/tty && read -n #{n} result && echo $result`.chomp
    end
  end
  
  # Read git config value
  def read_config(key)
    `git config --get gitbox.#{key}`.chop
  end
  
  # Get task list
  def get_project_task_list
    GitBox::base_uri @server
    GitBox::basic_auth @user, @pass
    GitBox::get("/projects/#{@project}/task_lists.json")
  end
  
  # Get tasks
  def get_project_tasks
    GitBox::base_uri @server
    GitBox::basic_auth @user, @pass
    GitBox::get("/projects/#{@project}/task_lists/#{@tasklist}.json")
  end
  
  # Get project info (users etc)
  def get_project_info()
    GitBox::base_uri @server
    GitBox::basic_auth @user, @pass
    GitBox::get("/projects/#{@project}.json")
  end
  
  # Create comment and set status
  def update_status
    GitBox::base_uri @server
    GitBox::basic_auth @user, @pass
    GitBox::headers 'Content-Type' => 'text/xml'
    GitBox::post("/projects/#{@project}/task_lists/#{@tasklist}/tasks/#{@task[0]}/comments", :body => "<?xml version='1.0' encoding='UTF-8'?><comment><body>#{@message}</body><status>#{@status}</status></comment>")
  end
end