// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"



// require("chartkick")
import "chartkick/chart.js"

var TimerClass = require("easytimer.js").Timer
var timer = new TimerClass();


function updateTimerValue() {
  var s= document.getElementById('countdownTimer')
  s.innerHTML = timer.getTimeValues().toString(['minutes', 'seconds']);
}

let Hooks = {}
Hooks.MessageSubmit = {
  updated(){
    this.el.value = "";
  }
}
Hooks.Timer = {

  mounted() {
    timer.addEventListener('secondsUpdated', function (e) {
      updateTimerValue()
    });
    this.handleEvent("no_timer", ({data}) => {
        timer.stop()
        // updateTimerValue()
      }
    )
    this.handleEvent("new_timer", ({data}) => {
        timer.stop()
        timer.start({countdown: true, startValues: {seconds: data}});
        updateTimerValue()
      }
    )
  }
}
Hooks.ResultsChart = {
  mounted() {
    var ctx = document.getElementById('resultsChart');
    // Chart.defaults.global.defaultFontFamily='Montserrat, sans-serif'
    Chart.defaults.font.family='Montserrat, sans-serif'

    var resultsChart = new Chart(ctx, {
        type: 'bar',
        data: {
            // labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
            datasets: [{
                // label: '# of Votes',
                // data: [12, 19, 3, 5, 2, 3],
                backgroundColor: [
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)'
                ],
                borderColor: [
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)',
                    'rgb(242,188,35)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: {
                display: false
              }
            },
            scales: {
                y: {
                    ticks: {
                      font: {
                        size: 30,
                      },
                      beginAtZero: true,
                      precision: 0
                    }
                },
                x: {
                  color: 'rbga(1,1,1,1)',
                  ticks: {
                    font: {
                      size: 30,
                      weight: 'bold',
                    },
                    autoSkip: false,
                    maxRotation: 0,
                    color: 'rgb(242,188,35)',
                    callback: function(val, index) {
                      return this.getLabelForValue(val).split("\n");
                    }
                  }
                }
            }
        }
    });

    this.handleEvent("new_results", ({data}) => {
        var labels = []
        var values = []
        if( Object.keys(data).length ) {
          data.forEach((lineitem) => {
              labels.push(formatLabel(Object.keys(lineitem)[0], Object.keys(data).length))
              values.push(Object.values(lineitem)[0])
          })

          resultsChart.data.datasets[0].data = [].concat.apply([], values)
          resultsChart.data.labels = [].concat.apply([], labels)
          resultsChart.update();
        }
      }
    )
  }
}

function formatLabel(raw, totalCount) {
    var formattedLabel = "";
    var chunk = "";
    raw.split(" ").forEach((word) => {
      if(getWidthOfText(chunk+" "+word, 'Montserrat, sans-serif', '30px') > (getScaleWidth()/totalCount)) {
        formattedLabel += (formattedLabel.length ? "\n"+chunk : chunk);
        chunk = word;
      } else {
        chunk += chunk.length ? " "+word : word;
      }
    });
    formattedLabel += (formattedLabel.length ? "\n"+chunk : chunk);
    return formattedLabel
}

function getScaleWidth() {
  var scale = Chart.getChart('resultsChart').scales.x;
  return scale.width - scale._margins.left - scale._margins.right;
}

function getWidthOfText(txt, fontname, fontsize){
    if(getWidthOfText.c === undefined){
        getWidthOfText.c=document.createElement('canvas');
        getWidthOfText.ctx=getWidthOfText.c.getContext('2d');
    }
    var fontspec = fontsize + ' ' + fontname;
    if(getWidthOfText.ctx.font !== fontspec)
        getWidthOfText.ctx.font = fontspec;
    return getWidthOfText.ctx.measureText(txt).width;
}



let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


