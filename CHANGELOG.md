## [Unreleased]

### Added
### Changed
### Fixed

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
- The API surface changed a lot but you can still use Joken with the same [token pattern as versions 1.x](http://trivelop.de/2018/05/14/flow-elixir-designing-apis/). Please see our migrating guide.
