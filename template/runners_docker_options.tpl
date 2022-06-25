disable_cache = %{if disable_cache != null} ${disable_cache} %{else} false %{endif}
image         = %{if image != null} ${image} %{else} "docker:18.03.1-ce" %{endif}
privileged    = %{if privileged != null} ${privileged} %{else} true %{endif}
pull_policy   = %{if pull_policy != null} ${pull_policy} %{else} "always" %{endif}
shm_size      = %{if shm_size != null} ${shm_size} %{else} 0 %{endif}
tls_verify    = %{if tls_verify != null} ${tls_verify} %{else} false %{endif}
volumes       = %{if volumes != null} [${volumes}] %{else} ["/cache"] %{endif}