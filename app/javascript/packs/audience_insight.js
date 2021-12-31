class AudienceInsight {
  drawChart(renderTo, series) {
    var options = {
      chart: {
        renderTo: renderTo,
        type: 'spline'
      },
      title: null,
      xAxis: {
        type: 'datetime',
        dateTimeLabelFormats: {
          day: '%m/%d',
          week: '%m/%d'
        },
        title: {
          text: null
        }
      },
      yAxis: [{
        title: {
          text: null
        }
      }],
      series: series,
      tooltip: {
        xDateFormat: '%Y-%m-%d',
        hideDelay: 0,
        outside: true,
        shared: true
      },
      plotOptions: {
        series: {
          marker: {
            enabled: false
          }
        }
      },
      exporting: false,
      credits: false
    };

    Highcharts.chart(options);
  }

  drawSparkLine(renderTo, series, legendEnabled) {
    var options = {
      legend: {
        enabled: legendEnabled
      }
    };

    var chartConfig = {
      chart: {
        renderTo: renderTo,
        type: 'spline',
        borderWidth: 0,
        margin: [2, 0, 2, 0],
        skipClone: true
      },
      title: null,
      xAxis: {
        labels: {
          enabled: false
        },
        title: {
          text: null
        },
        startOnTick: false,
        endOnTick: false,
        tickPositions: []
      },
      yAxis: {
        endOnTick: false,
        startOnTick: false,
        labels: {
          enabled: false
        },
        title: {
          text: null
        },
        tickPositions: [0]
      },
      series: series,
      tooltip: {
        xDateFormat: '%Y-%m-%d',
        hideDelay: 0,
        outside: true,
        shared: true
      },
      plotOptions: {
        series: {
          animation: false,
          lineWidth: 1,
          shadow: false,
          states: {
            hover: {
              lineWidth: 1
            }
          },
          marker: {
            enabled: false
          }
        }
      },
      exporting: false,
      credits: false
    };

    options = Highcharts.merge(chartConfig, options);
    Highcharts.chart(options);
  }
}

window.AudienceInsight = AudienceInsight;

function drawSparkLine(url, container, legendEnabled) {
  $.get(url).done(function (res) {
    new AudienceInsight().drawSparkLine(container, res.series, legendEnabled);
  }).fail(function () {
    // Do nothing
  });
}

window.drawSparkLine = drawSparkLine;
