defmodule Token do
  use Joken.Config
end

rsa_pem_key = """
-----BEGIN RSA PRIVATE KEY-----
MIIJKAIBAAKCAgEA42Ly+LsapY7raIdo1buGg0LX5SEArOjLHjkr8iOm+PO/GXEq
2SrAr+XTgVT3MRMmif16RFPrBWXvtwwaUkwo3S16URGxX/YdiHfT8If21hn9wkpi
OSvo7Z62wpquHSBoZyu9NxNM/wqvxD17GuYQBsyb6stGI9bir+GjORKLT1b5ayIf
UeUK5qaWhjXQoL/yI1ZeRL0DVR+72CKW7/v+LlHBvS1H1wpKy/dcMXxVzXqWutsf
g+fXT7SlwWyFH6MUr9RTTYf8Kc0Pv3siSxmbR897Sv4o9A2c82qet+2snuDuDKur
3fmsmfY9UqKxh4qPAWPuxFVegdE5Tgy8CJVJidffeTS6Fp71DNUhi9bzYoQi/mx3
wm9WUD9GHABSFiEa43V2mZwHcWtdS5CljWf3n0IO3Jxoww1ZOwn788PnJrKe8LES
KH0WujEWXvLBJnu+DUF7fG94/gsrQXS6EEBg1DpQMSnozsQyQVHqvuZ4KsZkplP5
I14pgf5uw/6BAcSlyCRbv6rIfo4BKr9bk1PvqHiog3uFg6yyPUNwwTUQHDstOYVD
1L06D10QpiznRG/h2doKtUGRHXvUv9z2OeAOFXTkS+g6cgX+KSvnwwwjbHofE4/p
OYe5r5owiWkQ0hTT+FcrDkN/PLaRa1Nr5Ezzzli2XeFVQeAzLQueutCqSAECAwEA
AQKCAgBT1CnhOxFy0cLF0Y37pdvMTntLdKRMGrKvXMJvzWcERtA/7/GtCE7rSh50
gr9y7y15F+LYh9uQLOl4IVUe3AcAq4B5nL04tIJkylBvT6DXg9OCqmuVyjNgTu/v
xJjGEimLR5vFTy9Go0jzXvsgioqEBzDAGdqs4c7GqrfDFawYPudK8NR9G6SuLeI2
bmaQrNL25iNw0gIFguJ8pxvgM5Wcu/Vh6eyfQaMbmQD7GWyEiVpCXwA6X+GH+ABX
08ssQ7IftHZVkfmL65aPsDSPXUxa6An7NsIgX1hqgPcstcm69Q+tyihdeGuCgz5O
Vb5/Sry39YCUDyj9UQYAWT+FJoxqO/gmBYu+fymzvzqE6eYJW7esJgqjUXawYppM
sTCB0yYEDryBvK2Iqft7cUhNwKvO5MdOf9oWWIeIgjis8leUiIVYf7MGiedwfMny
DW6G8GlEvllq2CYr0AP8PTqriv6lf21YDVye3HuGChJUcPpFd1jLys/duGGqHSWj
rrGsygF9Z6Jnr5MNHIB5iuwY1fSGAlNOvxjwLYdCAVeutvqnz8Bro/Wxk4HSnbM6
BlS38SL6uSBN4MBFkyOvxBbu/eFd5XDRpL7T+zFE9JhQletuWqBItOzivUo8UtrN
tNyIOPlyU4+/8PVjGUm38yaak60mXhMAL6YD21iJ6eV1WQR1wQKCAQEA/WtOQpw7
45Z1DAz/myPbe5KYszFWVumoaEA2HruPYX7eaJspC2hmcrRdltA+5m37C9TJTrSt
9llbPo2K9GdDfIyGuMOYeB5Gg8oKRqvx+BjdHnUehvPUe1GlW0r1m3DWWkc2cw7M
9fLnF7IOhsZjljuhNrEk/BRdV/n9ooS7D9AWWlT34frzeLvb3y7C/l2PgT9rhUjY
9uIfQrwF2s6XowUSpKiZj+7PcWHKkTu/jCI+01Man9qiFvgwVVn6ARFgvuTUSSDA
QXJbC/L9PA7S1j2eRgwTqcf/TAOKCSCmbFqmN6KGSyJSYTZA8GQXQJvZq7NuclfY
NOK1rbyCgsxISQKCAQEA5bPF7kBwHr5QfQ3ZkP/s5uw4W0CJssqecEU2zhx3DKmJ
mokQiQAKtikRcRxGidP8Fd2lq1dOKWfDdvNh3BIpNGC/NgKRiQt0yX0KVF3NWzMf
+NTfbu+FceNKmz3Tj+HMipKfHleYHRMW0pUDc1d6T4KCQ1Vm7VuGP4iBcSw/dl7s
l+aZJJBASydX42kYPEEH85e+xkYrDLPn9XpcMnnmN8F3Qxa8/fAjDX7HKc1LgWaq
7dlcjTK7puFBaSwjAAKBCc0rS6T/W+l6rOgI7vH7Qbdmlxlzci04A0DGCPTaV5nu
Sp06xhgQi2f5HmWgtptiuB9Rb5TD8JWGi6yCIRIx+QKCAQBfpEXvAcPgiwI1wBof
1RKauqMCzhYFyz2RytoiEytz4kvSMuz0rzwrAkNoDcQPd2aN+orXN32IQgUbwJO2
1do0gVy/EqLSgqqeRnxGW9KAjfG18wHIcPG6cP/1Sn8TYSyk+cdk+SsFj90DpmGx
H+Kp6mtXltecg5sO/vxof6uRtjkZcoPzN6D36f57ZsyU736fiu3raajo1EJ0Dz4u
bFXyYpG8rxz1o22LHxsyYNhT7QDFBNJBjmQqQxUKwWCHUqWupfIwfznP+Xa/Nb+5
EOclkC/Rw/EP3LlPWO6Zr0bgEf41dRM1/AgXRECR+VSFP8yQ7rE6Wkjw/LcQkNq4
vpxxAoIBAB5uBGidrLzF5Y/Lh+kHnnCxFn4wPI2s/fRNlwcTCkppI0uPoNslYEXl
huP/JPEZXinfZRUfycD+eAyIDYzD8yV3M52KFZGcLOqMYBPxIUVVroSeXsMpg/ok
bDvIowBKn3g0GFRCsmoXn0xiZUSgcBmcZnlZFPuYxl4gTVWa0QVzadBtwhfv7DSI
j8IWqBlDXDRPA/zsSsOyCaahgRlGwNLeFFiU6JCTgXFGPEgzZC9OVJKR2wrxj555
9Npj+HcF3eZYgcXRo+qfMZs6WgSdlfWMwFCAFKUpjGQR7qo9FbfJMqI71g9sHLT7
HyuBtxq51wghTf6ELLjwdhSG0+5hpLECggEBAKYv00+xYnUNk4SQZvMM9AWGFI1T
pQBGdbsGWTEiR+bGcuJnal5jXxHBgTklzwF5EIf/tvmSYPFzIrhUVPF8yExdJdFY
u2xp/FpLfopfzPjuVSR5hJJDFF7Ytglk1gdkXmkwDW9MJt4Tn4P9N9rRJAg2Gtmo
ZXHvpjGtL6OVum/Tski+yJUTOPwl8/k3h0xzCI5HodcAUSuO59Jhd6MLzTNHZoyx
eLG6hKpGZtX1SGteGnGAqqagt1Nz4mOC5ZrDObVihAz1ejq1xEwd2is0igdBZb7A
CSAnW8Md2j56RkvCnSPGab8eh5BjoGEInmSZWpUXvLJt91pZqX1jSbs1ZNg=
-----END RSA PRIVATE KEY-----
"""

