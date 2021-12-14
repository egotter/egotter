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
            enabled: series[0].data.length <= 1
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
}

window.AudienceInsight = AudienceInsight;

AudienceInsight.SampleData = [[1587686400000, 454], [1587772800000, 454], [1587772800000, 455], [1587772800000, 454], [1587772800000, 454], [1588032000000, 456], [1588032000000, 456], [1588204800000, 458], [1588636800000, 460], [1588723200000, 460], [1588723200000, 460], [1588723200000, 460], [1588896000000, 460], [1588982400000, 461], [1589068800000, 461], [1589068800000, 461], [1589241600000, 461], [1589241600000, 461], [1589328000000, 462], [1589414400000, 463], [1589414400000, 464], [1589500800000, 465], [1589587200000, 465], [1589587200000, 465], [1589760000000, 465], [1589846400000, 465], [1589846400000, 465], [1589846400000, 465], [1590019200000, 466], [1590019200000, 466], [1590105600000, 465], [1590105600000, 465], [1590192000000, 466], [1590278400000, 466], [1590364800000, 466], [1590624000000, 466], [1590796800000, 466], [1590883200000, 467], [1591228800000, 468], [1591488000000, 469], [1592006400000, 472], [1592092800000, 472], [1593302400000, 473], [1593388800000, 473], [1593388800000, 473], [1594080000000, 474], [1596153600000, 480], [1596240000000, 481], [1596672000000, 486], [1596844800000, 486], [1596844800000, 486], [1596931200000, 487], [1596931200000, 487], [1596931200000, 487], [1597017600000, 487], [1597017600000, 487], [1597363200000, 486], [1597536000000, 486], [1597536000000, 486], [1597536000000, 486], [1597622400000, 486], [1597622400000, 486], [1597622400000, 485], [1597708800000, 485], [1597708800000, 487], [1597708800000, 487], [1597795200000, 488], [1597968000000, 491], [1598140800000, 492], [1598140800000, 492], [1598140800000, 492], [1598227200000, 493], [1598227200000, 494], [1598659200000, 492], [1598745600000, 492], [1598918400000, 492], [1599004800000, 493], [1599091200000, 493], [1599264000000, 493], [1599350400000, 494], [1599436800000, 494], [1599609600000, 494], [1599782400000, 494], [1599868800000, 494], [1599955200000, 494], [1600560000000, 497], [1600560000000, 497], [1600905600000, 499], [1600905600000, 499], [1600992000000, 498], [1601078400000, 498], [1601078400000, 498], [1601251200000, 499], [1601251200000, 499], [1601251200000, 499], [1601337600000, 499], [1601424000000, 499], [1601683200000, 502], [1601856000000, 502], [1602028800000, 502]];
