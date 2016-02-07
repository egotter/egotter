window.common_pie_chart_options = {
  credits: false,
  colors: ['rgba(181, 137, 0, 1.0)', 'rgba(203, 75, 22, 0.2)', 'rgba(220, 50, 47, 0.2)'],
  exporting: false,
  chart: {
    type: 'pie',
    margin: [0, -60, 0, 0],
    spacing: [0, 0, 0, 0]
  },
  legend: {
    align: 'left',
    layout: 'vertical',
    verticalAlign: 'middle',
    x: 0,
    y: 0,
    backgroundColor: 'rgba(255, 255, 255, 0.0)'
  },
  title: null,
  tooltip: false,
  plotOptions: {
    pie: {
      allowPointSelect: false,
      cursor: 'pointer',
      dataLabels: false,
      size: '100%',
      showInLegend: true
    }
  },
  series: [{
    name: '',
    colorByPoint: true,
    data: null
  }]
};

window.usage_stats_column_chart_options = {
  credits: false,
  chart: {
    type: 'column'
  },
  title: {
    text: null
  },
  xAxis: {
    type: 'category'
  },
  yAxis: {
    title: {
      text: null
    }

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
