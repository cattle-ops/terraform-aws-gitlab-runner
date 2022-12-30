%{ for config in runners_docker_services ~}
[[runners.docker.services]]
      name = "${config.name}"
      alias = "${config.alias}"
      entrypoint = [${replace(format("\"%s\"", join("\",\"", config.entrypoint)), "/\"{2,}/", "\"")}]
      command = [${replace(format("\"%s\"", join("\",\"", config.command)), "/\"{2,}/", "\"")}]
%{ endfor ~}
