# frozen_string_literal: true

require 'spec_helper'

describe 'zfsmgr::config' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with a stem title and config hash' do
        let(:title) { '60-backup' }
        let(:params) do
          {
            config: {
              'zfs' => {
                'tank/backup' => {
                  'send' => true,
                  'destination' => 'backup/tank',
                },
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file('/etc/zfsmgr/60-backup.toml').with(
            ensure: 'file',
            owner: 'root',
            group: 'root',
            mode: '0644',
            replace: true,
          ).that_requires('File[/etc/zfsmgr]')
        end

        it 'renders TOML with schema header' do
          content = catalogue.resource('file', '/etc/zfsmgr/60-backup.toml')[:content]
          expect(content).to include('#:schema https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json')
          expect(content).to include('[zfs."tank/backup"]')
          expect(content).to include('send = true')
          expect(content).to include('destination = "backup/tank"')
        end
      end

      context 'when title already ends with .toml' do
        let(:title) { '60-backup.toml' }
        let(:params) do
          {
            config: {
              'mbuffer' => false,
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/zfsmgr/60-backup.toml') }
        it { is_expected.not_to contain_file('/etc/zfsmgr/60-backup.toml.toml') }
      end

      context 'with raw content and replace => false' do
        let(:title) { '70-custom' }
        let(:params) do
          {
            content: "# custom content\nmbuffer = false\n",
            replace: false,
            owner: 'bin',
            group: 'bin',
            mode: '0640',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file('/etc/zfsmgr/70-custom.toml').with(
            ensure: 'file',
            owner: 'bin',
            group: 'bin',
            mode: '0640',
            replace: false,
            content: "# custom content\nmbuffer = false\n",
          )
        end
      end

      context 'with include_schema_comment => false' do
        let(:title) { '65-noschema' }
        let(:params) do
          {
            include_schema_comment: false,
            config: {
              'mbuffer' => true,
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/zfsmgr/65-noschema.toml') }

        it 'omits the schema header' do
          content = catalogue.resource('file', '/etc/zfsmgr/65-noschema.toml')[:content]
          expect(content).not_to include('#:schema')
          expect(content).to include('mbuffer = true')
        end
      end

      context 'with ensure => absent' do
        let(:title) { '60-removed' }
        let(:params) do
          {
            ensure: 'absent',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/zfsmgr/60-removed.toml').with(ensure: 'absent') }
      end

      context 'when both config and content are provided' do
        let(:title) { 'invalid' }
        let(:params) do
          {
            config: { 'mbuffer' => true },
            content: "mbuffer = true\n",
          }
        end

        it { is_expected.to compile.and_raise_error(%r{mutually exclusive}) }
      end
    end
  end
end
