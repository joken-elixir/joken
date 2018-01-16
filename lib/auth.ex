defmodule DefaultAuth do
  use Joken2.Config
end

defmodule RSAuth do
  use Joken2.Config, default_key: :pem_rs256
end