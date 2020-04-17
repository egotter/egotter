# db_config = Rails.configuration.database_configuration[Rails.env]
#
# influxdb = InfluxDB::Client.new
# influxdb.create_retention_policy('a_year', db_config['database'], '52w', 1)
# influxdb.create_database(db_config['database'])
# influxdb.send(:execute, "create database #{db_config['database']} with duration 156w") # 3 years
# influxdb.create_database_user(db_config['database'], db_config['username'], db_config['password'])
#
# influxdb.list_databases
# influxdb.list_users
# influxdb.list_retention_policies(database)
#