alias Joken.Signer

rs_pem = %{"pem" => rsa_pem_key}

ec_secp256r1_pem = %{
  "pem" => """
  -----BEGIN EC PRIVATE KEY-----
  MHcCAQEEIIyckPcZt49eAjPk42NPXERvks9ip0OhnlR3SrqTtMByoAoGCCqGSM49
  AwEHoUQDQgAEUqRvGoqsFWsYpqrfiN8oPY37QokcUuD7BNWwzabIG6tSgM4vE2Pc
  m5iUiMHxt1IqE9EujI7ugFSfGQNTO5YBPw==
  -----END EC PRIVATE KEY-----
  """
}

ec_secp384r1_pem = %{
  "pem" => """
  -----BEGIN EC PRIVATE KEY-----
  MIGkAgEBBDClEvuZJ6xx4F6L+PW7tKGesCKTTRDk6D/3ykvS20mccAXC6XxgTjaa
  H4OqCckbCMegBwYFK4EEACKhZANiAAQFKIS07aeNieiYUFdLvwxOa1fiYwW6uzgZ
  YySFOER6gnLN1Mpdaiq6UPcqitUcq0slz6qyC612En3UURdRy6FCS3qBBKj224XP
  ZsQZGTBDzcnTqUHROYnB1RKkEpEKDcc=
  -----END EC PRIVATE KEY-----
  """
}

