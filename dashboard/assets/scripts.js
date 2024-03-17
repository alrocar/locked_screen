const queryString = window.location.search;
const urlParams = new URLSearchParams(queryString);
const token = urlParams.get('token');

var colors = ["#FFEE92", "#FF73DC", "#63FFE9", "#A4FFAF", "#FEFEFE"]
//var colors = ["#003f5c","#2f4b7c","#665191","#a05195","#d45087","#f95d6a","#ff7c43","#ffa600"].reverse()
window.charts = {};
window.Apex = {
  chart: {
    foreColor: '#ccc',
    toolbar: {
      show: false
    },
  },
  stroke: {
    width: 3
  },
  dataLabels: {
    enabled: false
  },
  tooltip: {
    theme: 'dark'
  },
  grid: {
    borderColor: "#535A6C",
    xaxis: {
      lines: {
        show: true
      }
    }
  }
};

function addChart(id, options) {
  if (! window.charts[id]) {
    var chart = new ApexCharts(document.querySelector(`#${id}`), options);
    chart.render();
    window.charts[id] = chart;
  } else {
    window.charts[id].updateOptions(options)
  }
}

function spark(url, id, title) {
  fetch(url)
  .then(response => response.json())
  .then(data => {
    var spark = {
      chart: {
        id: id,
        group: 'sparks',
        type: 'line',
        height: 80,
        sparkline: {
          enabled: true
        },
        dropShadow: {
          enabled: true,
          top: 1,
          left: 1,
          blur: 2,
          opacity: 0.2,
        }
      },
      series: [{
        data: data["data"][0]["data"]
      }],
      stroke: {
        curve: 'smooth'
      },
      markers: {
        size: 0
      },
      grid: {
        padding: {
          top: 20,
          bottom: 10,
          left: 110
        }
      },
      colors: ['#fff'],
      tooltip: {
        x: {
          show: false
        },
        y: {
          title: {
            formatter: function formatter(val) {
              return '';
            }
          }
        }
      }
    }

    addChart(id, spark)
    const sum = data["data"][0]["data"].reduce((accumulator, currentValue) => accumulator + currentValue, 0);
    document.querySelector(`#${title}`).textContent = Math.round(sum)
  })
  .catch(error => console.error(`Error fetching ${id} data:`, error));
}

function timeline() {
  fetch(`https://api.tinybird.co/v0/pipes/timeline_2.json?token=${token}`)
  .then(response => response.json())
  .then(data => {
    var options = {
      series: [
        {
          data: data['data']
        }
      ],
      // colors: ["#f95d6a"],
      colors: colors,
      chart: {
        height: 250,
        type: 'rangeBar'
      },
      plotOptions: {
        bar: {
          horizontal: true,
          barHeight: '50%'
        }
      },
      xaxis: {
        type: 'datetime'
      },
      stroke: {
        width: 1
      },
      fill: {
        type: 'pattern',
        opacity: 1
      },
      legend: {
        position: 'top',
        horizontalAlign: 'left'
      },
      title: {
        text: 'Working hours timeline',
        align: 'left',
        offsetY: 5,
        offsetX: 20
      },
    };

    addChart('timeline', options)
  })
  .catch(error => console.error('Error fetching timeline data:', error));
}

function barchart(url, id, title) {
  fetch(url)
  .then(response => response.json())
  .then(data => {
    var optionsBar = {
      chart: {
        height: 380,
        type: 'bar',
        stacked: true
      },
      plotOptions: {
        bar: {
          columnWidth: '30%',
          horizontal: false,
        },
      },
      //colors: ["#003f5c","#2f4b7c","#665191","#a05195","#d45087","#f95d6a","#ff7c43","#ffa600"].reverse(),
      colors: colors,
      series: data["data"],
      xaxis: {
        categories: data["data"][0]["date"],
      },
      fill: {
        opacity: 1
      },
      title: {
        text: title,
        align: 'left',
        offsetY: 13,
        offsetX: 20
      },
      legend: {
        position: 'top',
        horizontalAlign: 'right',
        offsetY: -20
      }
    }
    addChart(id, optionsBar)
  })
  .catch(error => console.error('Error fetching barchart data:', error));

}

function linechart(url, id, title) {
  fetch(url)
  .then(response => response.json())
  .then(data => {
    var optionsLine = {
      chart: {
        height: 328,
        type: 'line',
        zoom: {
          enabled: false
        },
        dropShadow: {
          enabled: true,
          top: 3,
          left: 2,
          blur: 4,
          opacity: 1,
        }
      },
      stroke: {
        curve: 'smooth',
        width: 2
      },
      //colors: ["#003f5c","#2f4b7c","#665191","#a05195","#d45087","#f95d6a","#ff7c43","#ffa600"].reverse(),
      colors: colors,
      series: data["data"],
      title: {
        text: title,
        align: 'left',
        offsetY: 13,
        offsetX: 20
      },
      // subtitle: {
      //   text: 'Statistics',
      //   offsetY: 55,
      //   offsetX: 20
      // },
      markers: {
        size: 6,
        strokeWidth: 0,
        hover: {
          size: 9
        }
      },
      grid: {
        show: true,
        padding: {
          bottom: 0
        }
      },
      labels: data["data"][0]["date"],
      xaxis: {
        tooltip: {
          enabled: false
        }
      },
      legend: {
        position: 'top',
        horizontalAlign: 'right',
        offsetY: -20
      }
    }

    addChart(id, optionsLine)
  })
  .catch(error => console.error('Error fetching linechart data:', error));
}

const spark1 = `https://api.tinybird.co/v0/pipes/sparks.json?token=${token}`
const spark2 = `https://api.tinybird.co/v0/pipes/sparks.json?token=${token}&type=slack`
const spark3 = `https://api.tinybird.co/v0/pipes/sparks.json?token=${token}&type=coding`
const spark4 = `https://api.tinybird.co/v0/pipes/sparks.json?token=${token}&type=git`
const timeinapp = `https://api.tinybird.co/v0/pipes/active_app_by_day.json?limit=3&token=${token}`
const timeintab = `https://api.tinybird.co/v0/pipes/active_tab_by_day.json?limit=3&token=${token}`

const lineinapp = `https://api.tinybird.co/v0/pipes/active_app_by_day.json?limit=5&token=${token}&days=15`
const lineintab = `https://api.tinybird.co/v0/pipes/active_tab_by_day.json?limit=5&token=${token}&days=15`

function init() {
  spark(spark1, 'spark1', 'worked')
  spark(spark2, 'spark2', 'slack')
  spark(spark3, 'spark3', 'coding')
  spark(spark4, 'spark4', 'git')

  timeline()

  barchart(timeinapp, 'barchart', 'Time in app')
  barchart(timeintab, 'barchart-tab', 'Time in browser tab')

  linechart(lineinapp, 'line-adwords', 'Time in app')
  linechart(lineintab, 'line-adwords-tab', 'Time in browser tab')
}

init()
// window.setInterval(function () {
//   init()
// }, 10000)
