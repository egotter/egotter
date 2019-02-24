'use strict';

var AudienceInsights = {};

AudienceInsights.drawChart = function (selector, categories, series) {
  Highcharts.chart({
    chart: {
      renderTo: $(selector)[0]
    },
    title: null,
    xAxis: {
      categories: categories,
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
    legend: false,
    exporting: false,
    credits: false
  });
};
