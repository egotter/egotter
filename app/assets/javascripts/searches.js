window.common_pie_chart_options = {
  credits: false,
  colors: ['rgba(42, 161, 152, 1.0)', 'rgba(181, 137, 0, 0.4)', 'rgba(203, 75, 22, 0.4)', 'rgba(220, 50, 47, 0.4)'],
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
    name: null,
    colorByPoint: true,
    data: null
  }],
  drilldown: {
    series: null
  }
};

window.usage_stats_column_chart_options = {
  credits: false,
  colors: ['rgba(181, 137, 0, 1.0)', 'rgba(203, 75, 22, 1.0)', 'rgba(220, 50, 47, 1.0)', 'rgba(211, 54, 130, 1.0)', 'rgba(108, 113, 196, 1.0)', 'rgba(38, 139, 210, 1.0)', 'rgba(42, 161, 152, 1.0)', 'rgba(133, 153, 0, 1.0)'],
  chart: {
    type: 'column',
    marginTop: 0,
    spacingTop: 0
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

window.usage_stats_tweets_stat_options = {
  credits: false,
  colors: ['rgba(181, 137, 0, 0.4)', 'rgba(42, 161, 152, 1.0'],
  chart: {
    type: 'bar'
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

window.gaugeOptions = {
  credits: false,
  chart: {
    type: 'solidgauge',
    marginTop: 0,
    spacingTop: 0
  },
  title: null,
  pane: {
    center: ['50%', '85%'],
    size: '140%',
    startAngle: -90,
    endAngle: 90,
    background: {
      backgroundColor: '#EEE',
      innerRadius: '60%',
      outerRadius: '100%',
      shape: 'arc'
    }
  },
  tooltip: {
    enabled: false
  },
  yAxis: {
    stops: [
      [0.1, '#55BF3B'], // green
      [0.5, '#DDDF0D'], // yellow
      [0.9, '#DF5353'] // red
    ],
    lineWidth: 0,
    minorTickInterval: null,
    tickAmount: 2,
    min: 0,
    max: 1000000,
    title: null,
    labels: {
      y: 16
    }
  },
  series: [{
    name: 'Score',
    data: [80],
    dataLabels: {
      format: '<div style="text-align: center;"><span style="font-size: x-large; color: black;">{y}</span></div>'
    },
    tooltip: {
      valueSuffix: null
    }
  }],
  plotOptions: {
    solidgauge: {
      dataLabels: {
        y: 5,
        borderWidth: 0,
        useHTML: true
      }
    }
  }
};