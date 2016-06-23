class WorkspaceConfig
  WORKSPACE_NAME = 'Rails Workspace'.freeze

  def self.setup
    new.setup
  end

  def initialize
    @account_sid        = ENV['TWILIO_ACCOUNT_SID']
    @auth_token         = ENV['TWILIO_AUTH_TOKEN']
    @event_callback_url = ENV['EVENT_CALLBACK_URL']
    @client             = taskrouter_client
  end

  def setup
    store_workspace_sid(create_workspace)
    @client = taskrouter_client
    set_default_activity
    create_workers

    queues = create_task_queues
  end

  private

  attr_reader :client, :account_sid, :auth_token, :event_callback_url

  def store_workspace_sid(sid)
    @workspace_sid = sid
    WorkspaceInfo.instance.workspace_sid = sid
  end

  def taskrouter_client
    Twilio::REST::TaskRouterClient.new(
      account_sid,
      auth_token,
      workspace_sid
    )
  end

  def create_workspace
    workspace = client.workspaces.list(friendly_name: WORKSPACE_NAME).first
    workspace.delete unless workspace.nil?

    workspace = client.workspaces.create(
      friendly_name: WORKSPACE_NAME,
      event_callback_url: event_callback_url
    )

    workspace.sid
  end

  def set_default_activity
    idle_activity_sid = activity_by_name('Idle').sid
    client.workspace.update(timeout_activity_sid: idle_activity_sid)
  end

  def create_workers
    bob_attributes = '{"products": ["ProgrammableSMS"], "contact_uri": "+593992670240"}'
    alice_attributes = '{"products": ["ProgrammableVoice"], "contact_uri": "+593987908027"}'

    create_worker('Bob', bob_attributes)
    create_worker('Alice', alice_attributes)
  end

  def create_worker(name, attributes)
    client.workspace.workers.create(
      friendly_name: name,
      attributes: attributes
    )
  end

  def activity_by_name(name)
    client.workspace.activities.list(friendly_name: name).first
  end

  def create_task_queues
    reservation_activity_sid = activity_by_name('Reserved').sid
    assignment_activity      = activity_by_name('Busy').sid

    voice_queue = client.workspace.task_queues.create(
      friendly_name: 'Voice',
      reservation_activity_sid: reservation_activity_sid,
      assignment_activity_sid: assignment_activity,
      target_workers: "products HAS 'ProgrammableVoice'"
    )
    sms_queue = client.workspace.task_queues.create(
      friendly_name: 'SMS',
      reservation_activity_sid: reservation_activity_sid,
      assignment_activity_sid: assignment_activity,
      target_workers: "products HAS 'ProgrammableSMS'"
    )
    all_queue = client.workspace.task_queues.create(
      friendly_name: 'All',
      reservation_activity_sid: reservation_activity_sid,
      assignment_activity_sid: assignment_activity,
      target_workers: "1 == 1"
    )

    { voice: voice_queue, sms: sms_queue, all: all_queue }
  end

  def workspace_sid
    @workspace_sid || 'no_workspace_yet'
  end
end
