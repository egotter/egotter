function draw_word_cloud(selector, words, width, height) {
  var max_size = d3.max(words, function (n) {
    return n.size
  });
  var size_scale = d3.scale.linear().domain([0, max_size]).range([10, 80]);
  var fill = d3.scale.category20();

  var layout = d3.layout.cloud()
      .size([width, height])
      .words(words.map(function (d) {
        return {text: d.text, size: size_scale(d.size), group: d.group};
      }))
      .padding(5)
      .rotate(function () {
        return 0;
      })
      .font("Impact")
      .fontSize(function (d) {
        return d.size;
      })
      .on("end", draw);

  layout.start();

  function draw(words) {
    d3.select(selector).append("svg")
        .attr("width", layout.size()[0])
        .attr("height", layout.size()[1])
        .append("g")
        .attr("transform", "translate(" + layout.size()[0] / 2 + "," + layout.size()[1] / 2 + ")")
        .selectAll("text")
        .data(words)
        .enter().append("text")
        .style("font-size", function (d) {
          return d.size + "px";
        })
        .style("font-family", "Impact")
        .style("fill", function (d, i) {
          return fill(d.group - 1);
        })
        .attr("text-anchor", "middle")
        .attr("transform", function (d) {
          return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
        })
        .text(function (d) {
          return d.text;
        });
  }
}