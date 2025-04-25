// assets/js/app.js

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "topbar"
import NavChart from "./hooks/nav_chart"

// Stub complet pour tes hooks
const Hooks = {
  NavChart,
  // Attention : le nom ici doit matcher le phx-hook de ton modal
  AccountModal: {}
}

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", () => topbar.show())
window.addEventListener("phx:page-loading-stop",  () => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket
