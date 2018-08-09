# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

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

rsa_pem_key = """
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==
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
  missing_config_key: [
    signer_alg: "HS256"
  ],
  bad_algorithm: [
    signer_alg: "any algorithm",
    key_octet: "secret"
  ]
