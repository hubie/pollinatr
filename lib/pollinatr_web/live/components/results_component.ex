defmodule PollinatrWeb.Components.ResultsComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.6.0/chart.min.js"></script>
      <div phx-update="ignore" class="chart-container">
        <canvas class="results chart" id="resultsChart" phx-hook="ResultsChart"></canvas>
      </div>
    """
  end
end