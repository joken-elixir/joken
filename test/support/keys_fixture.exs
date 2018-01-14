defmodule Joken.Fixtures do
  import Joken

  def payload do
    %{name: "John Doe"}
  end

  def token_config do
    payload()
    |> token()
    |> with_validation("name", &(&1 == "John Doe"))
  end

  # key taken from Appendix A.2.3 of JWE (Json Web Encryption) RFC
  # http://tools.ietf.org/html/rfc7516#appendix-A.2.3
  def rsa_key2 do
    %{
      "kty" => "RSA",
      "n" =>
        "sXchDaQebHnPiGvyDOAT4saGEUetSyo9MKLOoWFsueri23bOdgWp4Dy1WlUzewbgBHod5pcM9H95GQRV3JDXboIRROSBigeC5yjU1hGzHHyXss8UDprecbAYxknTcQkhslANGRUZmdTOQ5qTRsLAt6BTYuyvVRdhS8exSZEy_c4gs_7svlJJQ4H9_NxsiIoLwAEk7-Q3UXERGYw_75IDrGA84-lA_-Ct4eTlXHBIY2EaV7t7LjJaynVJCpkv4LKjTTAumiGUIuQhrNhZLuF_RJLqHpM2kgWFLU7-VTdL1VbC2tejvcI2BlMkEpk1BzBZI0KQB0GaDWFLN-aEAw3vRw",
      "e" => "AQAB",
      "d" =>
        "VFCWOqXr8nvZNyaaJLXdnNPXZKRaWCjkU5Q2egQQpTBMwhprMzWzpR8Sxq1OPThh_J6MUD8Z35wky9b8eEO0pwNS8xlh1lOFRRBoNqDIKVOku0aZb-rynq8cxjDTLZQ6Fz7jSjR1Klop-YKaUHc9GsEofQqYruPhzSA-QgajZGPbE_0ZaVDJHfyd7UUBUKunFMScbflYAAOYJqVIVwaYR5zWEEceUjNnTNo_CVSj-VvXLO5VZfCUAVLgW4dpf1SrtZjSt34YLsRarSb127reG_DUwg9Ch-KyvjT1SkHgUWRVGcyly7uvVGRSDwsXypdrNinPA4jlhoNdizK2zF2CWQ",
      "p" =>
        "9gY2w6I6S6L0juEKsbeDAwpd9WMfgqFoeA9vEyEUuk4kLwBKcoe1x4HG68ik918hdDSE9vDQSccA3xXHOAFOPJ8R9EeIAbTi1VwBYnbTp87X-xcPWlEPkrdoUKW60tgs1aNd_Nnc9LEVVPMS390zbFxt8TN_biaBgelNgbC95sM",
      "q" =>
        "uKlCKvKv_ZJMVcdIs5vVSU_6cPtYI1ljWytExV_skstvRSNi9r66jdd9-yBhVfuG4shsp2j7rGnIio901RBeHo6TPKWVVykPu1iYhQXw1jIABfw-MVsN-3bQ76WLdt2SDxsHs7q7zPyUyHXmps7ycZ5c72wGkUwNOjYelmkiNS0",
      "dp" =>
        "w0kZbV63cVRvVX6yk3C8cMxo2qCM4Y8nsq1lmMSYhG4EcL6FWbX5h9yuvngs4iLEFk6eALoUS4vIWEwcL4txw9LsWH_zKI-hwoReoP77cOdSL4AVcraHawlkpyd2TWjE5evgbhWtOxnZee3cXJBkAi64Ik6jZxbvk-RR3pEhnCs",
      "dq" =>
        "o_8V14SezckO6CNLKs_btPdFiO9_kC1DsuUTd2LAfIIVeMZ7jn1Gus_Ff7B7IVx3p5KuBGOVF8L-qifLb6nQnLysgHDh132NDioZkhH7mI7hPG-PYE_odApKdnqECHWw0J-F0JWnUd6D2B_1TvF9mXA2Qx-iGYn8OVV1Bsmp6qU",
      "qi" =>
        "eNho5yRBEBxhGBtQRww9QirZsB66TrfFReG_CcteI1aCneT0ELGhYlRlCtUkTRclIfuEPmNsNDPbLoLqqCVznFbvdB7x-Tl-m0l_eFTj2KiqwGqE9PZB9nNTwMVvH3VRRSLWACvPnSiwP8N5Usy-WRXS-V7TbpxIhvepTfE0NNo"
    }
  end

  def rsa_key do
    %{
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
  end

  def ec_p256_key do
    %{
      "crv" => "P-256",
      "d" => "aJhYDBNS-5yrH97PAExzWNLlJGqJwFGZmv7iJvdG4p0",
      "kty" => "EC",
      "x" => "LksdLpZN3ijcn_TBfRK-_tgmvws0c5_V5k0bg14RLhU",
      "y" => "ukc-JOEAWhW664SY5Q29xHlAVEDlrQwYF3-vQ_cdi1s"
    }
  end

  def ec_p384_key do
    %{
      "crv" => "P-384",
      "d" => "-iM1VuECCos2kAvvSXSsEGL-_A9-DIc4l8Z297xfSMSxiHJMYdyVMNRxHBmoJ__0",
      "kty" => "EC",
      "x" => "HgI0kaSfi-MJLcO5eP3OvLwO6pHYxiP4q-qnzqk5-TwR8MO9FweSRMpxWb-1buPZ",
      "y" => "EdONZTBTmoT_c0R7_kSW6y_VaCgB_k2iNMlARR2xqFzVS5ADkyFtCEMgOS5JmZuA"
    }
  end

  def ec_p521_key do
    %{
      "crv" => "P-521",
      "d" =>
        "ADa5GfibXsE1DcceEmsTB99lVG2cakh247L77aa1_K9OZrlYzCIhx-HVVzwJ-KDYPOIU9q2Up8D8H-EXM_6EOYzJ",
      "kty" => "EC",
      "x" =>
        "ANrII7yaoz0vcvYKSXg404CebQYn0-GXIBvtc3hJFh-ubu8_mdIR6_B3pa3FC_CbHZnYcSxYeRaWmDjZmWqnWsgg",
      "y" =>
        "AH0EUWVaoVROX3_OzzQIZLuKG5546exe5-0cQ-E7thMaH6-k5cqcyIedCuX1c9lOWcXgo2NLlj4JOwSetCpOspEM"
    }
  end

  def ed25519_key do
    %{
      "crv" => "Ed25519",
      "d" => "VoU6Pm8SOjz8ummuRPsvoJQOPI3cjsdMfUhf2AAEc7s",
      "kty" => "OKP",
      "x" => "l11mBSuP-XxI0KoSG7YEWRp4GWm7dKMOPkItJy2tlMM"
    }
  end

  def ed25519ph_key do
    %{
      "crv" => "Ed25519ph",
      "d" => "D8PU55JCryvSLK44AaCcAYj99P2MDQdxmNJhTUhFqTA",
      "kty" => "OKP",
      "x" => "JnLdiNg-GBTQjukBZUPinl56Au_kF58adtqtzrXnZTs"
    }
  end

  def ed448_key do
    %{
      "crv" => "Ed448",
      "d" => "-ox5cBHY-QLR0hRdE2gd97LkQ8oRZCT89ALXm-FqhINLdVEd_PtfHuetZoKeHALqwu-NfuADYDBL",
      "kty" => "OKP",
      "x" => "BnJNZy1_JXpGRlrNLYsz_9I5NCM-Py39P1kEOyrLRXJj38rnOJe7cJaVsOnPj2NkL_jVtG_qkjOA"
    }
  end

  def ed448ph_key do
    %{
      "crv" => "Ed448ph",
      "d" => "1AlVWjtG0cTvUSQrqgXHqYTBP07FljGGvO5SZhAgtt92NTBcuTs_HedSqvikyHhhcsE4PsTHXBx0",
      "kty" => "OKP",
      "x" => "pqCS-juwmDl_-uZhliMmaZNssMukorRdQcqC8Nu44uYyBDgpkc_i-Ir1rYjPzLOlNHEGyb0dIN-A"
    }
  end

  def ed25519_token do
    "eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiSldUIn0.eyJuYW1lIjoiSm9obiBEb2UifQ.9a7z_qCuHwBMVSOG9sDzc2Ccbk49tY2GLddqViz0nuB4zG9pQS-jhhGpkYwQ9LE33742__nujzWLaSJ93tYhAw"
  end

  def ed25519ph_token do
    "eyJhbGciOiJFZDI1NTE5cGgiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiSm9obiBEb2UifQ.VRTZ7LyOmmPTn382rK6vP4VMYYBiQGz6i-Hpf8IB5flmcBavDmLqed8Q-h9uRlSRCTkemIBDpqKE-7zj9RlgBw"
  end

  def ed448_token do
    "eyJhbGciOiJFZDQ0OCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.8eVjWUndsxWOzJMRQn5BqFJDMrcIj950zmKdSkXH2NBSCRETJD0YFA3HocSiWOgswHKZXIcYeT0AFc1JjH3LGl_oREiotTuU20b8USt3Z81VzqmMG2fvx5QlwKlZwwk4A2V5F2X-d1Ky0z1VV1PovjcA"
  end

  def ed448ph_token do
    "eyJhbGciOiJFZDQ0OHBoIiwidHlwIjoiSldUIn0.eyJuYW1lIjoiSm9obiBEb2UifQ.T4PiW8b_l0XqEI3NLXHFvHUifD0SpNNLpMwLbT-QuLE03FZ105Voyeh7uB87WxbSwWuZOyZfPQ6Az4N41A2oRsoTS7v9jeqizIP240vve3VB7sLs6zl9Vgb4nH6k0jvQUMKPBw7Mf6KbPN1a_rumIj0A"
  end

  def es256_token do
    "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ozw2CHDqSE1t5CXXP50x52tr07Nj7HGSBWGytDj93gcHxS65TJ6Tv0RrOei-WtauDN3beXF5e7lZ8c5MPwx0-w"
  end

  def es384_token do
    "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.H1Y9Z3hhYff4kIWt6b1F-S1hNP74DRqYH9Jg41sJTitKC4wmYEAfKkQk6O7Z5nReL-4bhL2TZwl-rutG2tadVSUePeGlYR0AIiBCgJGf9dZPfYYF-toJ37wefKz0Cq78"
  end

  def es512_token do
    "eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ASkU80v3zU8Qa0Xdz3fJTkwRn5yEoYIUpEp4R7IH8iEEq1AJqhJv7VLSrACfiC8TdooBsa2qitA7qCOF12XgpHQzAJCvs1ryhEwmgnB3a5_aNW-5_s3REmAvmaA587Au0C-vBlRFvymrYRAITUN0Vb9z0giBAu82GcEaRuTvXblYeQXz"
  end

  def hs256_token do
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ"
  end

  def hs384_token do
    "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k"
  end

  def hs512_token do
    "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg"
  end

  def ps256_token do
    "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ku7tPc7imjD49cf2iL2KKOWd9pWSM8MYIa3lIkx8FV0uZEgukCx5yzWl20tpozLkvp_jeW_-9n2jy-Htm8Acj2Gj4zc-DhHajS01RD5Q341cQ4TS5UFZqO6BkACPXlPAPIlFCRliU2IZkSCVUsr73BaiXZ0kGpa6RZ0EWmIa0zOA6eMODDujtifoBntpxjEceFZZZux3Z7tts0-GZw4Qob952IjFdtVHqpmBGXz3v0paJ5fqCWjO7_tMqfdg7LDGXYsgkUxKyuPMjuctCtgNpKQsQZx0K4sTq7aVitQFpVUH2byyidX33xw2FvVqGFPccHCiq52sVZjUqjeKADcJhQ"
  end

  def ps384_token do
    "eyJhbGciOiJQUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.QhUlNiQ1oRFqVcgr36Tp7O3PzvZ6P0quyE9DWMFmMR2lmwW6Qh07tlS4Lre_V2zA9EsWb4Z4UPNLlugizgZyDbomW7DEZGsmMs39XP7kS0WPOPkK_JGZmRCJEvA6K038KSwWhgdgfTn_ZzwnEQutkF3OkgyMR6vbhSx60eJgh9EqVVoXQzZ9amiYszKpJYQqGgs_MNtzAS6UkurLeaL_w1CYEJGtPuepKg2mDX9DKFMrEJCeNI7Zj6f8b3_CSw7VdoMZRxAbcGMa7imRrf1b-ONCaEpO8UWGkUURtmEr4PllHpBPRn8eg7TaHK1WwM7VrPWDjiDOr7gIi3XJpik4BA"
  end

  def ps512_token do
    "eyJhbGciOiJQUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.sb3d4pgZD8-LxVwgTo-rS1PQmjzQhfrXyRg6FWMKWGGltKlpnuySVDPHywZCmYFEOyT4KSk17Xx7E1L6256Q4KO320zMB6Uh7HpFhCbsvSsI0Xlybypbx0oJO7H4g5MypyF4WkEmbxGA64vltZobVCL2bxg7uLfNtngwmyUA8yzeXZwNhpdfB6ajhpY1JIp5D6bv8630QANCSI2mabvsaMW2pjvAQOYPZZTzN5Z8JZVvzTxyr0yheApB6KkW58zDyGbYf7wH0aeaL16tnDpdC5ZX3ddwMDYtUDEp_5nFy1bFIKa0jFWTnoyL0AYwtsO8ag2l9L4Q7fs0OdjAD1qgrg"
  end

  def rs256_token do
    "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ"
  end

  def rs384_token do
    "eyJhbGciOiJSUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.XpXgnjgYH-SIQMPg8xnNXXG5RV6CQhWajHoJbf44_fT70ZbpVDSeQopNXjQg3ClFDdbTbyGeR-cCfgr1xMqdWWpbmuCn13CS9-918WD0fENkrDMb_ErFyft0XiWTLeQlW_BaLP0-sqAfY8-XsiDMbClP2hgAdyV9iA-aFJ2S5HVKI_j68WmjcvwNGPNJcfhTEpx0mMroBj1qNBRNS5p94L-QRieZgtbs5ikrn7OAo5NME6DGtrDLd1deeN84r3nGTqQODiK22o-LSjnpWHKw0iXjQymFrnnd7B_IgYiWu7X4ZPmUy_wMSYT9O8k00sfE_VRVV5Uq2qlNpCYWv9LlLA"
  end

  def rs512_token do
    "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.aw9j2S7aqohX_dGWJYrA1btgQE46Dtiy-7S9J70-k_Tm2ElepqgAj25gBDqLWkGuhKKncHWlablS2fLpmzmh-FqPbamBms6Wb9oL73H-BN4RbaCV_GGtqRFJGGHiMcKMTkbAqFps0P9xyAlr77mjplC8yXvS-gnRw3Y1z3vpgmju9G7DSyKYNUea0-_7VkT-dq0DQTiAxpaBNz4bV4Ycuduu4J24opTAGnZKR3QMdLJnoM1NRhCtpAo8twXi5He4yIFiCoz5Cjy6uWkY8mtJchC5BEES-EnbqsTBY8ScOH3tQuR9gFxunHGrfwOvT6OgX2Y5D-ZjVC6WuFGy9tPb7w"
  end
end