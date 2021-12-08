defmodule Pollinatr.Models.User do
  @behaviour Bodyguard.Policy
  import Ecto.Query
  alias Pollinatr.Schema.User, as: UserSchema
  alias Pollinatr.Repo

  defstruct validation_code: nil, id: nil, role: nil, email_address: nil

  @voter_codes []
  @admin_codes [System.get_env("ADMIN_LOGIN_CODE")]
  @refresh_period 120

  def get_user(%{user_id: nil} = params) do
    IO.inspect(params, label: "NO USER_ID PROVIDED")
    nil
  end

  def get_user(%{user_id: user_id}) do
    result = Repo.one(from u in UserSchema, where: u.id == ^user_id, select: u)
    IO.inspect(result, label: "RESULT")

    case result do
      nil ->
        IO.inspect(user_id, label: "USER_ID NOT FOUND")
        nil

      user ->
        user
    end
  end

  def create_user(%Ecto.Changeset{} = new_user) do
    IO.inspect(new_user, label: "UPSERTING NEW USER")

    {:ok, user} =
      Repo.insert_or_update(new_user,
        conflict_target: :email_address,
        on_conflict: {:replace_all_except, [:id, :email_address, :role]}
      )

    IO.inspect(user)
    user
  end

  def find_or_create_user(%{} = new_user) do
    make_changeset(new_user) |> create_user()
  end

  def get_user(%{validation_code: validation_code} = user) do
    IO.inspect(user, label: "USER")
    current_time = DateTime.utc_now() |> DateTime.to_unix()

    case :ets.lookup(:auth_meta, :last_refresh) do
      [] ->
        IO.inspect("BRAND NEW")
        get_user(user, :stale)

      [{_, last_refresh}] when last_refresh + @refresh_period < current_time ->
        IO.inspect(last_refresh, label: "LAST_REFRESH_STALE")
        get_user(user, :stale)

      meh ->
        IO.inspect(meh, label: "LAST_REFRESH_FRESH")
        get_user(user, :fresh)
    end
  end

  defp get_user(%{validation_code: validation_code} = user, list_state) do
    IO.inspect(:ets.lookup(:auth_codes, :"#{validation_code}"), label: "USER")

    case :ets.lookup(:auth_codes, :"#{validation_code}") do
      [{_, :admin}] ->
        new_user(%{validation_code: validation_code, role: :admin})

      [{_, :voter}] ->
        new_user(%{validation_code: validation_code, role: :voter})

      meh ->
        case list_state do
          :stale ->
            IO.inspect(meh, label: "Refreshing codes, existing codes:")

            refresh_voter_codes()
            get_user(user, :fresh)

          _ ->
            IO.inspect(meh, label: "Code not found in list:")

            false
        end
    end
  end

  defp new_user(%{validation_code: code, role: role}) do
    # make_changeset(%__MODULE__{id: "code_" <> code, role: role, validation_code: code})
    # |> create_user()
  end

  defp new_user(%{email_address: email, role: role}) do
    make_changeset(%{id: "email_" <> email, role: role, email_address: email})
    |> create_user()
  end

  defp make_changeset(%{role: role} = user) do
    changeset = UserSchema.changeset(%UserSchema{}, user)
  end

  defp refresh_voter_codes() do
    # :ets.delete_all_objects(:auth_codes)

    vc = @voter_codes |> Enum.map(fn vc -> {:"#{vc}", :voter} end)
    :ets.insert(:auth_codes, vc)
    ac = @admin_codes |> Enum.map(fn ac -> {:"#{ac}", :admin} end)
    :ets.insert(:auth_codes, ac)

    {:ok, pid} = GSS.Spreadsheet.Supervisor.spreadsheet(System.get_env("VOTER_CODE_SHEET_ID"))

    get_codes(pid)
    Process.exit(pid, :kill)

    refresh_time = DateTime.utc_now() |> DateTime.to_unix()
    :ets.insert(:auth_meta, {:last_refresh, refresh_time})
  end

  defp get_codes(pid) do
    get_codes(pid, 1)
  end

  defp get_codes(pid, start_row) do
    max_rows = 300
    end_row = start_row + max_rows

    {:ok, fetched_codes} = GSS.Spreadsheet.read_rows(pid, start_row, end_row, column_to: 1)
    new_codes = fetched_codes |> List.flatten() |> Enum.reject(&(is_nil(&1) || &1 == ""))

    case Enum.count(new_codes) do
      0 ->
        :ok

      _ ->
        vc = new_codes |> Enum.map(fn vc -> {:"#{vc}", :voter} end)
        :ets.insert(:auth_codes, vc)
        get_codes(pid, end_row + 1)
    end
  end

  def authorize(_, %UserSchema{role: :admin}, _), do: true
  def authorize(:voter, %UserSchema{role: :voter}, _), do: true

  def authorize(action, %{user_id: user_id}, params),
    do: authorize(action, get_user(%{user_id: user_id}), params)

  def authorize(_action, _user, _params), do: false
end
