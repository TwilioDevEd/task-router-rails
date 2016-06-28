class WorkspaceInfo
  include Singleton

  attr_accessor(
    :workspace_sid,
    :workflow_sid,
    :post_work_activity_sid,
    :workers,
    :idle_activity_sid,
    :offline_activity_sid
  )
end
