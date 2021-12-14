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
            enabled: this.checkMarkerEnabled(series[0].data)
          }
        }
      },
      exporting: false,
      credits: false
    };

    Highcharts.chart(options);
  }

  drawSparkLine(renderTo, series) {
    var chartConfig = {
      chart: {
        renderTo: renderTo,
        type: 'spline'
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
          marker: {
            enabled: false
          }
        }
      },
      exporting: false,
      credits: false
    };

    Highcharts.chart(chartConfig);
  }

  checkMarkerEnabled(data) {
    var count = data.filter(function (d) {
      return d[1];
    }).length;
    return count <= 1;
  }
}

window.AudienceInsight = AudienceInsight;
