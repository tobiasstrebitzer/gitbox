require 'rubygems'
require 'httparty'

class GitBox
  include HTTParty
  default_params :output => 'json'
  format :json

  def self.get_project_info()
    base_uri $SERVER
    basic_auth $USER, $PASSWORD
    get("/projects/#{$PROJECT}.json")
  end

  def self.get_project_task_list()
    base_uri $SERVER
    basic_auth $USER, $PASSWORD
    get("/projects/#{$PROJECT}/task_lists.json")
  end
  
  def self.get_project_tasks(id)
    base_uri $SERVER
    basic_auth $USER, $PASSWORD
    get("/projects/#{$PROJECT}/task_lists/#{id}.json")
  end
  
  def self.update_status(listid, id, status, message)
    base_uri $SERVER
    basic_auth $USER, $PASSWORD
    format :xml
    post("/projects/#{$PROJECT}/task_lists/#{listid}/tasks/#{id}/comments.json", :query => { :comment => { :status => status, :body => message } })
  end
end