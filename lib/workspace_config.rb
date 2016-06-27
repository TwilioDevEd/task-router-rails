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
    puts 'Configuring workspace...'
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
    create_workers
    queues = create_task_queues
    workflow_sid = create_workflow(queues).sid
    WorkspaceInfo.instance.workflow_sid = workflow_sid
    WorkspaceInfo.instance.post_work_activity_sid = activity_by_name('Idle').sid
  end

  private

  attr_reader :client, :account_sid, :auth_token

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
      event_callback_url: EVENT_CALLBACK_URL
    )

    workspace.sid
  end

  def create_workers
    bob_attributes = "{\"products\": [\"ProgrammableSMS\"], \"contact_uri\": \"#{BOB_NUMBER}\"}"
    alice_attributes = "{\"products\": [\"ProgrammableVoice\"], \"contact_uri\": \"#{ALICE_NUMBER}\"}"

    create_worker('Bob', bob_attributes)
    create_worker('Alice', alice_attributes)
  end

  def create_worker(name, attributes)
    client.workspace.workers.create(
      friendly_name: name,
      attributes: attributes,
      activity_sid: activity_by_name('Idle').sid
    )
  end

  def activity_by_name(name)
    client.workspace.activities.list(friendly_name: name).first
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
    client.workspace.task_queues.create(
      friendly_name: name,
      reservation_activity_sid: reservation_sid,
      assignment_activity_sid: assignment_sid,
      target_workers: target_workers
    )
  end

  def create_workflow(queues)
    default_rule_target = create_rule_target(queues[:all].sid, 1, QUEUE_TIMEOUT, '1==1')
    voice_rule_target   = create_rule_target(queues[:voice].sid, 5, QUEUE_TIMEOUT, nil)
    sms_rule_target     = create_rule_target(queues[:sms].sid, 5, QUEUE_TIMEOUT, nil)
    voice_rule = create_rule('selected_product=="ProgrammableVoice"',
                             [voice_rule_target, default_rule_target])
    sms_rule   = create_rule('selected_product=="ProgrammableSMS"',
                             [sms_rule_target, default_rule_target])

    rules = [voice_rule, sms_rule]
    config = Twilio::TaskRouter::WorkflowConfiguration.new(rules, default_rule_target)
    client.workspace.workflows.create(
      configuration: config.to_json,
      friendly_name: WORKFLOW_NAME,
      assignment_callback_url: ASSIGNMENT_CALLBACK_URL,
      fallback_assignment_callback_url: ASSIGNMENT_CALLBACK_URL,
      task_reservation_timeout: WORKFLOW_TIMEOUT
    )
  end

  def create_rule_target(queue_sid, priority, timeout, expression)
    Twilio::TaskRouter::WorkflowRuleTarget.new(queue_sid, priority, timeout,
                                               expression)
  end

  def create_rule(expression, targets)
    Twilio::TaskRouter::WorkflowRule.new(expression, targets)
  end

  def workspace_sid
    @workspace_sid || 'no_workspace_yet'
  end
end
