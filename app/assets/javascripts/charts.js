window.usage_stats_column_chart_options = {
  credits: false,
  colors: ['rgba(181, 137, 0, 1.0)', 'rgba(203, 75, 22, 1.0)', 'rgba(220, 50, 47, 1.0)', 'rgba(211, 54, 130, 1.0)', 'rgba(108, 113, 196, 1.0)', 'rgba(38, 139, 210, 1.0)', 'rgba(42, 161, 152, 1.0)', 'rgba(133, 153, 0, 1.0)'],
  chart: {
    type: 'column',
    marginTop: 0,
    marginRight: 0,
    spacingTop: 0,
    spacingBottom: 0,
    spacingLeft: 0
  },
  title: {
    style: {color: '#777777'},
    text: null
  },
  xAxis: {
    type: 'category'
  },
  yAxis: {
    title: {
      text: null
    },
    labels: {
      formatter: null
    },
    endOnTick: false,
    startOnTick: false
  },
  legend: {
    enabled: false
  },
  plotOptions: {
    series: {
      borderWidth: 0,
      dataLabels: {
        enabled: false,
        format: '{point.y}'
      }
    }
  },
  tooltip: false,

  series: [{
    name: null,
    colorByPoint: true,
    data: null
  }],
  drilldown: {
    series: null
  }
};

window.barChartOptions = {
  credits: false,
  colors: ['rgba(181, 137, 0, 0.4)', 'rgba(42, 161, 152, 1.0'],
  chart: {
    type: 'bar',
    marginTop: 0,
    marginRight: 0,
    spacingTop: 0,
    spacingBottom: 0,
    spacingLeft: 0
  },
  title: {
    style: {color: '#777777'},
    text: null
  },
  xAxis: {
    categories: null
  },
  yAxis: {
    min: 0,
    max: 100,
    title: {
      text: null
    }
  },
  legend: {
    reversed: true
  },
  plotOptions: {
    series: {
      stacking: 'normal'
    }
  },
  series: null
};
