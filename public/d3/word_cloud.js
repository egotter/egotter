function draw_word_cloud(selector, nodes, width, height) {
  var color = ['rgba(181, 137, 0, 1.0)', 'rgba(220, 50, 47, 1.0)', 'rgba(108, 113, 196, 1.0)'];

  var max_size  = d3.max(nodes, function(n){ return n.size} );
  var sizeScale = d3.scale.linear().domain([0, max_size]).range([15, 30]);

  var words = nodes.map(function(n) {
    return {
      name: n.text,
      text: n.text,
      size: sizeScale(n.size),
      group: n.group
    }
  });

  d3.layout.cloud().size([width, height])
      .words(words)
      .padding(5)
      .rotate(function() { return 0 })
      .font('Impact')
      .fontSize(function(d) { return d.size })
      .on("end", function(nodes) {
        d3.select(selector).append("svg")
            .attr("width", width)
            .attr("height", height)
            .append("g")
            .attr("transform", "translate(" + width / 2 + ", " + height / 2 + ")")
            .selectAll("text")
            .data(nodes)
            .enter().append("text")
            .style("font-size", function(d) { return d.size + "px" })
            .attr("text-anchor", "middle")
            .style("font-family", "Impact")
            .style("fill", function(d, i) { return color[d.group] })
            .attr("transform", function(d) {
              return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")"
            })
            .text(function(d) { return d.name });
      })
      .start();
}