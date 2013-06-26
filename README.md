## Newrelic RabbitMQ Agent Install

## Requirements
* Ruby 1.9 with bundler installed
* RabbitMQ with [management plugins](http://www.rabbitmq.com/management.html) enabled.  This is much easier from 2.8 onwards.
* git installed on the target machine
* HTTP access from target machine to RabbitMQ installation (we installed the agent on the same machine)

## Installation
* Clone this project into a directory on the target machine. We like /data/newrelic-rabbitmq-agent
* Copy 'template-newrelic-plugin.yml' to 'newrelic-plugin.yml'
* Replace YOUR_LICENCE_KEY_HERE with your newrelic licence key and SERVER_NAME_HERE with the name you'd like to see in your NewRelic dashboard.
* Adjust the management_api_url setting if you're using a different port (RabbitMQ 3.0 uses port 15672) or authentication details.  You can check the management agent is running by issuing a curl -i 'management_api_url' if you're having problems.  Note that the management API requires erlang R14A.
* In your chosen directory run
  $ bundle install
  $ ./newrelic-rabbitmq-agent start


## Hardening the installation
We like things to run by themselves so create a monit script to ensure the agent is always up and running:
```
check process newrelic_rabbitmq_agent
  with pidfile /var/run/newrelic-rabbitmq-agent.pid
  start program = "/data/newrelic-rabbitmq-agent/newrelic-rabbitmq-agent start" as uid <youruser> gid <usergroup>
  stop program = "/data/newrelic-rabbitmq-agent/newrelic-rabbitmq-agent stop" as uid <youruser> gid <usergroup>
```

Update the <youruser> and <usergroup> tokens with the user you'd like the agent to run as.  You may also need to update the pid and installation paths for your local environment, the pid path is also defined in the newrelic-rabbitmq-agent script.