# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

rsa_map_key = %{
  "d" =>
    "A2gHIUmJOzRGvklIA2S8wWayCXnF8NYAhOhu7woSwjioO3HRzvd3ptegSKDpPfABJuzhy7y08ug5ZcyFbN1hJBVY8NwNzpLSUK9wmXekrbTG9MT76NAiQTxV6fYK5DXPF4Cp0qghBt-tq0kQNKx4q9QEzLb9XonmXE2a10U8EWJIs972SFGhxKzf6aq6Ri7UDK607ngQyEhVmGxr3gDJLAGQ5wOap5NYIL2ufI5FYqH-Sby_Qk7299b-w4B0fl6u8isR8OlpwMLVnD-oqOBPH-65tE82hxPV0QbSmyzmg9hlVVinJ82YRBkbcu-XG9XXOhUqJJ7kafQrYkQx6BiFKQ",
  "dp" =>
    "Useg361ca8Aem1TToW8AfjOLAAEqkkR48UPMSS2Le9D4YFtAb_ud5CK2IevYl0R-4afXUzIoeiNRg4bOTAWmTwKKlmAp4B5GzlbPzAPhwQRCxzs5MiW0K-Nw30blBLWlJYDAnVEr3T3rqtgzXFLMhR5AHqM4VhWQK7QaxgaW7TE",
  "dq" =>
    "yueW-DmyJULJlJckFXfkivSO_X1sjQurDwDfyFLAnrvgy2EqJ-iq0gBVySMGw2CgeSQegTmuKinF4anL0wy85BK8tgxDULVOpjls4ej8ZQnJ2RVEjdxZLjKh-2yw-v6mbn7goko98nkRCBYMdDUBHNVcaY9bA8kdBWi-K6DgW2E",
  "e" => "AQAB",
  "kty" => "RSA",
  "n" =>
    "xnAUUvtW3ftv25jCB-hePVCnhROqH2PACVGoCybdtMYTl8qVABAR0d6T-BRzVhJzz0-UvBNFUQyVvKAFxtbQUZN2JgAm08UJrDQszqz5tTzodWexODdPuoCaWaWge_MZGhz5PwWd7Jc4bPAu0QzSVFpBP3CovSjv48Z2Eq0_LHXVjjX_Az-WaUh94mXFyAxFI_oCygtT-il1-japS3cXJJh0WddT3VKEBRYHmxDJd_LYE-KXQt3aTDhq0vI9sG2ivtFj0dc3w_YBdr4hlcr42ujSP3wLTPpTjituwHQhYP4j-zqu7J3FYaIxU4lkK9Y_DP27RxffFI9YDPJdwFkNJw",
  "p" =>
    "5cMQg_4MrOnHI44xEs6Jyt_22DCvw3K-GY046Ls50vIf2KlRALHI65SPKfVFo5hUuHkBuWnQV46tHJU0dlmfg4svPMm_581r59yXeI8W6G4FlsSiVyhFO3P5Q5ubVs7MNaqhvaqqPqR14cVvHSqjwX5jGuGAVuLhnOhZGbtb7_U",
  "q" =>
    "3RlGNrCRU-yV7TTikKJVJCIpe8vgLBkHQ61iuICd8AyHa4sXICgf2YBFgW8CAJOHKIp8g_Nl94VYpqWvN1YVDB7sFUlRpJL2yXvTKxDzUwtM5pf_D1O6lGEMQBRY-buhZHmPf5qG93LnsSqm5YOZGpZ6t6gHtYM9A6JOIgwsYys",
  "qi" =>
    "kG5Stetls18_1fvQx8rxhX2Ais0Xg0gLDUjpE_9TYcb-utq79HVKOQ_2PJGz09hQ_teqnhXhgGMubqaktl6UOSJr6B4JgcAY7yU-34EuSxp8uKLix9BVsF2cpiC4ADhjLKP9c7IQ7X7zfs336_Reb8fh9G_zRdwEfmqFy7m28Lg"
}

