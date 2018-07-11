# Testing your app with Joken

On common hurdle with testing tokens is that they almost always contain some time sensitive claims. If you want to automate the expiration of your tokens how can you do it?

One possible solution to this problem is to have a different token configuration for your tests. This works but is not advisable since your production code will run a different path than your test code. It is one of those moments where your tests might pass but things can go wrong in production.

## Joken time

We have ifntroduced an adapter for producing any time sensitive claim values. `Joken.current_time/0` looks for the implementation it will use in the configuration. This is the adapter pattern that helps you mock time if you need to. 

The default implementation we use is `Joken.CurrentTime.OS`. It uses `DateTime` to fetch current time in seconds.

In our tests we have a `Joken.CurrentTime.Mock` that can freeze time or advance as we want it. Please, look in our test base for one possible solution. 

We don't ship `Joken.CurrentTime.Mock` in the library as this is only one possible way of solving this. If you already have a time mocking mechanism in your app, you can make Joken use it with:

```elixir
config :joken, current_time_adapter: MyTimeMock
```

All it needs is to implement the function `current_time/0`.

### Behaviour

It also worth mentioning that Joken.CurrentTime is a behaviour so you can use mocking libraries like `mox`.
