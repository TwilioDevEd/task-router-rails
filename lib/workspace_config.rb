class WorkspaceConfig
  WORKSPACE_NAME          = 'Rails Workspace'.freeze
  WORKFLOW_NAME           = 'Sales'.freeze
  WORKFLOW_TIMEOUT        = ENV['WORKFLOW_TIMEOUT'].freeze
  QUEUE_TIMEOUT           = ENV['QUEUE_TIMEOUT'].freeze
  ASSIGNMENT_CALLBACK_URL = ENV['ASSIGNMENT_CALLBACK_URL'].freeze
  EVENT_CALLBACK_URL      = ENV['EVENT_CALLBACK_URL'].freeze
  BOB_NUMBER              = ENV['BOB_NUMBER'].freeze
  ALICE_NUMBER            = ENV['ALICE_NUMBER'].freeze

  def self.setup
    puts 'Configuring workspace, please wait ...'
    new.setup
    puts 'Workspace ready!'
  end

  def initialize
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token  = ENV['TWILIO_AUTH_TOKEN']
    @client      = taskrouter_client
  end

  def setup
    @workspace_sid = create_workspace
    @client = taskrouter_client
    WorkspaceInfo.instance.workers = create_workers
    workflow_sid = create_workflow.sid
    WorkspaceInfo.instance.workflow_sid = workflow_sid
    idle_activity_sid = activity_by_name('Idle').sid
    WorkspaceInfo.instance.post_work_activity_sid = idle_activity_sid
    WorkspaceInfo.instance.idle_activity_sid = idle_activity_sid
    WorkspaceInfo.instance.offline_activity_sid = activity_by_name('Offline').sid
    WorkspaceInfo.instance.workspace_sid = @workspace_sid
  end

  private

  attr_reader :client, :account_sid, :auth_token

  def taskrouter_client
    client_instance = Twilio::REST::Client.new(
      account_sid,
      auth_token
    )

    client_instance.taskrouter.v1
  end

  def create_workspace
    workspace = client.workspaces.list(friendly_name: WORKSPACE_NAME).first
    workspace.delete unless workspace.nil?

    workspace = client.workspaces.create(
      friendly_name: WORKSPACE_NAME,
      event_callback_url: EVENT_CALLBACK_URL
    )

    workspace.sid
  end

  def create_workers
    bob_attributes = "{\"products\": [\"ProgrammableSMS\"], \"contact_uri\": \"#{BOB_NUMBER}\"}"
    alice_attributes = "{\"products\": [\"ProgrammableVoice\"], \"contact_uri\": \"#{ALICE_NUMBER}\"}"

    bob   = create_worker('Bob', bob_attributes)
    alice = create_worker('Alice', alice_attributes)

    {
      BOB_NUMBER   => { sid: bob.sid,   name: 'Bob' },
      ALICE_NUMBER => { sid: alice.sid, name: 'Alice' }
    }
  end

  def create_worker(name, attributes)
    client.workspaces(@workspace_sid).workers.create(
      friendly_name: name,
      attributes:    attributes,
      activity_sid:  activity_by_name('Idle').sid
    )
  end

  def activity_by_name(name)
    client.workspaces(@workspace_sid).activities.list(friendly_name: name).first
  end

  def create_task_queues
    reservation_activity_sid = activity_by_name('Reserved').sid
    assignment_activity_sid  = activity_by_name('Busy').sid

    voice_queue = create_task_queue('Voice', reservation_activity_sid,
                                    assignment_activity_sid,
                                    "products HAS 'ProgrammableVoice'")

    sms_queue = create_task_queue('SMS', reservation_activity_sid,
                                  assignment_activity_sid,
                                  "products HAS 'ProgrammableSMS'")

    all_queue = create_task_queue('All', reservation_activity_sid,
                                  assignment_activity_sid, '1==1')

    { voice: voice_queue, sms: sms_queue, all: all_queue }
  end

  def create_task_queue(name, reservation_sid, assignment_sid, target_workers)
    client.workspaces(@workspace_sid).task_queues.create(
      friendly_name: name,
      reservation_activity_sid: reservation_sid,
      assignment_activity_sid: assignment_sid,
      target_workers: target_workers
    )
  end

  def create_workflow
    queues = create_task_queues
    config = workflow_config(queues)

    client.workspaces(@workspace_sid).workflows.create(
      configuration: config.to_json,
      friendly_name: WORKFLOW_NAME,
      assignment_callback_url: ASSIGNMENT_CALLBACK_URL,
      fallback_assignment_callback_url: ASSIGNMENT_CALLBACK_URL,
      task_reservation_timeout: WORKFLOW_TIMEOUT
    )
  end

  def workspace_sid
    @workspace_sid || 'no_workspace_yet'
  end

  def workflow_config(queues)
    {
      task_routing: {
        filters: [
          {
            expression: 'selected_product=="ProgrammableVoice"',
            targets: [{ queue: queues[:voice].sid }]
          },
          {
            expression: 'selected_product=="ProgrammableSMS"',
            targets: [{ queue: queues[:sms].sid }]
          }
        ],
        default_filter: {
          expression: '1==1',
          targets: [{ queue: queues[:all].sid }]
        }
      }
    }
  end
end
