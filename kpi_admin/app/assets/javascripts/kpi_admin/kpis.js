window.kpis = {};

window.kpis.dateTimeLabelFormats = {
  millisecond: '%H:%M:%S.%L',
  second: '%H:%M:%S',
  minute: '%H:%M',
  hour: '%H:%M',
  day: '%m/%d',
  week: '%m/%d',
  month: '%b \'%y',
  year: '%Y'
};

window.kpis.config = {
  credits: {
    enabled: false
  },
  chart: {
    type: 'line'
  },
  title: {
    text: 'title'
  },
  xAxis: {
    type: 'datetime',
    dateTimeLabelFormats: window.kpis.dateTimeLabelFormats
  },
  yAxis: {
    title: null
  },
  tooltip: {
    valueSuffix: ''
  },
  series: null
};

window.kpis.config_stacked = {
  credits: {
    enabled: false
  },
  chart: {
    type: 'area'
  },
  title: {
    text: 'title'
  },
  xAxis: {
    type: 'datetime',
    dateTimeLabelFormats: window.kpis.dateTimeLabelFormats
  },
  yAxis: {
    title: null
  },
  tooltip: {
    valueSuffix: ''
  },
  plotOptions: {
    area: {
      stacking: 'normal'
    }
  },
  series: null
};
