defmodule Joken.HooksTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Joken.CurrentTime.Mock
  alias Joken.Signer

  setup do
    {:ok, _pid} = start_supervised(Mock)
    :ok
  end

  defmodule TestHook do
    @moduledoc false
    use Joken.Hooks

    @impl Joken.Hooks
    def before_sign(_options, {claims, signer}) do
      IO.puts("TestHook.before_sign/4")
      {:cont, {claims, signer}}
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
      @moduledoc false
      use Joken.Config

      @impl Joken.Hooks
      def before_generate(_options, {claims_config, extra_claims}) do
        IO.puts("before_generate")
        {:cont, {claims_config, extra_claims}}
      end
    end

    assert capture_io(&OwnHookIsExecuted.generate_and_sign/0) == "before_generate\n"
  end

  test "all hooks are executed" do
    defmodule AddedHooksAreExecuted do
      @moduledoc false
      use Joken.Config

      add_hook(TestHook)

      @impl Joken.Hooks
      def before_generate(_options, {claims_config, extra_claims}) do
        IO.puts("before_generate")
        {:cont, {claims_config, extra_claims}}
      end
    end

    assert capture_io(&AddedHooksAreExecuted.generate_and_sign/0) ==
             "before_generate\nTestHook.before_sign/4\n"
  end

  test "before_hook can abort execution" do
    defmodule BeforeHookCanAbort do
      @moduledoc false
      use Joken.Config

      @impl Joken.Hooks
      def before_sign(_options, _input) do
        {:halt, {:error, :abort}}
      end
    end

    assert BeforeHookCanAbort.generate_and_sign() == {:error, :abort}
  end

  test "after_hook can abort execution" do
    defmodule AfterHookCanAbort do
      @moduledoc false
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_options, _result, _input) do
        {:halt, {:error, :abort}}
      end
    end

    assert AfterHookCanAbort.generate_and_sign() == {:error, :abort}
  end

  test "wrong callback returns :unexpected" do
    defmodule WrongCallbackReturn do
      @moduledoc false
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_options, _result, _input), do: :ok
    end

    assert WrongCallbackReturn.generate_and_sign() == {:error, :wrong_hook_return}
  end

  test "can add hook with options" do
    defmodule HookWithOptions do
      @moduledoc false
      use Joken.Hooks

      @impl true
      def before_generate(options, {token_config, extra_claims}) do
        IO.puts("Run with options: #{inspect(options)}")
        {:cont, {token_config, extra_claims}}
      end
    end

    defmodule UseHookWithOptions do
      @moduledoc false
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
      @moduledoc false
      use Joken.Hooks

      @impl true
      def after_validate(_options, {:error, reason}, _input) do
        IO.puts("Got error: #{inspect(reason)}")
        {:halt, {:error, :validate_error}}
      end
    end

    defmodule UseValidateErrorHook do
      @moduledoc false
      use Joken.Config

      add_hook(ValidateErrorHook)

      def token_config do
        add_claim(%{}, "test", fn -> "TEST" end, &(&1 == "PRODUCTION"))
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
      @moduledoc false
      use Joken.Config

      add_hook(EmptyHook)
    end

    assert %{"iss" => "Joken", "aud" => "Joken"} =
             TokenWithEmptyHook.verify_and_validate!(TokenWithEmptyHook.generate_and_sign!())
  end

  test "after callbacks can set validation" do
    defmodule TokenWithOverridenAfterHook do
      @moduledoc false
      use Joken.Config

      def after_validate(_, {:ok, _}, input) do
        {:cont, {:error, :invalid}, input}
      end
    end

    assert {:error, :invalid} ==
             TokenWithOverridenAfterHook.verify_and_validate(
               TokenWithOverridenAfterHook.generate_and_sign!()
             )
  end

  test "after verify receives signing error" do
    defmodule AfterVerifyTokenError do
      @moduledoc false
      use Joken.Config

      def after_verify(_, result, input) do
        assert result == {:error, :signature_error}
        {:cont, result, input}
      end
    end

    signer = Signer.create("HS256", "another key whatever")

    assert {:error, :signature_error} ==
             AfterVerifyTokenError.verify_and_validate(
               AfterVerifyTokenError.generate_and_sign!(),
               signer
             )
  end
end
