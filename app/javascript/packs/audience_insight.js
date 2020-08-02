class AudienceInsight {
  drawChart(renderTo, series) {
    var yAxis = [{
      title: {
        text: null
      }
    }];

    if (series.length === 2) {
      yAxis.push({
        opposite: true,
        title: {
          text: null
        }
      });
    }

    var chartConfig = {
      chart: {
        renderTo: renderTo
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
      yAxis: yAxis,
      series: series,
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
