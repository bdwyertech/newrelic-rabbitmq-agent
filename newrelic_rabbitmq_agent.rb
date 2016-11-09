#!/usr/bin/env ruby
# rubocop: disable LineLength
require 'rubygems'
require 'bundler/setup'
require 'newrelic_plugin'
require 'rabbitmq_manager'

module NewRelic
  module RabbitMQPlugin
    class Agent < NewRelic::Plugin::Agent::Base
      agent_guid 'com.redbubble.newrelic.plugin.rabbitmq'
      agent_version '1.1.1'
      agent_config_options :management_api_url, :server_name, :verify_ssl
      agent_human_labels('RabbitMQ') { server_name }

      def poll_cycle
        # => This version is meant for a consumer view only, not an admin view.
        rmq_manager.queues.each do |queue|
          queue_name = queue['name'].split('queue.').last
          # => Add queue filter for shared rabbit server.

          report_metric "Queue Size/#{queue_name}", 'Queues', queue['messages']

          report_metric "Message Rate/Deliver/#{queue_name}", 'messages/sec', per_queue_rate_for('deliver', queue)
          report_metric "Message Rate/Acknowledge/#{queue_name}", 'messages/sec', per_queue_rate_for('ack', queue)
          report_metric "Message Rate/Return/#{queue_name}", 'messages/sec', per_queue_rate_for('return_unroutable', queue)
        end
      end

      private

      def per_queue_rate_for(type, queue)
        msg_stats = queue['message_stats']

        if msg_stats.is_a?(Hash)
          details = msg_stats["#{type}_details"]
          details ? details['rate'] : 0
        else
          0
        end
      end

      def rate_for(type)
        msg_stats = rmq_manager.overview['message_stats']

        if msg_stats.is_a?(Hash)
          details = msg_stats["#{type}_details"]
          details ? details['rate'] : 0
        else
          0
        end
      end

      def rmq_manager
        @rmq_manager ||= ::RabbitMQManager.new(management_api_url, verify: verify_ssl)
      end
    end

    NewRelic::Plugin::Setup.install_agent :rabbitmq, self
    NewRelic::Plugin::Run.setup_and_run
  end
end
