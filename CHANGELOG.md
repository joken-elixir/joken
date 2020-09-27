## [Unreleased]

## [2.3.0] - 2020-09-27

### Changed

- (@supersimple with @bryanjos) Update CHANGELOG.md (#257)
- (@victorolinasc) chore: add public PEM only signer test
- (@victorolinasc) chore: update deps
- (@victorolinasc) Adding error handling (#277)
- (@ideaMarcos) Update common_use_cases.md (#285)
- (@victorolinasc) Clean up versions and compatibility with OTP 23 (#291)

### Fixed

- (@woylie) fix type specs and doc (#266)

## [2.2.0] - 2019-11-08

### Added

- (@bryanjos) Update .travis.yml to deploy to hex on tag (#232)
- (@thefuture2029) Access current_time_adapter in runtime instead of compile time (#252)
- (@victorolinasc) feat: add required claims hook (#250)

### Changed

- Bump benchee from 0.14.0 to 1.0.1
- Bump stream_data from 0.4.2 to 0.4.3 (#227)
- Bump ex_doc from 0.19.3 to 0.20.2 (#230)
- Bump dialyxir from 1.0.0-rc.4 to 1.0.0-rc.6
- Bump credo from 1.0.2 to 1.0.5
- Bump excoveralls from 0.10.5 to 0.11.1 (#233)
- Bump ex_doc from 0.20.2 to 0.21.1 (#240)
- Bump ex_doc from 0.21.1 to 0.21.2 (#246)
- Bump excoveralls from 0.11.1 to 0.11.2 (#243)
- Bump junit_formatter from 3.0.0 to 3.0.1 (#238)
- Bump dialyxir from 1.0.0-rc.6 to 1.0.0-rc.7 (#248)
- Bump credo from 1.0.5 to 1.1.5 (#253)
- Bump excoveralls from 0.11.2 to 0.12.0 (#254)

### Fixed

- (@llxff) Fix small typo in "Asymmetric cryptography signers" guide (#235)
- (@polvalente) fix: treat improper token properly (#237)
- (@chulkilee) Use short identifier from SPDX License List (#255)

## [2.1.0] - 2019-05-27

### Added

- (@tgturner) Allow custom error messages on claim validation (#221)

### Changed

- (@sgtpepper43) Get default signer at runtime (#212)
- (@balena) Update to JOSE 1.9 and remove Jason dependency (#216)
- (@victorolinasc) chore: deps update, docs update, removed unused application (#219)

### Fixed

- (@maartenvanvliet) Plural time units are deprecated >= elixir1.8 (#213)
- (@oo6) Fixed documentation (#218)
- (@popo63301) fix typo (#220)
- (@HeroicEric) Fix some typos in configuration guide (#222)

## [2.0.1] - 2019-02-17

### Changed

- Get default signer at runtime (#212) @sgtpepper43
- Update to JOSE 1.9 and remove Jason dependency (#216) @balena

### Fixed

- Plural time units are deprecated >= elixir1.8 (#213) @maartenvanvliet
- Fixed documentation (#218) @oo6

## [v2.0.0] - 2019-01-02

This is a re-write with a focus on making a clearer API surface with less ambiguity and more future proof without breaking backwards compatibility once again.

For changes on versions 1.x look on the v1.5 branch.

* Enhancements

- Ease of key configuration. We provide optional built-in support with Elixir's `Mix.Config` system. See our configuration guide for more details;
- Portable configuration using `Joken.Claim`;
- Encapsulate your token logic in a module with `Joken.Config`;
- Better error handling. We provide a lot more context in error messages;
- A good perfomance analysis for ensuring this hot-path in APIs won't be your bottleneck. Please see our perfomance documentation to check what we are talking about;
- Hooks for extending Joken functionality. All core actions in Joken have a corresponding hook for extending its functionality;
- Guides for common patterns;

* Backwards incompatible changes

- There is no `Joken.Plug` module anymore. Depending on requests we can bring that back, but we believe it is better to be on a different library;
- The API surface changed a lot but you can still use Joken with the same [token pattern as versions 1.x](http://trivelop.de/2018/05/14/flow-elixir-designing-apis/). Please see our [migrating guide](https://github.com/joken-elixir/joken/blob/master/guides/migration_from_1.md).
