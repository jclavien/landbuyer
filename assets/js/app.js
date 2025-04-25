// assets/js/app.js


// 2) Phoenix HTML helpers (pour les form & method-override)
import "phoenix_html"

// 3) Importe Phoenix et LiveView
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

// 4) Barre de progression sur nav (optionnel, créé par phx.new)
import topbar from "topbar"

// 5) Importe ton hook NavChart
import NavChart from "./hooks/nav_chart"

// 6) Récupère le CSRF token pour sécuriser les sockets
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

// 7) Monte LiveSocket en y enregistrant le hook
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { NavChart }
})

// 8) Configure Topbar (couleur et ombre)
topbar.config({
  barColors: { 0: "#29d" },
  shadowColor: "rgba(0, 0, 0, .3)"
})

// 9) Affiche/caché la barre sur navigation LiveView
window.addEventListener("phx:page-loading-start", () => topbar.show())
window.addEventListener("phx:page-loading-stop", () => topbar.hide())

// 10) Connecte-toi au socket si des LiveViews sont présentes
liveSocket.connect()

// 11) Expose pour debug / simulations de latence
window.liveSocket = liveSocket