rsa_public_pem_key = """
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA42Ly+LsapY7raIdo1buG
g0LX5SEArOjLHjkr8iOm+PO/GXEq2SrAr+XTgVT3MRMmif16RFPrBWXvtwwaUkwo
3S16URGxX/YdiHfT8If21hn9wkpiOSvo7Z62wpquHSBoZyu9NxNM/wqvxD17GuYQ
Bsyb6stGI9bir+GjORKLT1b5ayIfUeUK5qaWhjXQoL/yI1ZeRL0DVR+72CKW7/v+
LlHBvS1H1wpKy/dcMXxVzXqWutsfg+fXT7SlwWyFH6MUr9RTTYf8Kc0Pv3siSxmb
R897Sv4o9A2c82qet+2snuDuDKur3fmsmfY9UqKxh4qPAWPuxFVegdE5Tgy8CJVJ
idffeTS6Fp71DNUhi9bzYoQi/mx3wm9WUD9GHABSFiEa43V2mZwHcWtdS5CljWf3
n0IO3Jxoww1ZOwn788PnJrKe8LESKH0WujEWXvLBJnu+DUF7fG94/gsrQXS6EEBg
1DpQMSnozsQyQVHqvuZ4KsZkplP5I14pgf5uw/6BAcSlyCRbv6rIfo4BKr9bk1Pv
qHiog3uFg6yyPUNwwTUQHDstOYVD1L06D10QpiznRG/h2doKtUGRHXvUv9z2OeAO
FXTkS+g6cgX+KSvnwwwjbHofE4/pOYe5r5owiWkQ0hTT+FcrDkN/PLaRa1Nr5Ezz
zli2XeFVQeAzLQueutCqSAECAwEAAQ==
-----END PUBLIC KEY-----
"""

rsa_pem_key = """
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
"""

config :joken,
  current_time_adapter: Joken.CurrentTime.Mock,
  default_signer: "s3cr3t",
  hs256: [
    signer_alg: "HS256",
    key_octet: "test"
  ],
  hs384: [
    signer_alg: "HS384",
    key_octet: "test"
  ],
  hs512: [
    signer_alg: "HS512",
    key_octet: "test"
  ],
  rs256: [
    signer_alg: "RS256",
    key_map: rsa_map_key
  ],
  rs384: [
    signer_alg: "RS384",
    key_map: rsa_map_key
  ],
  rs512: [
    signer_alg: "RS512",
    key_map: rsa_map_key
  ],
  pem_rs256: [
    signer_alg: "RS256",
    key_pem: rsa_pem_key
  ],
  pem_rs384: [
    signer_alg: "RS384",
    key_pem: rsa_pem_key
  ],
  pem_rs512: [
    signer_alg: "RS512",
    key_pem: rsa_pem_key
  ],
  ed25519: [
    signer_alg: "Ed25519",
    key_openssh: """
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACB/qscCIU645l8xh1J5l5PQmB9IBiSPMmzFywW7bFl5LAAAAKjOwjJQzsIy
    UAAAAAtzc2gtZWQyNTUxOQAAACB/qscCIU645l8xh1J5l5PQmB9IBiSPMmzFywW7bFl5LA
    AAAEBCfc95wRP1nAlJY4ahZBMUs2iN3eiSp48aNqjTfdhQsX+qxwIhTrjmXzGHUnmXk9CY
    H0gGJI8ybMXLBbtsWXksAAAAI3ZpY3Rvcm9saW5hc2NAbG9jYWxob3N0LmxvY2FsZG9tYW
    luAQI=
    -----END OPENSSH PRIVATE KEY-----
    """
  ],
  public_pem: [
    signer_alg: "RS256",
    key_pem: rsa_public_pem_key
  ],
  with_key_id: [
    signer_alg: "HS256",
    key_octet: "secret",
    jose_extra_headers: %{"kid" => "my_key_id"}
  ],
  missing_config_key: [
    signer_alg: "HS256"
  ],
  bad_algorithm: [
    signer_alg: "any algorithm",
    key_octet: "secret"
  ]
