require "rubygems"
require "bundler/setup"
require "newrelic_plugin"
require 'rabbitmq_manager'


module NewRelic
  module RabbitMQPlugin
    class Agent < NewRelic::Plugin::Agent::Base
      agent_guid 'com.redbubble.newrelic.plugin.rabbitmq'
      agent_version '1.1.1'
      agent_config_options :management_api_url, :server_name
      agent_human_labels('RabbitMQ') { server_name }

      def poll_cycle
        rmq_manager.queues.each do |queue|
          queue_name = queue['name'].split('queue.').last
          report_metric "Queue Size/#{queue_name}", 'messages', queue['messages']
        end

        report_metric 'Message Rate/Deliver', 'messages/sec', rate_for('deliver')
        report_metric 'Message Rate/Acknowledge', 'messages/sec', rate_for('ack')
        report_metric 'Message Rate/Return', 'messages/sec', rate_for('return_unroutable')

        report_metric 'Node/File Descriptors', 'file_descriptors', node_info('fd_used')
        report_metric 'Node/Sockets', 'sockets', node_info('sockets_used')
        report_metric 'Node/Erlang Processes', 'processes', node_info('proc_used')
        report_metric 'Node/Memory Used', 'bytes', node_info('mem_used')
      end

      private

      def rate_for(type)
        msg_stats = rmq_manager.overview['message_stats']

        if msg_stats.is_a?(Hash)
          details = msg_stats["#{type}_details"]
          details ? details['rate'] : 0
        else
          0
        end
      end

      def node_info(key)
        default_node_name = rmq_manager.overview['node']
        node = rmq_manager.node(default_node_name)
        node[key]
      end

      def rmq_manager
        @rmq_manager ||= ::RabbitMQManager.new(management_api_url)
      end
    end

    NewRelic::Plugin::Setup.install_agent :rabbitmq, self
    NewRelic::Plugin::Run.setup_and_run
  end
end
