%{ for config in runners_machine_autoscaling ~}
[[runners.machine.autoscaling]]
    Periods = [${join(",", config.periods)}]
    IdleCount = ${config.idle_count}
    IdleTime = ${config.idle_time}
    Timezone = "${config.timezone}"
%{ endfor ~}
