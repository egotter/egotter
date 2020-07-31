class FriendNetwork {
  constructor(selector, data, nodes) {
    Highcharts.chart(selector, {
      title: {
        text: null
      },
      chart: {
        type: 'networkgraph'
      },
      plotOptions: {
        networkgraph: {
          keys: ['from', 'to'],
          layoutAlgorithm: {
            enableSimulation: true,
            repulsiveForce: function () {
              return 15;
            }
          }
        }
      },
      series: [{
        dataLabels: {
          enabled: true,
          linkFormat: ''
        },
        data: data,
        nodes: nodes
      }],
      credits: false
    });
  }
}

window.FriendNetwork = FriendNetwork;
