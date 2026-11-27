# frozen_string_literal: true

require 'spec_helper'

describe 'zfsmgr' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('zfsmgr::install').that_comes_before('Class[zfsmgr::configure]') }
        it { is_expected.to contain_class('zfsmgr::configure').that_comes_before('Class[zfsmgr::service]') }
        it { is_expected.to contain_class('zfsmgr::service') }

        it do
          is_expected.to contain_package('zfs_mgmt').with(
            ensure: 'installed',
            provider: 'gem',
          )
        end

        it do
          is_expected.to contain_file('/etc/zfsmgr').with(
            ensure: 'directory',
            owner: 'root',
            group: 'root',
            mode: '0755',
            purge: false,
            recurse: false,
            force: false,
          )
        end

        it do
          is_expected.to contain_file('/var/lib/zfs_mgmt').with(
            ensure: 'directory',
            owner: 'root',
            group: 'root',
            mode: '0755',
          )
        end

        it { is_expected.to contain_zfsmgr__config('50-puppet') }

        it do
          is_expected.to contain_file('/etc/zfsmgr/50-puppet.toml').with(
            ensure: 'file',
            owner: 'root',
            group: 'root',
            mode: '0644',
            replace: true,
            content: "#:schema https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json\n# Managed by Puppet\n",
          )
        end

        it { is_expected.to contain_zfsmgr__config('99-local') }

        it do
          is_expected.to contain_file('/etc/zfsmgr/99-local.toml').with(
            ensure: 'file',
            owner: 'root',
            group: 'root',
            mode: '0644',
            replace: false,
            content: "#:schema https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json\n# Local zfsmgr configuration (not managed by Puppet)\n",
          )
        end

        it do
          is_expected.to contain_cron('zfsmgr-snapshot-destroy').with(
            ensure: 'present',
            command: 'PATH=/sbin:$PATH /usr/local/bin/zfsmgr snapshot destroy --loglevel warn --lock --lock-wait 43200',
            user: 'root',
            minute: 45,
            hour: '*/12',
            monthday: '*',
            month: '*',
            weekday: '*',
          )
        end

        it do
          is_expected.to contain_cron('zfsmgr-snapshot-create').with(
            ensure: 'present',
            command: 'PATH=/sbin:$PATH /usr/local/bin/zfsmgr snapshot create --loglevel warn --lock --lock-wait 14400',
            user: 'root',
            minute: 1,
            hour: '*/4',
            monthday: '*',
            month: '*',
            weekday: '*',
          )
        end

        it do
          is_expected.to contain_cron('zfsmgr-send-all').with(
            ensure: 'present',
            command: 'PATH=/sbin:$PATH /usr/local/bin/zfsmgr send all --loglevel info --lock --lock-wait 1440',
            user: 'root',
            minute: 57,
            hour: '*/4',
            monthday: '*',
            month: '*',
            weekday: '*',
          )
        end
      end

      context 'with config hash rendered to TOML' do
        let(:params) do
          {
            config: {
              'mbuffer' => true,
              'mbuffer_size' => '512M',
              'excludes' => %w[mountpoint sharenfs],
              'overrides' => {
                'canmount' => 'noauto',
              },
              'ssh_config' => {
                'Compression' => 'yes',
              },
              'zfs' => {
                'tank/data' => {
                  'manage' => true,
                  'policy' => '10y6m4w30d24h',
                  'destination' => 'zfs_recv@backup.example.com:backup/tank',
                  'overrides' => {
                    'canmount' => '**',
                  },
                  'ssh_config' => {
                    'ConnectTimeout' => '30',
                  },
                },
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it 'renders top-level and quoted dataset TOML tables in /etc/zfsmgr/50-puppet.toml' do
          content = catalogue.resource('file', '/etc/zfsmgr/50-puppet.toml')[:content]
          expect(content).to include('#:schema https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json')
          expect(content).to include('mbuffer = true')
          expect(content).to include('mbuffer_size = "512M"')
          expect(content).to include('excludes = ["mountpoint", "sharenfs"]')
          expect(content).to include("[overrides]\ncanmount = \"noauto\"")
          expect(content).to include("[ssh_config]\nCompression = \"yes\"")
          expect(content).to include('[zfs."tank/data"]')
          expect(content).to include('manage = true')
          expect(content).to include('policy = "10y6m4w30d24h"')
          expect(content).to include('destination = "zfs_recv@backup.example.com:backup/tank"')
          expect(content).to include('[zfs."tank/data".overrides]')
          expect(content).to include('[zfs."tank/data".ssh_config]')
        end
      end

      context 'with purge_config_dir => true' do
        let(:params) do
          {
            purge_config_dir: true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file('/etc/zfsmgr').with(
            purge: true,
            recurse: true,
            force: true,
          )
        end

        it do
          is_expected.to contain_file('/etc/zfsmgr/99-local.toml').with(
            ensure: 'file',
            replace: false,
          )
        end
      end

      context 'with manage_local_config => false' do
        let(:params) do
          {
            manage_local_config: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_zfsmgr__config('99-local') }
        it { is_expected.not_to contain_file('/etc/zfsmgr/99-local.toml') }
      end

      context 'with manage_package => false' do
        let(:params) do
          {
            manage_package: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('zfs_mgmt') }
      end

      context 'with custom package_ensure and package_provider' do
        let(:params) do
          {
            package_ensure: '0.8.1',
            package_provider: 'puppet_gem',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_package('zfs_mgmt').with(
            ensure: '0.8.1',
            provider: 'puppet_gem',
          )
        end
      end

      context 'with additional configs hash' do
        let(:params) do
          {
            configs: {
              '60-extra' => {
                'config' => {
                  'mbuffer' => false,
                },
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_zfsmgr__config('60-extra') }
        it { is_expected.to contain_file('/etc/zfsmgr/60-extra.toml') }
      end

      context 'with customized cron jobs' do
        let(:params) do
          {
            snapshot_create_cron: {
              'hour' => '*/2',
              'lock_file' => '/run/zfsmgr-create.lock',
              'extra_args' => '--filter ^tank/',
            },
            snapshot_destroy_cron: {
              'lock' => false,
            },
            send_all_cron: {
              'ensure' => 'absent',
            },
            cron_path: '',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_cron('zfsmgr-snapshot-create').with(
            ensure: 'present',
            hour: '*/2',
            minute: 1,
            command: '/usr/local/bin/zfsmgr snapshot create --loglevel warn --lock --lock-file /run/zfsmgr-create.lock --lock-wait 14400 --filter ^tank/',
          )
        end

        it do
          is_expected.to contain_cron('zfsmgr-snapshot-destroy').with(
            ensure: 'present',
            command: '/usr/local/bin/zfsmgr snapshot destroy --loglevel warn',
          )
        end

        it { is_expected.to contain_cron('zfsmgr-send-all').with(ensure: 'absent') }
      end

      context 'with manage_cron => false' do
        let(:params) do
          {
            manage_cron: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_cron('zfsmgr-snapshot-destroy') }
        it { is_expected.not_to contain_cron('zfsmgr-snapshot-create') }
        it { is_expected.not_to contain_cron('zfsmgr-send-all') }
      end
    end
  end
end
