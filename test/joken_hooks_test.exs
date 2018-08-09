defmodule Joken.HooksTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Joken.CurrentTime.Mock

  setup do
    {:ok, _pid} = start_supervised(Mock)
    :ok
  end

  defmodule TestHook do
    use Joken.Hooks

    @impl Joken.Hooks
    def before_sign(_options, _status, claims, signer) do
      IO.puts("TestHook.before_sign/4")
      {:cont, {:ok, claims, signer}}
    end
  end

  test "can add hook" do
    defmodule AddHookTest do
      use Joken.Config

      add_hook(TestHook)
    end

    assert AddHookTest.__hooks__() == [{TestHook, []}, AddHookTest]
  end

  test "own hooks are executed" do
    defmodule OwnHookIsExecuted do
      use Joken.Config

      @impl Joken.Hooks
      def before_generate(_options, _status, extra_claims, claims_config) do
        IO.puts("before_generate")
        {:cont, {:ok, extra_claims, claims_config}}
      end
    end

    assert capture_io(&OwnHookIsExecuted.generate_and_sign/0) == "before_generate\n"
  end

  test "all hooks are executed" do
    defmodule AddedHooksAreExecuted do
      use Joken.Config

      add_hook(TestHook)

      @impl Joken.Hooks
      def before_generate(_options, _status, extra_claims, claims_config) do
        IO.puts("before_generate")
        {:cont, {:ok, extra_claims, claims_config}}
      end
    end

    assert capture_io(&AddedHooksAreExecuted.generate_and_sign/0) ==
             "before_generate\nTestHook.before_sign/4\n"
  end

  test "before_hook can abort execution" do
    defmodule BeforeHookCanAbort do
      use Joken.Config

      @impl Joken.Hooks
      def before_sign(_options, _status, _claims, _signer) do
        {:halt, {:error, :abort}}
      end
    end

    assert BeforeHookCanAbort.generate_and_sign() == {:error, :abort}
  end

  test "after_hook can abort execution" do
    defmodule AfterHookCanAbort do
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_options, _status, _token, _claims, _signer) do
        {:halt, {:error, :abort}}
      end
    end

    assert AfterHookCanAbort.generate_and_sign() == {:error, :abort}
  end

  test "wrong callback returns :unexpected" do
    defmodule WrongCallbackReturn do
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_options, _status, _token, _claims, _signer), do: :ok
    end

    assert WrongCallbackReturn.generate_and_sign() == {:error, :wrong_hook_callback}
  end

  test "can add hook with options" do
    defmodule HookWithOptions do
      use Joken.Hooks

      @impl true
      def before_generate(options, status, extra_claims, token_config) do
        IO.puts("Run with options: #{inspect(options)}")
        {:cont, {status, extra_claims, token_config}}
      end
    end

    defmodule UseHookWithOptions do
      use Joken.Config

      add_hook(HookWithOptions, option1: 1)

      def token_config, do: %{}
    end

    assert capture_io(&UseHookWithOptions.generate_and_sign!/0) ==
             "Run with options: [option1: 1]\n"
  end

  @tag :capture_log
  test "error in validate propagates to after_validate" do
    defmodule ValidateErrorHook do
      use Joken.Hooks

      @impl true
      def after_validate(_options, {:error, reason}, _claims_map, _token_config) do
        IO.puts("Got error: #{inspect(reason)}")
        {:halt, {:error, :validate_error}}
      end
    end

    defmodule UseValidateErrorHook do
      use Joken.Config

      add_hook(ValidateErrorHook)

      def token_config do
        %{}
        |> add_claim("test", fn -> "TEST" end, &(&1 == "PRODUCTION"))
      end
    end

    token = UseValidateErrorHook.generate_and_sign!()

    fun = fn ->
      assert UseValidateErrorHook.verify_and_validate(token) == {:error, :validate_error}
    end

    assert capture_io(fun) ==
             "Got error: [message: \"Invalid token\", claim: \"test\", claim_val: \"TEST\"]\n"
  end

  test "empty hooks is a pass through implementation" do
    # no overridden callback
    defmodule(EmptyHook, do: use(Joken.Hooks))

    defmodule TokenWithEmptyHook do
      use Joken.Config
      add_hook(EmptyHook)
    end

    assert %{"iss" => "Joken", "aud" => "Joken"} =
             TokenWithEmptyHook.generate_and_sign!()
             |> TokenWithEmptyHook.verify_and_validate!()
  end
end