ec_secp521r1_pem = %{
  "pem" => """
  -----BEGIN EC PRIVATE KEY-----
  MIHcAgEBBEIAb0I6lo+mZh6zqq1671ZZoHvy/qN/McU3nsQknbZT/iS7pXwMBN+6
  bPyU0M5V6xScafodFOTI8AZfPjEDiLJK52GgBwYFK4EEACOhgYkDgYYABADHupB2
  0HD5cGO/VuwWMqBTmJ0xTmOfqHkQETelN87bsAkcByPT8VKAHvsllcDWG3uMPDci
  eWFrnO0YpRRkrxjdUAAYx0TPp6ng3Rv0pTS2bYt0wbCKhJ2M2asp6RBSCqV2HgmO
  +6Qq60uTtsSomnSimbOHfYvLgFpkFEcREAhjqpqM7w==
  -----END EC PRIVATE KEY-----
  """
}

Benchee.run(%{"Generate and sign" => &Token.generate_and_sign(%{}, &1)},
  inputs: %{
    # HS***
    "HS256 with JOSE" => Signer.create("HS256", "secret octal key", %{}, use_joken_crypto: false),
    "HS256 ohne JOSE" => Signer.create("HS256", "secret octal key", %{}, use_joken_crypto: true),
    "HS384 with JOSE" => Signer.create("HS384", "secret octal key", %{}, use_joken_crypto: false),
    "HS384 ohne JOSE" => Signer.create("HS384", "secret octal key", %{}, use_joken_crypto: true),
    "HS512 with JOSE" => Signer.create("HS512", "secret octal key", %{}, use_joken_crypto: false),
    "HS512 ohne JOSE" => Signer.create("HS512", "secret octal key", %{}, use_joken_crypto: true),

    # RS***
    "RS256 with JOSE" => Signer.create("RS256", rs_pem, %{}, use_joken_crypto: false),
    "RS256 ohne JOSE" => Signer.create("RS256", rs_pem, %{}, use_joken_crypto: true),
    "RS384 with JOSE" => Signer.create("RS384", rs_pem, %{}, use_joken_crypto: false),
    "RS384 ohne JOSE" => Signer.create("RS384", rs_pem, %{}, use_joken_crypto: true),
    "RS512 with JOSE" => Signer.create("RS512", rs_pem, %{}, use_joken_crypto: false),
    "RS512 ohne JOSE" => Signer.create("RS512", rs_pem, %{}, use_joken_crypto: true),

    # ES***
    "ES256 with JOSE" => Signer.create("ES256", ec_secp256r1_pem, %{}, use_joken_crypto: false),
    "ES256 ohne JOSE" => Signer.create("ES256", ec_secp256r1_pem, %{}, use_joken_crypto: true),
    "ES384 with JOSE" => Signer.create("ES384", ec_secp384r1_pem, %{}, use_joken_crypto: false),
    "ES384 ohne JOSE" => Signer.create("ES384", ec_secp384r1_pem, %{}, use_joken_crypto: true),
    "ES512 with JOSE" => Signer.create("ES512", ec_secp521r1_pem, %{}, use_joken_crypto: false),
    "ES512 ohne JOSE" => Signer.create("ES512", ec_secp521r1_pem, %{}, use_joken_crypto: true),

    # PS***
    "PS256 with JOSE" => Signer.create("PS256", rs_pem, %{}, use_joken_crypto: false),
    "PS256 ohne JOSE" => Signer.create("PS256", rs_pem, %{}, use_joken_crypto: true),
    "PS384 with JOSE" => Signer.create("PS384", rs_pem, %{}, use_joken_crypto: false),
    "PS384 ohne JOSE" => Signer.create("PS384", rs_pem, %{}, use_joken_crypto: true),
    "PS512 with JOSE" => Signer.create("PS512", rs_pem, %{}, use_joken_crypto: false),
    "PS512 ohne JOSE" => Signer.create("PS512", rs_pem, %{}, use_joken_crypto: true)
  }
)
