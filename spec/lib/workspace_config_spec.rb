require 'rails_helper'
require 'vcr_helper'

RSpec.describe WorkspaceConfig do
  describe '#setup' do
    let(:workspace_info) { WorkspaceInfo.instance }

    it 'saves all the required workspace information after creation' do
      VCR.use_cassette('configure_workspace', record: :new_episodes, allow_playback_repeats: true) do
        described_class.setup

        expect(workspace_info.workspace_sid).to match(/^WS\w{32}$/)
        expect(workspace_info.workers.first[1][:sid]).to match(/^WK\w{32}$/)
        expect(workspace_info.workers.first(2)[0][1][:sid]).to match(/^WK\w{32}$/)
        expect(workspace_info.workflow_sid).to match(/^WW\w{32}$/)
        expect(workspace_info.post_work_activity_sid).to match(/^WA\w{32}$/)
        expect(workspace_info.idle_activity_sid).to match(/^WA\w{32}$/)
        expect(workspace_info.offline_activity_sid).to match(/^WA\w{32}$/)
      end
    end
  end
end
