defmodule Pollinatr.User do
  @behaviour Bodyguard.Policy

  defstruct validation_code: nil, id: nil, role: nil, email_address: nil

  @voter_codes []
  @admin_codes [System.get_env("ADMIN_LOGIN_CODE")]
  @refresh_period 120

  def get_user(%{user_id: user_id}) do
    case :ets.lookup(:users, :"#{user_id}") do
      [{_id, user}] ->
        user
      nope ->
        IO.inspect(nope, label: "USER NOT FOUND")
    end
  end

  def get_user(%{email_address: email_address}) do
    new_user(%{email_address: email_address, role: :voter})
  end

  def get_user(user) do
    IO.inspect(user, label: "USER")
    current_time = DateTime.utc_now |> DateTime.to_unix
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

  def get_user(%{validation_code: validation_code} = user, list_state) do
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
    save_user(%__MODULE__{id: "code_"<>code, role: role, validation_code: code})
  end

  defp new_user(%{email_address: email, role: role}) do
    save_user(%__MODULE__{id: "email_"<>email, role: role, email_address: email})
  end

  defp save_user(%{id: user_id} = user) do
    :ets.insert(:users, {:"#{user_id}", user})
    user
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

    refresh_time = DateTime.utc_now |> DateTime.to_unix
    :ets.insert(:auth_meta, {:last_refresh,  refresh_time})
  end

  defp get_codes(pid) do
    get_codes(pid, 1)
  end

  defp get_codes(pid, start_row) do
    max_rows = 300
    end_row = start_row+max_rows

    {:ok, fetched_codes} = GSS.Spreadsheet.read_rows(pid, start_row, end_row, column_to: 1)
    new_codes = fetched_codes |> List.flatten |> Enum.reject(& is_nil(&1) || &1 == "" )

    case Enum.count(new_codes) do
      0 ->
        :ok
      _ ->
        vc = new_codes |> Enum.map(fn vc -> {:"#{vc}", :voter} end)
        :ets.insert(:auth_codes, vc)
        get_codes(pid, end_row+1)
    end
  end

  def authorize(_, %__MODULE__{role: :admin}, _), do: true
  def authorize(:voter, %__MODULE__{role: :voter}, _), do: true
  def authorize(action, %{user_id: user_id}, params), do: authorize(action, get_user(%{user_id: user_id}), params)
  # def authorize(action, %{email_address: email_address}, params), do: authorize(action, get_user(%{email_address: email_address}), params)
  # def authorize(action, %{validation_code: validation_code}, params), do: authorize(action, get_user(%{validation_code: validation_code}), params)
  def authorize(_action, _user, _params), do: false
end
