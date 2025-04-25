// 1) Importe l’adapter date-fns pour activer l’axe de temps
import 'chartjs-adapter-date-fns'

// assets/js/hooks/nav_chart.js
import Chart from "chart.js/auto"

const NavChart = {
  mounted() {
    // on récupère le contexte du canvas
    const ctx = this.el.querySelector("canvas").getContext("2d")
    // on parse les points passés via data-points
    const points = JSON.parse(this.el.dataset.points)
    const labels = points.map(p => p.inserted_at)
    const data   = points.map(p => p.nav)

    // on crée le chart une fois pour toutes
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "NAV",
          data,
          fill: false,
          tension: 0.1
        }]
      },
      options: {
        scales: {
          x: {
            type: "time",
            time: {
              unit: labels.length > 5000 ? "hour" : "minute"
            },
            ticks: {
              autoSkip: true,
              maxTicksLimit: 10
            }
          },
          y: {
            beginAtZero: false
          }
        }
      }
    })
  },

  updated() {
    // à chaque update LiveView, on met à jour les données
    const points = JSON.parse(this.el.dataset.points)
    const labels = points.map(p => p.inserted_at)
    const data   = points.map(p => p.nav)

    this.chart.data.labels = labels
    this.chart.data.datasets[0].data = data
    this.chart.options.scales.x.time.unit =
      points.length > 5000 ? "hour" : "minute"
    this.chart.update()
  }
}

export default NavChart
