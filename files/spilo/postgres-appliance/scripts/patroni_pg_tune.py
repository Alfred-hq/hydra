import subprocess
import yaml

# Run timescaledb-tune command and capture the output
command = "timescaledb-tune --yes --dry-run"
output = subprocess.check_output(command, shell=True, text=True)

def is_a_postgres_configuration(line: any):
    if '=' in line:
        return True
    else:
        return False

sanitized_configurations = list(filter(is_a_postgres_configuration, output.split('\n')))

print("Output of timescaledb-tune command:")
print(sanitized_configurations)
print("\n")

# Process the recommended items and create a dictionary
recommended_settings = {}

for config in sanitized_configurations:
    key, value = config.split('=')
    recommended_settings[key.strip()] = value.strip()

recommended_settings.pop("max_connections", "")
recommended_settings.pop("max_replication_slots", "")
recommended_settings.pop("archive_command", "")
recommended_settings.pop("archive_mode", "")
recommended_settings.pop("max_wal_senders", "")
recommended_settings.pop("wal_compression", "")
recommended_settings.pop("log_connections", "")
recommended_settings.pop("log_disconnections", "")


with open('spilo.yaml', 'r') as yaml_file:
    patroni_config = yaml.safe_load(yaml_file)


if "shared_buffers" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("shared_buffers", "")

if "effective_cache_size" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("effective_cache_size", "")

if "maintenance_work_mem" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("maintenance_work_mem", "")

if "checkpoint_completion_target" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("checkpoint_completion_target", "")

if "wal_buffers" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("wal_buffers", "")

if "default_statistics_target" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("default_statistics_target", "")

if "random_page_cost" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("random_page_cost", "")

if "effective_io_concurrency" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("effective_io_concurrency", "")

if "work_mem" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("work_mem", "")

if "min_wal_size" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("min_wal_size", "")

if "max_wal_size" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("max_wal_size", "")

if "shared_preload_libraries" in patroni_config["postgresql"]["parameters"]:
    recommended_settings.pop("shared_preload_libraries", "")

patroni_config["postgresql"]["parameters"].update(recommended_settings)

# Print the formatted YAML output
print("Structured YAML representation of recommended settings:")
print(patroni_config)

with open('spilo_tuned.yaml', 'w') as yaml_file:
    yaml.dump(patroni_config, yaml_file, default_flow_style=False)
