defmodule UeberauthToken.StrategyTest do
  use UeberauthToken.TestCase

  describe "When a provider has not been set in %Conn{private: %{ueberauth_token: _}}" do
    setup [:ensure_cache_deactivated]

    test "the handle_request!/1 function returns %Conn{} unchanged", %{conn: conn} do
      assert Strategy.handle_request!(conn) == conn
    end

    test """
         the handle_callback!/1 function raises a FunctionClauseError
         """,
         %{conn: conn} do
      assert_raise FunctionClauseError, fn ->
        Strategy.handle_callback!(conn)
      end
    end

    test "the cache is inactive" do
      assert Config.use_cache?(test_provider()) == false
      assert Config.cache_name(test_provider()) in :ets.all() == false
    end
  end

  describe "When the request headers lack an authorization token" do
    setup [:ensure_cache_deactivated, :setup_provider]

    @describetag :provider

    test "the handle_request!/1 function returns %Conn{} unchanged", %{conn: conn} do
      assert Strategy.handle_request!(conn) == conn
    end

    test """
         the handle_callback!/1 function returns %Conn{assigns: assigns} with a
         struct in the form %Ueberauth.Failure{errors: errors}
         """,
         %{conn: conn} do
      conn_after = Strategy.handle_callback!(conn)

      refute conn_after == conn
      assert Map.has_key?(conn_after.assigns, :ueberauth_failure) == true

      assert :erlang.hd(conn_after.assigns.ueberauth_failure.errors).message ==
               """
               Token validation failed for a token against the ueberauth_token_test_provider provider\n. \
               The authorization request header is missing
               """
               |> String.trim_trailing("\n")
    end

    test "the cache is inactive" do
      assert Config.use_cache?(test_provider()) == false
      assert Config.cache_name(test_provider()) in :ets.all() == false
    end
  end

  describe """
  When the request headers lack an authorization token but a private %Conn{} field
  has a valid authorization token
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "the handle_request!/1 function returns %Conn{} unchanged", %{conn: conn} do
      assert Strategy.handle_request!(conn) == conn
    end

    test """
         the handle_callback!/1 function returns a conn with a private payload
         in the format %Conn{private: %{ueberauth_token: payload}}
         """,
         %{conn: conn} do
      expect_passing_token_info()
      expect_passing_user_info()

      conn_after = Strategy.handle_callback!(conn)
      expected_payload = Fixtures.payload()

      refute conn_after == conn
      assert Map.has_key?(conn_after.assigns, :ueberauth_failure) == false
      assert Map.has_key?(conn_after.private, :ueberauth_token) == true

      assert conn_after.private.ueberauth_token.payload == expected_payload
    end

    test "the cache is inactive" do
      assert Config.use_cache?(test_provider()) == false
      assert Config.cache_name(test_provider()) in :ets.all() == false
    end
  end

  describe """
  When the request headers have an authorization token
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "the handle_request!/1 function returns %Conn{} unchanged", %{conn: conn} do
      assert Strategy.handle_request!(conn) == conn
    end

    test """
         the handle_callback!/1 function returns a conn with a private payload
         in the format %Conn{private: %{ueberauth_token: payload}}
         """,
         %{conn: conn} do
      expect_passing_token_info()
      expect_passing_user_info()

      conn_after = Strategy.handle_callback!(conn)
      expected_payload = Fixtures.payload()

      refute conn_after == conn
      assert Map.has_key?(conn_after.assigns, :ueberauth_failure) == false
      assert Map.has_key?(conn_after.private, :ueberauth_token) == true

      assert conn_after.private.ueberauth_token.payload == expected_payload
    end

    test "the cache is inactive" do
      assert Config.use_cache?(test_provider()) == false
      assert Config.cache_name(test_provider()) in :ets.all() == false
    end
  end
end
