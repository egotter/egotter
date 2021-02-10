class UsageStat {
  constructor(i18n) {
    this.i18n = i18n;
  }

  drawColumnChart(renderTo, data, drilldown) {
    var series = {name: null, colorByPoint: true, data: data};
    this._drawColumnChart(renderTo, [series], {series: drilldown});
  }

  drawColorlessColumnChart(renderTo, data) {
    var series = {name: null, colorByPoint: false, data: data};
    this._drawColumnChart(renderTo, [series], {});
  }

  drawStockLineChart(renderTo, data) {
    var series = {name: null, data: data};
    this._drawStockLineChart(renderTo, [series]);
  }

  drawTweetsBarChart(renderTo, breakdown) {
    var categories = [
      this.i18n['mention'],
      this.i18n['media'],
      this.i18n['link'],
      this.i18n['hashtag'],
      this.i18n['location']
    ];

    var series = [{
      name: this.i18n['no'],
      data: [
        100.0 - breakdown.mentions * 100,
        100.0 - breakdown.media * 100,
        100.0 - breakdown.urls * 100,
        100.0 - breakdown.hashtags * 100,
        100.0 - breakdown.location * 100
      ]
    }, {
      name: this.i18n['yes'],
      data: [
        breakdown.mentions * 100,
        breakdown.media * 100,
        breakdown.urls * 100,
        breakdown.hashtags * 100,
        breakdown.location * 100
      ]
    }];

    this._drawBarChart(renderTo, categories, series);
  }

  drawFriendsBarChart(renderTo, friends) {
    var categories = [
      this.i18n['friends'],
      this.i18n['followers']
    ];

    var series = [{
      name: this.i18n['no'],
      data: [
        100.0 - 100.0 * friends.follow_back_rate,
        100.0 - 100.0 * friends.followed_back_rate
      ]
    }, {
      name: this.i18n['yes'],
      data: [
        100.0 * friends.follow_back_rate,
        100.0 * friends.followed_back_rate
      ]
    }];

    this._drawBarChart(renderTo, categories, series);
  }

  _drawColumnChart(renderTo, series, drilldown) {
    var chartConfig = {
      colors: ['rgba(181, 137, 0, 1.0)', 'rgba(203, 75, 22, 1.0)', 'rgba(220, 50, 47, 1.0)', 'rgba(211, 54, 130, 1.0)', 'rgba(108, 113, 196, 1.0)', 'rgba(38, 139, 210, 1.0)', 'rgba(42, 161, 152, 1.0)', 'rgba(133, 153, 0, 1.0)'],
      chart: {
        renderTo: renderTo,
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

      series: series,
      drilldown: drilldown,
      credits: false
    };

    Highcharts.chart(chartConfig);
  }

  _drawStockLineChart(renderTo, series) {
    Highcharts.setOptions({
      time: {
        timezone: moment.tz.guess()
      }
    });

    var chartConfig = {
      chart: {
        renderTo: renderTo,
        type: 'line',
        marginTop: 0,
        marginRight: 0,
        spacingTop: 0,
        spacingBottom: 0,
        spacingLeft: 0
      },
      title: {
        text: null,
      },
      subtitle: {
        text: null,
      },
      series: series,
      rangeSelector: {enabled: false},
      scrollbar: {enabled: false},
      navigator: {enabled: false},
      exporting: {enabled: false},
      credits: {enabled: false}
    };

    Highcharts.stockChart(chartConfig);
  }

  _drawBarChart(renderTo, categories, series) {
    var chartConfig = {
      colors: ['rgba(181, 137, 0, 0.4)', 'rgba(42, 161, 152, 1.0'],
      chart: {
        renderTo: renderTo,
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
        categories: categories
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
      series: series,
      credits: false
    };

    Highcharts.chart(chartConfig);
  }
}

window.UsageStat = UsageStat;
