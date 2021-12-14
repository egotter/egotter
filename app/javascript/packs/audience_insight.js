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

    options = Highcharts.merge(chartConfig, options);
    Highcharts.chart(options);
  }
}

window.AudienceInsight = AudienceInsight;
