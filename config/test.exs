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

# generated with openssl genrsa -aes256 4096
rsa_encrypted_passphrase = "passphrase"
rsa_encrypted_pem_key = """
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-256-CBC,B07A62A211BBA625EA114A6121DF1230

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
  pem_encrypted_rs256: [
    signer_alg: "RS256",
    key_pem: rsa_encrypted_pem_key,
    passphrase: rsa_encrypted_passphrase
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
