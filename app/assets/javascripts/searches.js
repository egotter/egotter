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
    type: 'column'
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

window.usage_stats_tweets_stat_options = {
  credits: false,
  colors: ['rgba(181, 137, 0, 0.4)', 'rgba(42, 161, 152, 1.0'],
  chart: {
    type: 'bar'
  },
  title: {
    text: null
  },
  xAxis: {
    categories: ['メンション', '画像', 'リンク', 'ハッシュタグ', '位置情報']
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