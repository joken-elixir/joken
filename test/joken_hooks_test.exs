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
    def before_sign(claims, signer) do
      IO.puts("TestHook.before_sign/2")
      {:ok, claims, signer}
    end
  end

  test "can add hook" do
    defmodule AddHookTest do
      use Joken.Config

      add_hook(TestHook)
    end

    assert AddHookTest.__hooks__() == [TestHook, AddHookTest]
  end

  test "own hooks are executed" do
    defmodule OwnHookIsExecuted do
      use Joken.Config

      @impl Joken.Hooks
      def before_generate(extra_claims, claims_config) do
        IO.puts("before_generate")
        {:ok, extra_claims, claims_config}
      end
    end

    assert capture_io(&OwnHookIsExecuted.generate_and_sign/0) == "before_generate\n"
  end

  test "all hooks are executed" do
    defmodule AddedHooksAreExecuted do
      use Joken.Config

      add_hook(TestHook)

      @impl Joken.Hooks
      def before_generate(extra_claims, claims_config) do
        IO.puts("before_generate")
        {:ok, extra_claims, claims_config}
      end
    end

    assert capture_io(&AddedHooksAreExecuted.generate_and_sign/0) ==
             "before_generate\nTestHook.before_sign/2\n"
  end

  test "before_ hook can abort execution" do
    defmodule BeforeHookCanAbort do
      use Joken.Config

      @impl Joken.Hooks
      def before_sign(_claims, _signer) do
        {:error, :abort}
      end
    end

    capture_io(fn ->
      assert BeforeHookCanAbort.generate_and_sign() == {:error, :abort}
    end)
  end

  test "after_ hook can abort execution" do
    defmodule AfterHookCanAbort do
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_token, _claims, _signer) do
        {:error, :abort}
      end
    end

    capture_io(fn ->
      assert AfterHookCanAbort.generate_and_sign() == {:error, :abort}
    end)
  end

  test "wrong callback returns :unexpected" do
    defmodule WrongCallbackReturn do
      use Joken.Config

      @impl Joken.Hooks
      def after_sign(_token, _claims, _signer), do: :ok
    end

    capture_io(fn ->
      assert WrongCallbackReturn.generate_and_sign() == {:error, :wrong_callback_return}
    end)
  end
end
