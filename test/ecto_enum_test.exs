defmodule EctoEnumTest do
  use ExUnit.Case

  alias Ecto.Integration.TestRepo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
  end

  import Ecto.Changeset
  import EctoEnum
  defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :status, StatusEnum
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:status])
    end
  end

  test "accepts int, atom and string on save" do
    user = TestRepo.insert!(%User{status: 0})
    user = TestRepo.get(User, user.id)
    assert user.status == :registered

    user = Ecto.Changeset.change(user, status: :active)
    user = TestRepo.update! user
    assert user.status == :active

    user = Ecto.Changeset.change(user, status: "inactive")
    user = TestRepo.update! user
    assert user.status == "inactive"

    user = TestRepo.get(User, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%User{status: :archived})
    user = TestRepo.get_by(User, status: :archived)
    assert user.status == :archived
  end

  test "casts int and binary to atom" do
    %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
    assert changes.status == :active

    %{changes: changes} = cast(%User{}, %{"status" => 3}, ~w(status), [])
    assert changes.status == :archived

    %{changes: changes} = cast(%User{}, %{"status" => :inactive}, ~w(status), [])
    assert changes.status == :inactive
  end

  test "returns invalid changeset when input is not in the enum map" do
    refute cast(%User{}, %{"status" => "retroactive"}, ~w(status), []).valid?

    refute cast(%User{}, %{"status" => :retroactive}, ~w(status), []).valid?

    refute cast(%User{}, %{"status" => 4}, ~w(status), []).valid?
  end

  test "changesets are invalid when input is not in the enum map" do
    assert_raise Ecto.InvalidChangesetError, fn ->
      changeset = User.changeset(%User{}, %{status: "retroactive"})

      TestRepo.insert!(changeset)
    end

    assert_raise Ecto.InvalidChangesetError, fn ->
      changeset = User.changeset(%User{}, %{status: :retroactive})
      TestRepo.insert!(changeset)
    end

    assert_raise Ecto.InvalidChangesetError, fn ->
      changeset = User.changeset(%User{}, %{status: 5})
      TestRepo.insert!(changeset)
    end
  end

  test "reflection" do
    assert StatusEnum.__enum_map__() == [registered: 0, active: 1, inactive: 2, archived: 3]
  end

  test "defenum/2 can accept variables" do
    x = 0
    defenum TestEnum, zero: x
  end
end

# TODO: configure to return either string or atom
