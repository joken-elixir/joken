# V 2.0 TODO:

- [ ] [NEW] Add options to `Joken.Claim`. These could include: optinal, error message and so on.
- [ ] [NEW] Add jti claim generation configuration in `use Joken.Config`.
- [ ] [NEW] Check OpenSSH keys.
- [ ] [NEW] Check JWKS with dynamic keys (should look at other APIs... we could use Guardian's implementation and update our key configuration guide).
- [ ] [NEW] Preload all keys in application bootstrap so that we can fail early and have a map with already parsed keys.
- [ ] Another full pass on documentation.
- [ ] Typespec everything with better typespecs (internal types for better documentation).
- [ ] Logo?
- [ ] Include HTML reports for benchmarks (Benchee HTML).
- [ ] Create 1.x branch.
- [ ] Clean CHANGELOG pointing to 1.x branch if the user wants to check it out.
- [ ] Reach at least 90% coverage.
- [ ] See if the optimizations for [`Poison`](https://github.com/potatosalad/erlang-jose/blob/master/lib/jose/poison/lexical_encoder.ex) json module can be used with `Jason`. This is certainly a hot path for `JOSE`.
- [ ] Discuss putting the override of base64url on a library (**IMPORTANT!!!**).
- [ ] Discuss Joken.Plug (should we keep it here or document a better way of handling this like Mithril??).
- [ ] Discuss an API for parsing token into known struct (maybe implemented as a hook?).
- [ ] Discuss having a better hooks plugging mechanism. It should be possible to add more than one hook without overriding functions. We could append hooks at compile time and just call one by one during execution time.
- [ ] Discuss having a repository for benchmarking all other types of token libraries (Guardian, AuthSecret and so on)
- [ ] Discuss making samples in another repository.
- [ ] Discuss having an organization in Github for managing all that.
- [ ] Missing guides:
  - [ ] Differences with Phoenix.Token
  - [ ] Differences with using raw JOSE
  - [ ] Key configuration (WIP)
  - [ ] Testing

