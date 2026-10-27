# SPDX-FileCopyrightText: 2022 Alembic Pty Ltd
#
# SPDX-License-Identifier: MIT

defmodule AshAuthentication.UtilsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AshAuthentication.Utils

  describe "default_action/2" do
    defmodule DefaultsDomain do
      @moduledoc false
      use Ash.Domain, validate_config_inclusion?: false

      resources do
        allow_unregistered? true
      end
    end

    defmodule DefaultsResource do
      @moduledoc false
      use Ash.Resource, data_layer: Ash.DataLayer.Ets, domain: DefaultsDomain

      attributes do
        uuid_primary_key :id
        attribute :name, :string, public?: true
        attribute :email, :string, public?: true
      end

      actions do
        default_accept [:name]
        defaults [:read, :destroy, :create, update: [:email]]
      end
    end

    setup do
      {:ok, dsl_state: DefaultsResource.spark_dsl_config()}
    end

    test "gives the action the accept that `defaults` declares", %{dsl_state: dsl_state} do
      assert %{type: :update, accept: [:email]} = Utils.default_action(dsl_state, :update)
    end

    test "falls back to `default_accept` for a bare create or update", %{dsl_state: dsl_state} do
      assert %{type: :create, accept: [:name]} = Utils.default_action(dsl_state, :create)
    end

    test "builds read and destroy actions", %{dsl_state: dsl_state} do
      assert %{type: :read} = Utils.default_action(dsl_state, :read)
      assert %{type: :destroy} = Utils.default_action(dsl_state, :destroy)
    end

    test "returns `nil` for an action `defaults` doesn't declare", %{dsl_state: dsl_state} do
      refute Utils.default_action(dsl_state, :sign_in)
    end
  end

  describe "lifetime_to_seconds/1" do
    test "converts integer seconds to seconds" do
      assert Utils.lifetime_to_seconds(30) == 30
      assert Utils.lifetime_to_seconds(0) == 0
      assert Utils.lifetime_to_seconds(3600) == 3600
      assert Utils.lifetime_to_seconds({3600, :seconds}) == 3600
      assert Utils.lifetime_to_seconds({60, :minutes}) == 3600
      assert Utils.lifetime_to_seconds({24, :hours}) == 86_400
      assert Utils.lifetime_to_seconds({365, :days}) == 31_536_000
    end
  end
end
