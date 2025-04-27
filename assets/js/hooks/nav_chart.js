// 1) Importe l’adapter date-fns pour activer l’axe de temps
import 'chartjs-adapter-date-fns'

// assets/js/hooks/nav_chart.js
import Chart from "chart.js/auto"

const NavChart = {
  mounted() {
    const points = JSON.parse(this.el.dataset.points)
    const labels = points.map(p => p.inserted_at)
    const data   = points.map(p => p.nav)

    const ctx = this.el.querySelector("canvas").getContext("2d")
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "NAV",
          data,
          borderColor: '#94a3b8',
          borderWidth: 2,
          fill: false,
          tension: 0.1,
          pointStyle: 'circle',
          pointRadius: 0
        }]
      },
      options: {
        animation: false,
        scales: {
          x: {
            type: "time",
            time: {
              unit: labels.length > 5000 ? "hour" : "minute"
            },
            ticks: {
              color: '#94a3b8',
              autoSkip: true,
              maxTicksLimit: 10
            },
            grid: {
              color: 'rgba(71, 85, 105, 0.2)',
              lineWidth: 1,
              drawBorder: false
            }
          },
          y: {
            beginAtZero: false,
            ticks: {
              color: '#94a3b8',
              font: {
                family: 'sans',
                size: 12,
                weight: '500'
              }
            },
            grid: {
              color: 'rgba(71, 85, 105, 0.2)',
              lineWidth: 1,
              drawBorder: false
            }
          }
        },
        plugins: {
          legend: {
            position: 'bottom',
            align: 'start',
            labels: {
              usePointStyle: true,
              pointStyle: 'line',
              lineWidth: 1,
              boxWidth: 40,
              boxHeight: 30,
              padding: 20
            }
          }
        }
      }
    })

    // ─── AJOUT DU DÉGRADÉ ─────────────────────────────────
    const { ctx: c, chartArea } = this.chart
    const gradient = c.createLinearGradient(
      0,
      chartArea.top,
      0,
      chartArea.bottom
    )
    gradient.addColorStop(0, 'rgba(148, 163, 184, 0.4)')
    gradient.addColorStop(1, 'rgba(24, 25, 34, 0)')
    this.chart.data.datasets[0].backgroundColor = gradient
    this.chart.data.datasets[0].fill = true
    this.chart.update('none')
  },

  updated() {
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